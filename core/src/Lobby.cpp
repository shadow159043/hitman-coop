#include "coop/Lobby.h"

#include <cctype>
#include <string_view>

namespace coop {

const char* LobbyPhaseName(LobbyPhase p) {
    switch (p) {
    case LobbyPhase::Voting: return "VOTING";
    case LobbyPhase::Ready: return "READY UP";
    case LobbyPhase::Request: return "CHECKING BOTH PLAYERS";
    case LobbyPhase::Loading: return "WAITING FOR BOTH MISSIONS";
    case LobbyPhase::Playing: return "IN MISSION";
    case LobbyPhase::Failed: return "LAUNCH STOPPED";
    }
    return "UNKNOWN";
}

static bool SceneWireValid(const SceneDesc& scene) {
    if (scene.scene.size() > 250 || scene.codename.size() > 80 ||
        scene.bricks.size() > 8)
        return false;
    size_t total = scene.scene.size() + scene.codename.size() + 16;
    for (const auto& brick : scene.bricks) {
        if (brick.empty() || brick.size() > 240) return false;
        total += brick.size() + 2;
    }
    return total <= 420;
}

bool LobbyRoom::ValidScene(const SceneDesc& scene) {
    if (!SceneWireValid(scene) || scene.Empty() || scene.Location().empty() ||
        scene.MissionBricks().empty())
        return false;
    // Loaded game scene metadata only; don't accept fabricated file or web URLs.
    auto suffix = [](const std::string& path, std::string_view end) {
        if (path.size() < end.size()) return false;
        auto at = path.size() - end.size();
        for (size_t i = 0; i < end.size(); ++i)
            if (std::tolower(static_cast<unsigned char>(path[at + i])) != end[i])
                return false;
        return true;
    };
    return scene.scene.starts_with("assembly:/") && suffix(scene.scene, ".entity");
}

static void WriteScene(ByteWriter& out, const SceneDesc& scene) {
    MsgSceneInfo msg;
    msg.scene = scene;
    msg.Write(out);
}
static bool ReadScene(ByteReader& in, SceneDesc& scene) {
    MsgSceneInfo msg;
    if (!msg.Read(in) || msg.epoch != 0) return false;
    scene = std::move(msg.scene);
    return LobbyRoom::ValidScene(scene);
}

void LobbySnapshot::Write(ByteWriter& out) const {
    out.U32(revision);
    out.U8(static_cast<uint8_t>(phase));
    out.U8(count);
    for (size_t i = 0; i < count && i < kLobbyOptions; ++i) {
        out.U8(options[i].observed);
        WriteScene(out, options[i].scene);
    }
    out.U8(votes[0]); out.U8(votes[1]); out.U8(selected);
    out.Bool(ready[0]); out.Bool(ready[1]);
    out.Bool(loaded[0]); out.Bool(loaded[1]);
    out.Bool(accepted);
    out.U64(launchId);
    out.Str(error);
}
bool LobbySnapshot::Read(ByteReader& in) {
    uint8_t raw = 0;
    if (!in.U32(revision) || !in.U8(raw) || raw > static_cast<uint8_t>(LobbyPhase::Failed) ||
        !in.U8(count) || count > kLobbyOptions) return false;
    phase = static_cast<LobbyPhase>(raw);
    for (size_t i = 0; i < count; ++i) {
        if (!in.U8(options[i].observed) || options[i].observed == 0 ||
            options[i].observed > 3 || !ReadScene(in, options[i].scene)) return false;
        for (size_t j = 0; j < i; ++j)
            if (options[j].scene.SameAs(options[i].scene)) return false;
    }
    if (!in.U8(votes[0]) || !in.U8(votes[1]) || !in.U8(selected) ||
        !in.Bool(ready[0]) || !in.Bool(ready[1]) ||
        !in.Bool(loaded[0]) || !in.Bool(loaded[1]) ||
        !in.Bool(accepted) || !in.U64(launchId) || !in.Str(error, 150))
        return false;
    for (auto vote : votes)
        if (vote != kLobbyNoChoice && vote >= count) return false;
    if (selected != kLobbyNoChoice && selected >= count) return false;
    if (phase != LobbyPhase::Voting && phase != LobbyPhase::Failed && selected == kLobbyNoChoice)
        return false;
    if ((phase == LobbyPhase::Request || phase == LobbyPhase::Loading || phase == LobbyPhase::Playing) &&
        launchId == 0) return false;
    return true;
}
void MsgLobbyInput::Write(ByteWriter& out) const {
    out.U8(static_cast<uint8_t>(kind));
    out.U32(serial);
    out.U8(choice);
    out.Bool(ready);
    out.U64(launchId);
    if (kind == LobbyInputKind::Observed)
        WriteScene(out, scene);
}
bool MsgLobbyInput::Read(ByteReader& in) {
    uint8_t raw = 0;
    if (!in.U8(raw) || raw < static_cast<uint8_t>(LobbyInputKind::Observed) ||
        raw > static_cast<uint8_t>(LobbyInputKind::BackToVoting) ||
        !in.U32(serial) || serial == 0 || !in.U8(choice) ||
        !in.Bool(ready) || !in.U64(launchId)) return false;
    kind = static_cast<LobbyInputKind>(raw);
    return kind != LobbyInputKind::Observed || ReadScene(in, scene);
}

void LobbyRoom::Changed() {
    if (++m_State.revision == 0) ++m_State.revision;
}
void LobbyRoom::Clear(bool keepChoices) {
    const auto last = m_State;
    m_State = {};
    m_State.revision = last.revision;
    if (keepChoices) {
        m_State.options = last.options;
        m_State.count = last.count;
    }
    m_Deadline = 0.0;
    Changed();
}
bool LobbyRoom::Observe(unsigned player, const SceneDesc& scene) {
    if (player > 1 || m_State.phase != LobbyPhase::Voting || !ValidScene(scene))
        return false;
    for (size_t i = 0; i < m_State.count; ++i) {
        if (m_State.options[i].scene.SameAs(scene)) {
            auto& flags = m_State.options[i].observed;
            if (flags & (1u << player)) return false;
            flags |= static_cast<uint8_t>(1u << player);
            m_State.votes = { kLobbyNoChoice, kLobbyNoChoice };
            Changed();
            return true;
        }
    }
    if (m_State.count >= kLobbyOptions) return false;
    m_State.options[m_State.count++] = { scene, static_cast<uint8_t>(1u << player) };
    m_State.votes = { kLobbyNoChoice, kLobbyNoChoice };
    Changed();
    return true;
}
bool LobbyRoom::Vote(unsigned player, uint8_t choice) {
    if (player > 1 || m_State.phase != LobbyPhase::Voting || choice >= m_State.count ||
        !m_State.CanSelect(choice) || m_State.votes[player] == choice) return false;
    m_State.votes[player] = choice;
    // Host-authoritative automatic winner when both agents vote alike.
    // The host chooses explicitly only when the vote is split 1-1.
    if (m_State.votes[0] != kLobbyNoChoice &&
        m_State.votes[0] == m_State.votes[1] && m_State.CanSelect(choice)) {
        m_State.selected = choice;
        m_State.phase = LobbyPhase::Ready;
        m_State.ready = { false, false };
        m_State.loaded = { false, false };
    }
    Changed();
    return true;
}
bool LobbyRoom::LockWinner(uint8_t choice) {
    if (m_State.phase != LobbyPhase::Voting ||
        m_State.votes[0] == kLobbyNoChoice || m_State.votes[1] == kLobbyNoChoice ||
        (choice != m_State.votes[0] && choice != m_State.votes[1]) ||
        (m_State.votes[0] == m_State.votes[1] && choice != m_State.votes[0]) ||
        !m_State.CanSelect(choice)) return false;
    m_State.selected = choice;
    m_State.ready = { false, false };
    m_State.loaded = { false, false };
    m_State.phase = LobbyPhase::Ready;
    Changed();
    return true;
}
bool LobbyRoom::SetReady(unsigned player, bool ready, bool compatible) {
    if (player > 1 || m_State.phase != LobbyPhase::Ready || !compatible ||
        !m_State.CanSelect(m_State.selected) || m_State.ready[player] == ready) return false;
    m_State.ready[player] = ready;
    Changed();
    return true;
}
bool LobbyRoom::CanLaunch(bool compatible) const {
    return compatible && m_State.phase == LobbyPhase::Ready &&
        m_State.CanSelect(m_State.selected) && m_State.ready[0] && m_State.ready[1];
}
bool LobbyRoom::RequestLaunch(uint64_t id, double now, bool compatible) {
    if (!CanLaunch(compatible) || id == 0 || id <= m_State.launchId)
        return false;
    m_State.launchId = id;
    m_State.phase = LobbyPhase::Request;
    m_State.accepted = false;
    m_State.loaded = { false, false };
    m_State.error.clear();
    m_Deadline = now + 120.0;
    Changed();
    return true;
}
bool LobbyRoom::AcceptLaunch(uint64_t id) {
    if (m_State.phase != LobbyPhase::Request || id != m_State.launchId) return false;
    m_State.accepted = true;
    m_State.phase = LobbyPhase::Loading;
    Changed();
    return true;
}
bool LobbyRoom::SceneLoaded(unsigned player, const SceneDesc& scene) {
    if (player > 1 || m_State.phase != LobbyPhase::Loading || m_State.loaded[player] ||
        !m_State.SelectedScene() || !m_State.SelectedScene()->SameAs(scene)) return false;
    m_State.loaded[player] = true;
    Changed();
    return true;
}
bool LobbyRoom::BeginGameplay(bool synchronized) {
    if (m_State.phase != LobbyPhase::Loading || !synchronized ||
        !m_State.loaded[0] || !m_State.loaded[1]) return false;
    m_State.phase = LobbyPhase::Playing;
    m_Deadline = 0.0;
    Changed();
    return true;
}
bool LobbyRoom::Timeout(double now) {
    if (m_Deadline <= 0.0 || now < m_Deadline || !HoldGameplay())
        return false;
    return Abort("Mission launch timed out. Choose Return to voting and try again.");
}
bool LobbyRoom::Abort(const std::string& reason) {
    if (m_State.phase == LobbyPhase::Failed || m_State.phase == LobbyPhase::Voting)
        return false;
    m_State.phase = LobbyPhase::Failed;
    m_State.ready = { false, false };
    m_State.error = reason.substr(0, 150);
    m_Deadline = 0.0;
    Changed();
    return true;
}
bool LobbyRoom::ReturnToVoting() {
    if (m_State.phase == LobbyPhase::Voting) return false;
    m_State.phase = LobbyPhase::Voting;
    m_State.selected = kLobbyNoChoice;
    m_State.votes = { kLobbyNoChoice, kLobbyNoChoice };
    m_State.ready = { false, false };
    m_State.loaded = { false, false };
    m_State.accepted = false;
    m_State.error.clear();
    m_Deadline = 0.0;
    Changed();
    return true;
}
bool LobbyRoom::ApplySnapshot(const LobbySnapshot& host) {
    if (host.revision <= m_State.revision)
        return false;
    m_State = host;
    m_Deadline = 0.0; // guest does not decide deadlines
    return true;
}

} // namespace coop
