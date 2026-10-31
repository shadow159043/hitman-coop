#include "SteamP2P.h"
#include "coop/Protocol.h"
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <sstream>
#include <ctime>

namespace {
constexpr uint32_t kHitmanSteamAppId = 1659040;
constexpr int kP2PSessionRequestCallback = 1202;
constexpr int kP2PSessionConnectFailCallback = 1203;
// Avoid logging Steam account identifiers, room codes, passwords, network addresses or game packets.
void LogSteam(const std::string& p_Message) {
    static std::mutex s_LogMutex;
    std::lock_guard s_Lock(s_LogMutex);
    char s_LocalAppData[32767]{};
    const DWORD s_Len = GetEnvironmentVariableA("LOCALAPPDATA", s_LocalAppData, sizeof(s_LocalAppData));
    if (s_Len == 0 || s_Len >= sizeof(s_LocalAppData)) return;
    const std::string s_Dir = std::string(s_LocalAppData) + "\\HitmanCoop";
    CreateDirectoryA(s_Dir.c_str(), nullptr);
    std::ofstream s_File(s_Dir + "\\SteamP2P.log", std::ios::app);
    if (!s_File) return;
    std::time_t s_Now = std::time(nullptr);
    s_File << static_cast<long long>(s_Now) << " " << p_Message << '\n';
}
}

SteamP2PSocket::SteamP2PSocket() : m_Callback(*this), m_FailureCallback(*this) {}

std::string SteamP2PSocket::SteamErrorDescription(uint8_t p_Error) {
    switch (p_Error) {
        case 1: return "Steam says the other player is not running the same game";
        case 2: return "Steam says this account has no rights to this game";
        case 3: return "Steam says the destination player is offline";
        case 4: return "Steam P2P timed out; check Steam overlay, NAT/firewall or host acceptance";
        default: return "Steam P2P reported error code " + std::to_string(p_Error);
    }
}

std::string SteamP2PSocket::Diagnostic() const {
    std::ostringstream s_Detail;
    s_Detail << "Steam " << (m_IsHost ? "host" : "client") << ": sent=" << m_SendCount.load()
        << ", send_failed=" << m_SendFailedCount.load()
        << ", received=" << m_ReceivedCount.load() << ", requests=" << m_Requests.load()
        << ", accepted=" << m_Accepted.load() << ".";
    if (const int s_Error = m_LastSteamError.load())
        s_Detail << " " << SteamErrorDescription(static_cast<uint8_t>(s_Error)) << ".";
    else if (!m_ReceivedCount.load())
        s_Detail << " No Steam gameplay packets arrived; inspect the host log.";
    return s_Detail.str();
}

bool SteamP2PSocket::ParseAddress(const std::string& p_Text, uint64_t& p_SteamId) {
    p_SteamId = 0;
    if (p_Text.rfind("steam:", 0) != 0 || p_Text.size() < 18 || p_Text.size() > 26)
        return false;
    const std::string s_IdText = p_Text.substr(6);
    if (!std::all_of(s_IdText.begin(), s_IdText.end(), [](unsigned char c) {return c >= '0' && c <= '9';}))
        return false;
    char* s_End = nullptr;
    const unsigned long long s_Id = std::strtoull(s_IdText.c_str(), &s_End, 10);
    if (!s_End || *s_End || s_Id == 0)
        return false;
    p_SteamId = static_cast<uint64_t>(s_Id);
    return true;
}

std::unique_ptr<SteamP2PSocket> SteamP2PSocket::Open(uint64_t p_HostPeer, std::string& p_Error) {
    const HMODULE s_Module = GetModuleHandleW(L"steam_api64.dll");
    if (!s_Module) {
        p_Error = "HITMAN's Steam API is not loaded";
        return nullptr;
    }
    const auto s_Sym = [&](const char* p_Name) { return GetProcAddress(s_Module, p_Name); };
    const auto s_GetUser = reinterpret_cast<int32_t(__cdecl*)()>(s_Sym("SteamAPI_GetHSteamUser"));
    const auto s_GetUtils = reinterpret_cast<void*(__cdecl*)()>(s_Sym("SteamAPI_SteamUtils_v011"));
    const auto s_GetAppId = reinterpret_cast<uint32_t(__cdecl*)(void*)>(s_Sym("SteamAPI_ISteamUtils_GetAppID"));
    const auto s_GetNetworking = reinterpret_cast<void*(__cdecl*)()>(s_Sym("SteamAPI_SteamNetworking_v006"));
    const auto s_Register = reinterpret_cast<void(__cdecl*)(void*, int)>(s_Sym("SteamAPI_RegisterCallback"));
    const auto s_Unregister = reinterpret_cast<UnregisterFn>(s_Sym("SteamAPI_UnregisterCallback"));
    auto s_Result = std::unique_ptr<SteamP2PSocket>(new SteamP2PSocket());
    s_Result->m_Send = reinterpret_cast<SendFn>(s_Sym("SteamAPI_ISteamNetworking_SendP2PPacket"));
    s_Result->m_Available = reinterpret_cast<AvailableFn>(s_Sym("SteamAPI_ISteamNetworking_IsP2PPacketAvailable"));
    s_Result->m_Read = reinterpret_cast<ReadFn>(s_Sym("SteamAPI_ISteamNetworking_ReadP2PPacket"));
    s_Result->m_Accept = reinterpret_cast<AcceptFn>(s_Sym("SteamAPI_ISteamNetworking_AcceptP2PSessionWithUser"));
    s_Result->m_CloseChannel = reinterpret_cast<CloseChannelFn>(s_Sym("SteamAPI_ISteamNetworking_CloseP2PChannelWithUser"));
    if (!s_GetUser || !s_GetUtils || !s_GetAppId || !s_GetNetworking || !s_Register ||
        !s_Unregister || !s_Result->m_Send || !s_Result->m_Available || !s_Result->m_Read ||
        !s_Result->m_Accept || !s_Result->m_CloseChannel) {
        p_Error = "SteamNetworking006 packet API unavailable";
        return nullptr;
    }
    void* s_Utils = s_GetUtils();
    if (!s_GetUser() || !s_Utils || s_GetAppId(s_Utils) != kHitmanSteamAppId) {
        p_Error = "Steam must be initialized under HITMAN App ID 1659040 (not Spacewar)";
        return nullptr;
    }
    s_Result->m_Networking = s_GetNetworking();
    if (!s_Result->m_Networking) {
        p_Error = "SteamNetworking006 interface not initialized";
        return nullptr;
    }
    s_Result->m_Module = s_Module;
    s_Result->m_Unregister = s_Unregister;
    s_Result->m_AllowedPeer = p_HostPeer;
    s_Result->m_IsHost = p_HostPeer == 0;
    s_Register(&s_Result->m_Callback, kP2PSessionRequestCallback);
    s_Register(&s_Result->m_FailureCallback, kP2PSessionConnectFailCallback);
    s_Result->m_Registered = true;
    LogSteam(p_HostPeer ? "client Steam P2P opened (App 1659040, channel 127)" :
        "host Steam P2P listening (App 1659040, channel 127)");
    return s_Result;
}

SteamP2PSocket::~SteamP2PSocket() {
    if (m_Registered && m_Unregister && GetModuleHandleW(L"steam_api64.dll") == m_Module) {
        m_Unregister(&m_Callback);
        m_Unregister(&m_FailureCallback);
    }
    LogSteam(Diagnostic());
    if (m_Networking && m_CloseChannel && GetModuleHandleW(L"steam_api64.dll") == m_Module) {
        const uint64_t s_Peer = m_AllowedPeer.load();
        if (s_Peer)
            m_CloseChannel(m_Networking, s_Peer, kChannel);
        std::lock_guard s_Lock(m_PeersMutex);
        for (uint64_t s_HostPeer : m_AllowedHostPeers)
            m_CloseChannel(m_Networking, s_HostPeer, kChannel);
    }
}

void SteamP2PSocket::OnSessionRequest(uint64_t p_Peer) {
    ++m_Requests;
    LogSteam(m_IsHost ? "host received Steam session request" : "client received Steam session request");
    if (!p_Peer || !m_Networking || !m_Accept)
        return;
    if (m_IsHost) {
        // Session itself enforces the two-player limit, protocol and optional password.
        // Do not permanently lock out a real invitee if an earlier peer was rejected.
        std::lock_guard s_Lock(m_PeersMutex);
        if (!m_AllowedHostPeers.contains(p_Peer) && m_AllowedHostPeers.size() >= 4)
            return;
        if (m_Accept(m_Networking, p_Peer)) {
            m_AllowedHostPeers.insert(p_Peer);
            ++m_Accepted;
            LogSteam("host accepted Steam P2P session request");
        } else {
            LogSteam("host Steam AcceptP2PSessionWithUser returned false");
        }
        return;
    }
    if (m_AllowedPeer.load() == p_Peer) {
        if (m_Accept(m_Networking, p_Peer)) {
            ++m_Accepted;
            LogSteam("client accepted expected Steam session request");
        } else LogSteam("client Steam AcceptP2PSessionWithUser returned false");
    } else LogSteam("client ignored unexpected Steam session request");
}

void SteamP2PSocket::OnSessionFailure(uint64_t p_Peer, uint8_t p_Error) {
    if (!p_Peer) return;
    // Client only accepts a failure about the intended host; host can receive failures
    // about one of its admitted candidate peers.
    if (!m_IsHost && p_Peer != m_AllowedPeer.load()) return;
    if (m_IsHost) {
        std::lock_guard s_Lock(m_PeersMutex);
        if (!m_AllowedHostPeers.contains(p_Peer)) return;
    }
    m_LastSteamError = p_Error;
    LogSteam(SteamErrorDescription(p_Error));
}

void SteamP2PSocket::FailureCallback::Run(void* p_Data) {
    if (!p_Data) return;
    const auto* s_Bytes = static_cast<const uint8_t*>(p_Data);
    uint64_t s_Peer = 0;
    std::memcpy(&s_Peer, s_Bytes, sizeof(s_Peer));
    m_Owner.OnSessionFailure(s_Peer, s_Bytes[sizeof(uint64_t)]);
}

void SteamP2PSocket::SessionCallback::Run(void* p_Data) {
    if (p_Data)
        m_Owner.OnSessionRequest(*static_cast<const uint64_t*>(p_Data));
}

bool SteamP2PSocket::SendTo(const coop::Endpoint& p_To, const uint8_t* p_Data, size_t p_Size) {
    if (!p_To.IsSteam() || !p_Data || p_Size == 0 || p_Size > coop::kMaxPacketSize ||
        !m_Networking || !m_Send)
        return false;
    if (m_IsHost) {
        std::lock_guard s_Lock(m_PeersMutex);
        if (!m_AllowedHostPeers.contains(p_To.steamPeer))
            return false;
    } else if (p_To.steamPeer != m_AllowedPeer.load()) {
        return false;
    }
    // Reliability is already implemented by the co-op Connection layer. This preserves
    // its sequencing, retransmission and congestion behavior without double-buffering.
    const bool s_Ok = m_Send(m_Networking, p_To.steamPeer, p_Data, static_cast<uint32_t>(p_Size), 0, kChannel);
    const uint32_t s_Number = ++m_SendCount;
    if (!s_Ok) {
        if (++m_SendFailedCount <= 3) LogSteam("Steam SendP2PPacket returned false");
    }
    else if (s_Number == 1 || s_Number == 30 || s_Number == 100)
        LogSteam("Steam SendP2PPacket queued outgoing handshake/gameplay datagram");
    return s_Ok;
}

int SteamP2PSocket::RecvFrom(coop::Endpoint& p_From, uint8_t* p_Buffer, size_t p_Capacity) {
    if (!m_Networking || !m_Available || !m_Read || !p_Buffer)
        return -1;
    uint32_t s_Size = 0;
    if (!m_Available(m_Networking, &s_Size, kChannel))
        return -1;
    // Never allow the peer to overrun the 1200 byte gameplay datagram buffer.
    if (s_Size == 0 || s_Size > coop::kMaxPacketSize || s_Size > p_Capacity)
        return -1;
    uint64_t s_Peer = 0;
    uint32_t s_Read = 0;
    if (!m_Read(m_Networking, p_Buffer, static_cast<uint32_t>(p_Capacity),
                &s_Read, &s_Peer, kChannel))
        return -1;
    if (!s_Peer || s_Read > coop::kMaxPacketSize)
        return -1;
    if (m_IsHost) {
        std::lock_guard s_Lock(m_PeersMutex);
        if (!m_AllowedHostPeers.contains(s_Peer))
            return -1;
    } else if (s_Peer != m_AllowedPeer.load()) {
        return -1;
    }
    p_From = coop::Endpoint::Steam(s_Peer);
    if (++m_ReceivedCount == 1) LogSteam("first incoming Steam P2P datagram received");
    return static_cast<int>(s_Read);
}
