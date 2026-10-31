#pragma once

#include "coop/Socket.h"
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <Windows.h>
#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_set>
#include <string>

// Experimental opt-in transport on HITMAN's OWN Steam App 1659040.
// Uses the existing SteamNetworking006 packet API, never SteamAPI_Init or AppID 480.
// Legacy API is deprecated: future builds should migrate to SteamNetworkingSockets.
class SteamP2PSocket final : public coop::IDatagramSocket {
public:
    static std::unique_ptr<SteamP2PSocket> Open(uint64_t p_HostPeer, std::string& p_Error);
    ~SteamP2PSocket() override;
    SteamP2PSocket(const SteamP2PSocket&) = delete;
    SteamP2PSocket& operator=(const SteamP2PSocket&) = delete;

    bool SendTo(const coop::Endpoint& p_To, const uint8_t* p_Data, size_t p_Size) override;
    int RecvFrom(coop::Endpoint& p_From, uint8_t* p_Buffer, size_t p_Capacity) override;

    static bool ParseAddress(const std::string& p_Text, uint64_t& p_SteamId);
private:
    SteamP2PSocket();

    class SessionCallback {
    public:
        explicit SessionCallback(SteamP2PSocket& p_Owner) : m_Owner(p_Owner) {}
        virtual void Run(void* p_Data);
        virtual void Run(void* p_Data, bool, uint64_t) { Run(p_Data); }
        virtual int GetCallbackSizeBytes() { return sizeof(uint64_t); }
        uint8_t m_Flags = 0;
        int m_CallbackId = 0;
    private:
        SteamP2PSocket& m_Owner;
    };

    using SendFn = bool (__cdecl*)(void*, uint64_t, const void*, uint32_t, int, int);
    using AvailableFn = bool (__cdecl*)(void*, uint32_t*, int);
    using ReadFn = bool (__cdecl*)(void*, void*, uint32_t, uint32_t*, uint64_t*, int);
    using AcceptFn = bool (__cdecl*)(void*, uint64_t);
    using CloseChannelFn = bool (__cdecl*)(void*, uint64_t, int);
    using UnregisterFn = void (__cdecl*)(void*);

    void OnSessionRequest(uint64_t p_Peer);
    HMODULE m_Module = nullptr;
    void* m_Networking = nullptr;
    SendFn m_Send = nullptr;
    AvailableFn m_Available = nullptr;
    ReadFn m_Read = nullptr;
    AcceptFn m_Accept = nullptr;
    CloseChannelFn m_CloseChannel = nullptr;
    UnregisterFn m_Unregister = nullptr;
    SessionCallback m_Callback;
    bool m_Registered = false;
    std::atomic<uint64_t> m_AllowedPeer {0}; // client: explicit invite target
    bool m_IsHost = false;
    std::mutex m_PeersMutex;
    std::unordered_set<uint64_t> m_AllowedHostPeers; // bounded to 4; core room handshake rejects strangers
    // Distinct channel from HITMAN's game-owned network traffic.
    static constexpr int kChannel = 127;
};
