#pragma once

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <set>
#include <string>
#include <vector>

#include "Protocol.h"

namespace coop {

// Two-player host-authoritative lobby. Mission IDs are hashes of *observed game
// scene descriptors*, never invented scene names. This is a conservative catalog:
// a player advertises a mission only after HITMAN has actually loaded it.
// It does NOT prove DLC ownership, nor does it navigate the game menus.
enum class LobbyPhase : uint8_t { Voting, Ready, AwaitAck, Loading, Synced, Failed };

struct LobbyOption {
    std::string key;
    std::string label;
    bool peerObserved = false;
};

struct LobbySnapshot {
    uint32_t revision = 0;
    uint32_t launchId = 0;
    LobbyPhase phase = LobbyPhase::Voting;
    std::vector<LobbyOption> options;
    std::string hostVote;
    std::string peerVote;
    std::string selected;
    bool hostReady = false, peerReady = false;
    bool hostLoaded = false, peerLoaded = false;
    bool peerAck = false;
    std::string error;
};

class LobbyModel {
public:
    static std::string MissionKey(const SceneDesc& scene) {
        if (scene.Empty() || scene.Location().empty() || scene.codename.empty())
            return {};
        const auto bricks = scene.MissionBricks();
        if (bricks.empty()) return {};
        // Stable FNV-1a 64-bit. The normalized, sorted mission bricks include
        // difficulty-specific entries and exclude machine-dependent bricks.
        uint64_t hash = 14695981039346656037ull;
        const auto feed = [&](const std::string& value) {
            for (unsigned char b : value) {
                hash ^= b;
                hash *= 1099511628211ull;
            }
            hash ^= 0xff;
            hash *= 1099511628211ull;
        };
        feed(scene.Location());
        feed(scene.codename);
        for (const auto& brick : bricks) feed(brick);
        char key[17];
        std::snprintf(key, sizeof(key), "%016llx", static_cast<unsigned long long>(hash));
        return key;
    }

    static bool ValidKey(const std::string& key) {
        return key.size() == 16 && std::all_of(key.begin(), key.end(), [](char c) {
            return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f');
        });
    }

    const LobbySnapshot& State() const { return m_State; }

    bool Observe(const SceneDesc& scene) {
        std::string key = MissionKey(scene);
        if (!ValidKey(key) || m_State.phase != LobbyPhase::Voting && m_State.phase != LobbyPhase::Ready)
            return false;
        for (const auto& option : m_State.options)
            if (option.key == key) return false;
        if (m_State.options.size() >= 8) return false;
        const std::string label = LocationDisplayName(scene.Location()) + " / " + scene.codename;
        if (label.size() > 100) return false;
        m_State.options.push_back({ key, label, false });
        ChangeSelection();
        return true;
    }

    bool PeerObserved(const std::string& key) {
        auto* option = Find(key);
        if (!option || option->peerObserved) return false;
        option->peerObserved = true;
        ChangeSelection();
        return true;
    }

    // Every mutation is performed by the host (client requests are validated
    // against this model). A vote isn't accepted for an unconfirmed mission.
    bool Vote(bool peer, const std::string& key) {
        const auto* option = Find(key);
        if (!option || !option->peerObserved || Locked()) return false;
        std::string& vote = peer ? m_State.peerVote : m_State.hostVote;
        if (vote == key) return false; // duplicate / replay
        vote = key;
        ChangeSelection();
        if (!m_State.hostVote.empty() && m_State.hostVote == m_State.peerVote) {
            m_State.selected = key;
            m_State.phase = LobbyPhase::Ready;
            ++m_State.revision;
        }
        return true;
    }

    bool ResolveTie(const std::string& key) {
        if (Locked() || m_State.hostVote.empty() || m_State.peerVote.empty() ||
            m_State.hostVote == m_State.peerVote ||
            (key != m_State.hostVote && key != m_State.peerVote))
            return false;
        const auto* option = Find(key);
        if (!option || !option->peerObserved) return false;
        m_State.selected = key;
        m_State.phase = LobbyPhase::Ready;
        m_State.hostReady = m_State.peerReady = false;
        ++m_State.revision;
        return true;
    }

    bool Ready(bool peer, bool ready) {
        if (m_State.phase != LobbyPhase::Ready || m_State.selected.empty()) return false;
        bool& field = peer ? m_State.peerReady : m_State.hostReady;
        if (field == ready) return false;
        field = ready;
        ++m_State.revision;
        return true;
    }

    bool Begin(double now, bool versionsMatch) {
        if (!versionsMatch || m_State.phase != LobbyPhase::Ready ||
            m_State.selected.empty() || !m_State.hostReady || !m_State.peerReady)
            return false;
        if (++m_NextLaunchId == 0) ++m_NextLaunchId;
        m_State.launchId = m_NextLaunchId;
        m_State.phase = LobbyPhase::AwaitAck;
        m_State.peerAck = m_State.hostLoaded = m_State.peerLoaded = false;
        m_State.error.clear();
        m_Deadline = now + 20.0;
        ++m_State.revision;
        return true;
    }

    bool Ack(uint32_t launchId, double now) {
        if (m_State.phase != LobbyPhase::AwaitAck || !launchId || launchId != m_State.launchId)
            return false;
        m_State.peerAck = true;
        m_State.phase = LobbyPhase::Loading;
        m_Deadline = now + 180.0;
        ++m_State.revision;
        return true;
    }

    bool Loaded(bool peer, uint32_t launchId, const SceneDesc& scene) {
        if (m_State.phase != LobbyPhase::Loading || !launchId || launchId != m_State.launchId ||
            MissionKey(scene) != m_State.selected)
            return false;
        bool& flag = peer ? m_State.peerLoaded : m_State.hostLoaded;
        if (flag) return false;
        flag = true;
        if (m_State.hostLoaded && m_State.peerLoaded) m_State.phase = LobbyPhase::Synced;
        ++m_State.revision;
        return true;
    }

    bool Timeout(double now) {
        if ((m_State.phase != LobbyPhase::AwaitAck && m_State.phase != LobbyPhase::Loading) ||
            now < m_Deadline)
            return false;
        Fail("The other player did not finish preparing/loading. Retry from the lobby.");
        return true;
    }

    void Fail(const std::string& reason) {
        m_State.phase = LobbyPhase::Failed;
        m_State.error = reason.substr(0, 160);
        m_State.hostReady = m_State.peerReady = false;
        ++m_State.revision;
    }

    void Reset(bool disconnect = false) {
        if (disconnect)
            for (auto& option : m_State.options) option.peerObserved = false;
        m_State.hostVote.clear();
        m_State.peerVote.clear();
        m_State.selected.clear();
        m_State.hostReady = m_State.peerReady = false;
        m_State.hostLoaded = m_State.peerLoaded = false;
        m_State.peerAck = false;
        m_State.phase = LobbyPhase::Voting;
        m_State.launchId = 0;
        m_State.error.clear();
        ++m_State.revision;
    }

    // A client only mirrors validated snapshots received from its host. In
    // particular, a peer packet can NEVER call the host-only helpers above.
    bool ApplyHostState(const LobbySnapshot& state) {
        if (state.options.size() > 8 || state.revision < m_State.revision) return false;
        for (const auto& option : state.options)
            if (!ValidKey(option.key) || option.label.size() > 100) return false;
        if (state.selected.size() && !ValidKey(state.selected)) return false;
        m_State = state;
        return true;
    }

private:
    LobbyOption* Find(const std::string& key) {
        for (auto& option : m_State.options)
            if (option.key == key) return &option;
        return nullptr;
    }
    const LobbyOption* Find(const std::string& key) const {
        for (const auto& option : m_State.options)
            if (option.key == key) return &option;
        return nullptr;
    }
    bool Locked() const {
        return m_State.phase == LobbyPhase::AwaitAck || m_State.phase == LobbyPhase::Loading ||
            m_State.phase == LobbyPhase::Synced || m_State.phase == LobbyPhase::Failed;
    }
    void ChangeSelection() {
        m_State.selected.clear();
        m_State.hostReady = m_State.peerReady = false;
        m_State.phase = LobbyPhase::Voting;
        ++m_State.revision;
    }

    LobbySnapshot m_State;
    uint32_t m_NextLaunchId = 0;
    double m_Deadline = 0;
};

} // namespace coop
