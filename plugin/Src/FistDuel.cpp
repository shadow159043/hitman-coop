#include "HitmanCoop.h"
#include "CoopText.h"
#include "GamePause.h"

#include <Windows.h>
#include <Glacier/ZHitman5.h>
#include <algorithm>
#include <array>
#include <cmath>
#include <string>

// Head-to-head competitive QTE. Each client times its own keypress from its
// local displayed prompt; the host compares bounded reaction times and
// broadcasts ONE winner per round. Packet arrival order never awards points.
// All HP changes are on the victim's OWN 47, never a remote actor or the
// stand-in NPC. No native NPC knock-out or death state is ever invoked.
bool HitmanCoop::CanStartDuel() const {
    if (!m_Session || !m_Session->Synced() || !m_World.IsInScene() ||
        m_LevelState != static_cast<int>(ZLevelManager::EGameState::EGS_Playing))
        return false;
    coop::Transform a;
    coop::Vec3 b;
    return m_World.GetLocalAvatar(a) && m_World.GetPartnerPosition(b) &&
        coop::Distance(a.pos, b) <= coop::duel::kChallengeRange;
}

void HitmanCoop::ApplyDuelPunch() {
    if (!m_Session || !m_Session->Synced() || !m_World.IsInScene() ||
        m_LevelState != static_cast<int>(ZLevelManager::EGameState::EGS_Playing))
        return;
    auto p = SDK()->GetLocalPlayer();
    if (!p || !p.m_pInterfaceRef || !p.m_pInterfaceRef->m_pHealth ||
        p.m_pInterfaceRef->m_bIsInvincible) return;
    auto* hp = p.m_pInterfaceRef->m_pHealth;
    const float current = hp->m_fHitPoints.Get();
    const float maxHp = hp->m_fMaxHitPoints.Get();
    const float after = coop::duel_motion::HealthAfterPunch(current, maxHp);
    if (after < current)
        hp->m_fHitPoints = after;
}

void HitmanCoop::ApplyDuelRound(int round, int winner, double now) {
    if (round < 0 || round >= coop::duel::kRounds || winner < 0 || winner > 2 ||
        !m_Session || !m_Session->Synced() || m_Duel.outcomes[round] != 0 ||
        round != m_Duel.nextJudgement)
        return;
    // outcomes: 3 denotes a scored draw, 1/2 denote host/client victory.
    m_Duel.outcomes[round] = winner == 0 ? 3 : winner;
    ++m_Duel.nextJudgement;
    const bool host = m_Session->Status().role == coop::SessionRole::Host;
    const bool localWon = winner != 0 && (host ? winner == 1 : winner == 2);
    const bool localLost = winner != 0 && !localWon;
    if (localWon) {
        ++m_Duel.rhythm.score;
        m_Duel.lastRemoteRecoilAt = now;
    } else if (localLost) {
        ++m_Duel.remoteScore; // Initialized to zero on accepted fight.
        m_Duel.lastRemoteHitAt = now;
        ApplyDuelPunch();
    }
    m_Duel.lastExchangeAt = now;
    m_Duel.lastExchange = localWon ? 1 : localLost ? -1 : 0;
}

void HitmanCoop::BeginDuelResult(uint32_t hostScore, uint32_t clientScore, double now) {
    const int w = coop::duel::Winner(static_cast<int>(hostScore), static_cast<int>(clientScore));
    if (w < 0) return;
    const bool host = m_Session && m_Session->Status().role == coop::SessionRole::Host;
    m_Duel.phase = DuelState::Phase::Result;
    m_Duel.resultAt = now;
    m_Duel.verdict = w == 0 ? 0 : ((w == 1) == host ? 1 : -1);
    m_Duel.remoteScore = host ? static_cast<int>(clientScore) : static_cast<int>(hostScore);
    m_LastDuelAt = now;
    if (m_Duel.verdict < 0)
        m_DuelDownUntil = now + 3.0;
    const std::string peer = m_FrameStatus.peerName.empty() ? "your partner" : m_FrameStatus.peerName;
    m_World.NotifyAs(m_Duel.verdict < 0 ? SdkWorld::ToastKind::Warning : SdkWorld::ToastKind::Partner,
        m_Duel.verdict > 0 ? "Fistfight won! You knocked down " + peer + "." :
        m_Duel.verdict < 0 ? "Fistfight lost. " + peer + " knocked you down for 3 seconds." :
        "Fistfight draw! Both fighters landed the same number of punches.");
    AppendLog("duel: punches landed=" + std::to_string(m_Duel.rhythm.score) +
        " opponent=" + std::to_string(m_Duel.remoteScore) +
        " verdict=" + std::to_string(m_Duel.verdict));
}

bool HitmanCoop::OnDuelEvent(const std::string& name, const std::string& data, double now) {
    if (name.rfind("Coop_Duel", 0) != 0) return false;
    if (!m_Session || !m_Session->Synced()) return true;
    uint32_t id=0, x=0, y=0;
    const bool host = m_Session->Status().role == coop::SessionRole::Host;
    using Phase = DuelState::Phase;
    const auto active = m_Duel.phase;

    if (name == "Coop_DuelChallenge") {
        if (!coop::duel::Number(data, id) || !id) return true;
        if ((active != Phase::Idle && active != Phase::Result) ||
            now-m_LastDuelAt < 8.0 || !CanStartDuel()) {
            m_Session->SendMissionEvent("Coop_DuelDecline", std::to_string(id));
            return true;
        }
        m_Duel = {};
        m_Duel.phase = Phase::ReceivedChallenge;
        m_Duel.id = id;
        m_Duel.created = now;
        m_World.NotifyAs(SdkWorld::ToastKind::Partner,
            m_FrameStatus.peerName + " challenged you to a fistfight! Open CO-OP > Play to accept.");
        return true;
    }
    if (name == "Coop_DuelDecline") {
        if (coop::duel::Number(data, id) && id == m_Duel.id && active == Phase::SentChallenge) {
            m_Duel = {}; m_LastDuelAt = now;
            m_World.Notify("Your fistfight challenge was declined or your partner was too far away.");
        }
        return true;
    }
    if (name == "Coop_DuelAccept") {
        if (coop::duel::Number(data, id) && id == m_Duel.id &&
            active == Phase::SentChallenge && CanStartDuel()) {
            const uint32_t seed = static_cast<uint32_t>(now*100000.0) ^ (m_Duel.id*0x9E3779B9u);
            m_Duel.seed = seed;
            m_Duel.start = now + coop::duel::kLeadSeconds;
            m_Duel.phase = Phase::Countdown;
            m_Duel.rhythm = {};
            m_Duel.remoteScore = 0;
            m_Session->SendMissionEvent("Coop_DuelStart",
                std::to_string(m_Duel.id) + ":" + std::to_string(seed));
            m_World.Notify("Fistfight accepted! Close the CO-OP menu and get ready.");
        }
        return true;
    }
    if (name == "Coop_DuelStart") {
        if (coop::duel::Pair(data, id, x, 0xFFFFFFFFu) &&
            id == m_Duel.id && active == Phase::WaitingStart) {
            m_Duel.seed = x;
            const double lag = std::clamp(m_FrameStatus.stats.rttMs/2000.0, 0.0, .25);
            m_Duel.start = now + coop::duel::kLeadSeconds - lag;
            m_Duel.phase = Phase::Countdown;
            m_Duel.rhythm = {};
            m_Duel.remoteScore = 0;
            m_World.Notify("Fistfight starting! Close CO-OP. Be the FIRST to hit each matching letter.");
        }
        return true;
    }
    if (name == "Coop_DuelPress") {
        // Only clients report reaction times; host observes its own local time.
        // Reject scores, malformed times, duplicates, and any round too far away
        // from the current timer (an untrusted client cannot send 12 at once).
        if (host && coop::duel::Triple(data, id, x, y,
                coop::duel::kRounds - 1, coop::duel::kRoundMs - 1) &&
            id == m_Duel.id && (active == Phase::Fighting || active == Phase::WaitingResult) &&
            m_Duel.peerMs[x] == -1 && m_Duel.outcomes[x] == 0 &&
            std::abs(coop::duel::Round(now,m_Duel.start) - static_cast<int>(x)) <= 2) {
            m_Duel.peerMs[x] = static_cast<int>(y);
        }
        return true;
    }
    if (name == "Coop_DuelRound") {
        // Host authoritative: each result contains ONE winner (host/client/tie).
        // Reliable ordered delivery guarantees each round is applied once.
        if (!host && coop::duel::Triple(data, id, x, y, coop::duel::kRounds-1, 2) &&
            id == m_Duel.id && (active == Phase::Fighting || active == Phase::WaitingResult) &&
            static_cast<int>(x) == m_Duel.nextJudgement)
            ApplyDuelRound(static_cast<int>(x), static_cast<int>(y), now);
        return true;
    }
    if (name == "Coop_DuelResult") {
        if (!host && coop::duel::Triple(data, id, x, y, coop::duel::kRounds, coop::duel::kRounds) &&
            id == m_Duel.id && (active == Phase::Fighting || active == Phase::WaitingResult) &&
            m_Duel.nextJudgement == coop::duel::kRounds &&
            x == static_cast<uint32_t>(m_Duel.remoteScore) &&
            y == static_cast<uint32_t>(m_Duel.rhythm.score))
            BeginDuelResult(x,y,now);
        return true;
    }
    return true;
}

void HitmanCoop::UpdateDuel(double now) {
    using Phase = DuelState::Phase;
    // Lock ordinary gameplay interactions during the letter QTE so pressing
    // F/E/Q/R does not accidentally pick up items, attack NPCs or run away.
    // Key scanning uses GetAsyncKeyState independently; session loss always
    // releases the lock, and the CO-OP menu can still be opened.
    m_DuelInputBlocked = m_Session && m_Session->Synced() &&
        (m_DuelDownUntil > now || m_Duel.phase == Phase::Fighting ||
         m_Duel.phase == Phase::WaitingResult);
    const bool fighting = m_Duel.phase == Phase::Fighting ||
                          m_Duel.phase == Phase::WaitingResult;
    const bool opponentDown = m_Duel.phase == Phase::Result && m_Duel.verdict > 0;
    m_World.SetDuelMotion(m_DuelAnimationsSetting ?
        coop::duel_motion::Sample(now, m_Duel.lastRemoteHitAt,
            m_Duel.lastRemoteRecoilAt, m_Duel.resultAt, opponentDown, fighting)
        : coop::duel_motion::Cue {});

    if (!m_Session || !m_Session->Synced() || !m_World.IsInScene()) {
        if (m_Duel.phase != Phase::Idle) m_Duel = {};
        m_DuelDownUntil = -100.0;
        m_DuelInputBlocked = false;
        m_World.SetDuelMotion({});
        return;
    }
    if (m_Duel.phase == Phase::Idle) return;
    if (m_Duel.phase == Phase::Result) {
        if (now - m_Duel.resultAt > 6.0) m_Duel = {};
        return;
    }
    if ((m_Duel.phase == Phase::SentChallenge || m_Duel.phase == Phase::ReceivedChallenge ||
         m_Duel.phase == Phase::WaitingStart) && now-m_Duel.created > 20.0) {
        m_World.Notify("Fistfight invitation timed out.");
        m_Duel = {};
        m_LastDuelAt = now;
        return;
    }
    if (m_Duel.phase == Phase::Countdown && now >= m_Duel.start) {
        m_Duel.phase = Phase::Fighting;
        std::fill(std::begin(m_Duel.keysHeld),std::end(m_Duel.keysHeld),false);
    }
    if (m_Duel.phase == Phase::Fighting) {
        const std::array<int,4> keys { 'E','F','Q','R' };
        const bool allowed = KeyAllowed() && m_WindowActive;
        const int round = coop::duel::Round(now, m_Duel.start);
        for (int i=0;i<4;++i) {
            const bool down = allowed && (GetAsyncKeyState(keys[i]) & 0x8000)!=0;
            if (down && !m_Duel.keysHeld[i] && round >= 0 &&
                round < coop::duel::kRounds && m_Duel.localMs[round] < 0 &&
                i == coop::duel::Prompt(m_Duel.seed,round)) {
                const double elapsed = (now-m_Duel.start-
                    round*coop::duel::kSecondsPerRound)*1000.0;
                const int ms = std::clamp(static_cast<int>(elapsed),0,coop::duel::kRoundMs-1);
                m_Duel.localMs[round] = ms;
                if (m_Session->Status().role == coop::SessionRole::Client) {
                    m_Session->SendMissionEvent("Coop_DuelPress",
                        std::to_string(m_Duel.id)+":"+std::to_string(round)+":"+std::to_string(ms));
                }
            }
            m_Duel.keysHeld[i] = down;
        }
        if (round >= coop::duel::kRounds) {
            m_Duel.phase = Phase::WaitingResult;
            m_Duel.created = now;
        }
    }
    if ((m_Duel.phase == Phase::Fighting || m_Duel.phase == Phase::WaitingResult) &&
        m_Session->Status().role == coop::SessionRole::Host) {
        // Equal reaction times are a tie (35ms tolerance). A single hit is
        // confirmed only after the other side had a chance to react / deliver.
        while (m_Duel.nextJudgement < coop::duel::kRounds) {
            const int round = m_Duel.nextJudgement;
            const bool both = m_Duel.localMs[round] >= 0 && m_Duel.peerMs[round] >= 0;
            const double sendGrace = .55 + std::clamp(m_FrameStatus.stats.rttMs / 1000., 0., .4);
            const bool expired = now >= m_Duel.start +
                (round + 1)*coop::duel::kSecondsPerRound + sendGrace;
            if (!both && !expired) break;
            const int winner = coop::duel::Judge(m_Duel.localMs[round],m_Duel.peerMs[round]);
            if (winner < 0) break; // Do not accept bogus reaction time.
            m_Session->SendMissionEvent("Coop_DuelRound",
                std::to_string(m_Duel.id)+":"+std::to_string(round)+":"+std::to_string(winner));
            ApplyDuelRound(round,winner,now);
        }
        if (m_Duel.nextJudgement == coop::duel::kRounds) {
            // Already 12 round results have been queued in reliable order.
            const uint32_t hs = static_cast<uint32_t>(m_Duel.rhythm.score);
            const uint32_t cs = static_cast<uint32_t>(m_Duel.remoteScore);
            m_Session->SendMissionEvent("Coop_DuelResult",
                std::to_string(m_Duel.id)+":"+std::to_string(hs)+":"+std::to_string(cs));
            BeginDuelResult(hs,cs,now);
        }
    }
    if (m_Duel.phase == Phase::WaitingResult && now-m_Duel.created > 8.0) {
        m_World.Notify("Fistfight results timed out; neither player is knocked down.");
        m_Duel = {};
        m_LastDuelAt = now;
    }
}
