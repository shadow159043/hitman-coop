#include "HitmanCoop.h"
#include "CoopText.h"
#include "GamePause.h"

#include <Windows.h>
#include <algorithm>
#include <array>
#include <string>

// The face-to-face duel is a deterministic co-op QTE, not an unsafe attempt to
// activate 47's unknown NPC takedown engine. The winner briefly downs the
// loser's controls without HP loss, death or mission-score consequences.
bool HitmanCoop::CanStartDuel() const {
    if (!m_Session || !m_Session->Synced() || !m_World.IsInScene() ||
        m_LevelState != static_cast<int>(ZLevelManager::EGameState::EGS_Playing))
        return false;
    coop::Transform a;
    coop::Vec3 b;
    return m_World.GetLocalAvatar(a) && m_World.GetPartnerPosition(b) &&
        coop::Distance(a.pos, b) <= coop::duel::kChallengeRange;
}

void HitmanCoop::BeginDuelResult(uint32_t p_HostScore, uint32_t p_ClientScore, double p_Now) {
    const int w = coop::duel::Winner(static_cast<int>(p_HostScore), static_cast<int>(p_ClientScore));
    if (w < 0) return;
    const bool host = m_Session && m_Session->Status().role == coop::SessionRole::Host;
    m_Duel.phase = DuelState::Phase::Result;
    m_Duel.resultAt = p_Now;
    m_Duel.verdict = w == 0 ? 0 : ((w == 1) == host ? 1 : -1);
    m_Duel.remoteScore = host ? static_cast<int>(p_ClientScore) : static_cast<int>(p_HostScore);
    m_LastDuelAt = p_Now;
    if (m_Duel.verdict < 0)
        m_DuelDownUntil = p_Now + 3.0; // Non-lethal knockdown/stun; never mutate player HP.
    const std::string peer = m_FrameStatus.peerName.empty() ? "your partner" : m_FrameStatus.peerName;
    m_World.NotifyAs(m_Duel.verdict < 0 ? SdkWorld::ToastKind::Warning : SdkWorld::ToastKind::Partner,
        m_Duel.verdict > 0 ? "Fistfight won! You knocked down " + peer + "." :
        m_Duel.verdict < 0 ? "Fistfight lost. " + peer + " knocked you down for 3 seconds." :
        "Fistfight draw! Both players landed the same number of QTEs.");
    AppendLog("duel: result local=" + std::to_string(m_Duel.rhythm.score) +
        " other=" + std::to_string(m_Duel.remoteScore) +
        " verdict=" + std::to_string(m_Duel.verdict));
}

bool HitmanCoop::OnDuelEvent(const std::string& p_Name, const std::string& p_Data, double p_Now) {
    if (p_Name.rfind("Coop_Duel", 0) != 0)
        return false;
    if (!m_Session || !m_Session->Synced()) return true;
    uint32_t id = 0, x = 0, y = 0;
    const auto host = m_Session->Status().role == coop::SessionRole::Host;
    const auto active = m_Duel.phase;

    if (p_Name == "Coop_DuelChallenge") {
        if (!coop::duel::Number(p_Data, id) || !id) return true;
        if ((active != DuelState::Phase::Idle && active != DuelState::Phase::Result) ||
            p_Now - m_LastDuelAt < 8.0 || !CanStartDuel()) {
            m_Session->SendMissionEvent("Coop_DuelDecline", std::to_string(id));
            return true;
        }
        m_Duel = {};
        m_Duel.phase = DuelState::Phase::ReceivedChallenge;
        m_Duel.id = id;
        m_Duel.created = p_Now;
        m_World.NotifyAs(SdkWorld::ToastKind::Partner,
            m_FrameStatus.peerName + " challenged you to a fistfight! Open CO-OP > Play to accept.");
        return true;
    }

    if (p_Name == "Coop_DuelDecline") {
        if (coop::duel::Number(p_Data, id) && id == m_Duel.id &&
            active == DuelState::Phase::SentChallenge) {
            m_Duel = {};
            m_LastDuelAt = p_Now;
            m_World.Notify("Your fistfight challenge was declined or the other player was too far away.");
        }
        return true;
    }
    if (p_Name == "Coop_DuelAccept") {
        if (coop::duel::Number(p_Data, id) && id == m_Duel.id &&
            active == DuelState::Phase::SentChallenge && CanStartDuel()) {
            const uint32_t seed = static_cast<uint32_t>(p_Now * 100000.0) ^ (m_Duel.id * 0x9E3779B9u);
            m_Duel.seed = seed;
            m_Duel.start = p_Now + coop::duel::kLeadSeconds;
            m_Duel.phase = DuelState::Phase::Countdown;
            m_Duel.rhythm = {};
            m_Session->SendMissionEvent("Coop_DuelStart",
                std::to_string(m_Duel.id) + ":" + std::to_string(seed));
            m_World.Notify("Fistfight accepted! Close the CO-OP menu and watch the arrows.");
        }
        return true;
    }
    if (p_Name == "Coop_DuelStart") {
        if (coop::duel::Pair(p_Data, id, x, 0xFFFFFFFFu) && id == m_Duel.id &&
            active == DuelState::Phase::WaitingStart) {
            m_Duel.seed = x;
            // Approximate the host's start time with RTT/2 compensation.
            const double lag = std::clamp(m_FrameStatus.stats.rttMs / 2000.0, 0.0, 0.25);
            m_Duel.start = p_Now + coop::duel::kLeadSeconds - lag;
            m_Duel.phase = DuelState::Phase::Countdown;
            m_Duel.rhythm = {};
            m_World.Notify("Fistfight starting! Close CO-OP and press the matching arrow once per prompt.");
        }
        return true;
    }
    if (p_Name == "Coop_DuelScore") {
        if (host && coop::duel::Pair(p_Data, id, x, coop::duel::kRounds) &&
            id == m_Duel.id && (active == DuelState::Phase::Fighting ||
            active == DuelState::Phase::WaitingResult)) {
            m_Duel.remoteScore = static_cast<int>(x);
        }
        return true;
    }
    if (p_Name == "Coop_DuelResult") {
        if (!host && coop::duel::Triple(p_Data, id, x, y, coop::duel::kRounds, coop::duel::kRounds) &&
            id == m_Duel.id && active == DuelState::Phase::WaitingResult &&
            y == static_cast<uint32_t>(m_Duel.rhythm.score)) {
            BeginDuelResult(x, y, p_Now);
        }
        return true;
    }
    return true;
}

void HitmanCoop::UpdateDuel(double p_Now) {
    using Phase = DuelState::Phase;
    m_DuelInputBlocked = m_DuelDownUntil > p_Now && m_Session && m_Session->Synced();
    if (!m_Session || !m_Session->Synced() || !m_World.IsInScene()) {
        if (m_Duel.phase != Phase::Idle) m_Duel = {};
        m_DuelDownUntil = -100.0;
        m_DuelInputBlocked = false;
        return;
    }
    if (m_Duel.phase == Phase::Idle) return;
    if (m_Duel.phase == Phase::Result) {
        if (p_Now - m_Duel.resultAt > 6.0) m_Duel = {};
        return;
    }
    if ((m_Duel.phase == Phase::SentChallenge || m_Duel.phase == Phase::ReceivedChallenge ||
         m_Duel.phase == Phase::WaitingStart) && p_Now - m_Duel.created > 20.0) {
        m_World.Notify("Fistfight invitation timed out.");
        m_Duel = {};
        m_LastDuelAt = p_Now;
        return;
    }
    if (m_Duel.phase == Phase::Countdown && p_Now >= m_Duel.start) {
        m_Duel.phase = Phase::Fighting;
        m_Duel.keysHeld[0] = m_Duel.keysHeld[1] = m_Duel.keysHeld[2] = m_Duel.keysHeld[3] = false;
    }
    if (m_Duel.phase == Phase::Fighting) {
        const std::array<int, 4> keys { VK_UP, VK_RIGHT, VK_DOWN, VK_LEFT };
        // GetAsyncKeyState is used by the existing mod hotkeys; never score when
        // the user is typing, in pause/UI, or another window is focused.
        const bool allowed = KeyAllowed() && m_WindowActive;
        for (int i = 0; i < 4; ++i) {
            const bool down = allowed && (GetAsyncKeyState(keys[i]) & 0x8000) != 0;
            if (down && !m_Duel.keysHeld[i])
                m_Duel.rhythm.Press(m_Duel.seed, i, p_Now, m_Duel.start);
            m_Duel.keysHeld[i] = down;
        }
        if (coop::duel::Round(p_Now, m_Duel.start) >= coop::duel::kRounds) {
            m_Duel.phase = Phase::WaitingResult;
            m_Duel.submitted = true;
            m_Duel.created = p_Now; // Result-response timeout anchor.
            if (m_Session->Status().role == coop::SessionRole::Client)
                m_Session->SendMissionEvent("Coop_DuelScore",
                    std::to_string(m_Duel.id) + ":" + std::to_string(m_Duel.rhythm.score));
        }
    }
    if (m_Duel.phase == Phase::WaitingResult) {
        const bool host = m_Session->Status().role == coop::SessionRole::Host;
        if (host && m_Duel.remoteScore >= 0) {
            const uint32_t hs = static_cast<uint32_t>(m_Duel.rhythm.score);
            const uint32_t cs = static_cast<uint32_t>(m_Duel.remoteScore);
            m_Session->SendMissionEvent("Coop_DuelResult",
                std::to_string(m_Duel.id) + ":" + std::to_string(hs) + ":" + std::to_string(cs));
            BeginDuelResult(hs, cs, p_Now);
        } else if (p_Now - m_Duel.created > 7.0) {
            m_World.Notify("Fistfight result timed out; nobody was knocked down.");
            m_Duel = {};
            m_LastDuelAt = p_Now;
        }
    }
}
