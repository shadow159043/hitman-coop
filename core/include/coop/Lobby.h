#pragma once

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <utility>

#include "coop/Protocol.h"

namespace coop {

// Experimental two-player lobby. Mission descriptions must come from real game
// scene loads, not guessed scene paths or a synthetic list of unowned contracts.
constexpr uint8_t kLobbyNoChoice = 255;
constexpr size_t kLobbyOptions = 2;

enum class LobbyPhase : uint8_t {
    Voting = 0, Ready, Request, Loading, Playing, Failed
};
const char* LobbyPhaseName(LobbyPhase phase);

// Each player may report a game scene they have actually loaded. This is a local
// observation, NOT an independently verified entitlement or account-license API.
struct LobbyOption {
    SceneDesc scene;
    uint8_t observed = 0; // bit 0 = host, bit 1 = guest
};

struct LobbySnapshot {
    uint32_t revision = 0;
    LobbyPhase phase = LobbyPhase::Voting;
    std::array<LobbyOption, kLobbyOptions> options {};
    uint8_t count = 0;
    std::array<uint8_t, 2> votes { kLobbyNoChoice, kLobbyNoChoice };
    uint8_t selected = kLobbyNoChoice;
    std::array<bool, 2> ready { false, false };
    std::array<bool, 2> loaded { false, false };
    bool accepted = false;
    uint64_t launchId = 0;
    std::string error;

    void Write(ByteWriter& out) const;
    bool Read(ByteReader& in);
    bool CanSelect(uint8_t option) const {
        return option < count && options[option].observed == 3;
    }
    const SceneDesc* SelectedScene() const {
        return selected < count ? &options[selected].scene : nullptr;
    }
};

// User-originated commands are sent reliably to the host. A client cannot send a
// host state, change phase, choose a tied winner, or invent a launch id.
enum class LobbyInputKind : uint8_t {
    Observed = 1, Vote, Ready, Ack, Loaded, Abort, BackToVoting
};

struct MsgLobbyInput {
    LobbyInputKind kind = LobbyInputKind::Vote;
    uint32_t serial = 0;
    uint8_t choice = kLobbyNoChoice;
    bool ready = false;
    uint64_t launchId = 0;
    SceneDesc scene; // only populated when kind == Observed
    void Write(ByteWriter& out) const;
    bool Read(ByteReader& in);
};

struct MsgLobbySnapshot {
    LobbySnapshot state;
    void Write(ByteWriter& out) const { state.Write(out); }
    bool Read(ByteReader& in) { return state.Read(in); }
};

// Only the host mutates LobbyRoom. The guest applies host snapshots and sends
// MsgLobbyInput; all actions are serialized on Session's game-thread tick.
class LobbyRoom {
public:
    const LobbySnapshot& State() const { return m_State; }
    void Clear(bool keepChoices = false);
    bool Observe(unsigned player, const SceneDesc& scene);
    bool Vote(unsigned player, uint8_t choice);
    bool LockWinner(uint8_t choice); // explicit host tie-break / confirmation
    bool SetReady(unsigned player, bool ready, bool compatible);
    bool RequestLaunch(uint64_t id, double now, bool compatible);
    bool AcceptLaunch(uint64_t id);
    bool SceneLoaded(unsigned player, const SceneDesc& scene);
    bool BeginGameplay(bool synchronized);
    bool Timeout(double now);
    bool Abort(const std::string& reason);
    bool ReturnToVoting();
    bool ApplySnapshot(const LobbySnapshot& host);
    bool CanLaunch(bool compatible) const;
    bool HoldGameplay() const {
        return m_State.phase == LobbyPhase::Request || m_State.phase == LobbyPhase::Loading;
    }
    static bool ValidScene(const SceneDesc& scene);

private:
    void Changed();
    LobbySnapshot m_State;
    double m_Deadline = 0.0;
};

} // namespace coop
