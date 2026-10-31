#include "SteamInvite.h"
#include <algorithm>
#include <cstring>

namespace {
constexpr uint32_t kHitmanSteamAppId = 1659040;
constexpr int kRichPresenceJoinCallback = 337;
constexpr char kInvitePrefix[] = "arturcoop1|";
constexpr size_t kMaxInviteLength = 255;

bool ValidAddress(const std::string& p_Value) {
    if (p_Value.empty() || p_Value.size() > 120) return false;
    return std::all_of(p_Value.begin(), p_Value.end(), [](unsigned char c) {
        return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') ||
            (c >= 'a' && c <= 'z') || c == '.' || c == ':' || c == '-';
    });
}
bool ValidRoom(const std::string& p_Value) {
    if (p_Value.size() < 4 || p_Value.size() > 16) return false;
    return std::all_of(p_Value.begin(), p_Value.end(), [](unsigned char c) {
        return (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-';
    });
}
}

SteamInvite::SteamInvite() : m_Callback(*this) {}
SteamInvite::~SteamInvite() {
    // Never unload the game-owned steam_api64.dll.
    if (m_Registered && m_Unregister && GetModuleHandleW(L"steam_api64.dll") == m_Module)
        m_Unregister(&m_Callback);
}

std::string SteamInvite::Encode(const std::string& p_Address, const std::string& p_Room) {
    if (!ValidAddress(p_Address) || !ValidRoom(p_Room)) return {};
    const std::string s_Result = std::string(kInvitePrefix) + p_Address + "|" + p_Room;
    return s_Result.size() <= kMaxInviteLength ? s_Result : std::string {};
}

std::optional<SteamInvite::Join> SteamInvite::Decode(const std::string& p_Value) {
    if (p_Value.size() > kMaxInviteLength || p_Value.rfind(kInvitePrefix, 0) != 0)
        return std::nullopt;
    const size_t s_Divider = p_Value.find('|', sizeof(kInvitePrefix) - 1);
    if (s_Divider == std::string::npos || p_Value.find('|', s_Divider + 1) != std::string::npos)
        return std::nullopt;
    Join s_Join {
        p_Value.substr(sizeof(kInvitePrefix) - 1, s_Divider - (sizeof(kInvitePrefix) - 1)),
        p_Value.substr(s_Divider + 1)
    };
    if (!ValidAddress(s_Join.address) || !ValidRoom(s_Join.room))
        return std::nullopt;
    return s_Join;
}

uint64_t SteamInvite::LocalSteamId() const {
    if (!m_Ready || !m_Module) return 0;
    const auto s_GetUser = reinterpret_cast<void*(__cdecl*)()>(GetProcAddress(m_Module, "SteamAPI_SteamUser_v023"));
    const auto s_GetId = reinterpret_cast<uint64_t(__cdecl*)(void*)>(GetProcAddress(m_Module, "SteamAPI_ISteamUser_GetSteamID"));
    if (!s_GetUser || !s_GetId) return 0;
    void* s_User = s_GetUser();
    return s_User ? s_GetId(s_User) : 0;
}

std::string SteamInvite::Status() const {
    std::lock_guard s_Lock(m_Mutex);
    return m_Status;
}

void SteamInvite::Probe() {
    if (m_Ready) return;
    // The game owns SteamAPI_Init and SteamAPI_Shutdown. This module only attaches to
    // an already initialized Steam context with the correct legitimate HITMAN App ID.
    const HMODULE s_Module = GetModuleHandleW(L"steam_api64.dll");
    if (!s_Module) return;
    const auto s_Sym = [&](const char* p_Name) {
        return GetProcAddress(s_Module, p_Name);
    };
    const auto s_GetUser = reinterpret_cast<GetUserFn>(s_Sym("SteamAPI_GetHSteamUser"));
    const auto s_GetFriends = reinterpret_cast<GetFriendsFn>(s_Sym("SteamAPI_SteamFriends_v018"));
    const auto s_GetUtils = reinterpret_cast<GetUtilsFn>(s_Sym("SteamAPI_SteamUtils_v011"));
    const auto s_AppId = reinterpret_cast<AppIdFn>(s_Sym("SteamAPI_ISteamUtils_GetAppID"));
    const auto s_Overlay = reinterpret_cast<OverlayEnabledFn>(s_Sym("SteamAPI_ISteamUtils_IsOverlayEnabled"));
    const auto s_Invite = reinterpret_cast<InviteDialogFn>(
        s_Sym("SteamAPI_ISteamFriends_ActivateGameOverlayInviteDialogConnectString"));
    const auto s_Register = reinterpret_cast<RegisterFn>(s_Sym("SteamAPI_RegisterCallback"));
    const auto s_Unregister = reinterpret_cast<UnregisterFn>(s_Sym("SteamAPI_UnregisterCallback"));
    const auto s_RunCallbacks = reinterpret_cast<RunCallbacksFn>(s_Sym("SteamAPI_RunCallbacks"));
    if (!s_GetUser || !s_GetFriends || !s_GetUtils || !s_AppId || !s_Overlay ||
        !s_Invite || !s_Register || !s_Unregister || !s_RunCallbacks) {
        std::lock_guard s_Lock(m_Mutex);
        m_Status = "Steam API lacks the required friends/overlay exports";
        return;
    }
    if (!s_GetUser()) return;
    void* s_Utils = s_GetUtils();
    void* s_Friends = s_GetFriends();
    if (!s_Utils || !s_Friends) return;
    if (s_AppId(s_Utils) != kHitmanSteamAppId) {
        std::lock_guard s_Lock(m_Mutex);
        m_Status = "Steam App ID is not HITMAN 3 (1659040): integration disabled";
        return;
    }
    if (!s_Overlay(s_Utils)) {
        std::lock_guard s_Lock(m_Mutex);
        m_Status = "Enable Steam overlay in Steam/HITMAN settings";
        return;
    }
    m_Module = s_Module;
    m_Utils = s_Utils;
    m_Friends = s_Friends;
    m_InviteDialog = s_Invite;
    m_Unregister = s_Unregister;
    m_RunCallbacks = s_RunCallbacks;
    if (!m_Registered) {
        s_Register(&m_Callback, kRichPresenceJoinCallback);
        m_Registered = true;
    }
    {
        std::lock_guard s_Lock(m_Mutex);
        m_Status = "Steam friends invite available (existing IP/Tailscale route)";
    }
    m_Ready = true;
}

void SteamInvite::Tick() {
    if (!m_CommandLineChecked) {
        m_CommandLineChecked = true;
        // Steam can launch a non-running HITMAN with the invite connect string.
        // Only parse our own strict prefix. Never modify the executable's App ID.
        const std::string s_CommandLine = GetCommandLineA();
        const size_t s_Start = s_CommandLine.find(kInvitePrefix);
        if (s_Start != std::string::npos) {
            const size_t s_End = s_CommandLine.find_first_of(" \t\r\n\"'", s_Start);
            const std::string s_Token = s_CommandLine.substr(s_Start, s_End - s_Start);
            if (auto s_Join = Decode(s_Token)) {
                std::lock_guard s_Lock(m_Mutex);
                m_Pending = std::move(s_Join);
            }
        }
    }
    if (!m_Ready) {
        if (++m_Frames % 120 == 0)
            Probe();
        return;
    }
    if (m_RunCallbacks)
        m_RunCallbacks(); // Steam documents multi-thread dispatch as supported.
}

bool SteamInvite::OpenInviteDialog(const std::string& p_Address, const std::string& p_Room,
                                   std::string& p_Error) {
    if (!m_Ready || !m_Friends || !m_InviteDialog) {
        p_Error = Status();
        return false;
    }
    const std::string s_Invite = Encode(p_Address, p_Room);
    if (s_Invite.empty()) {
        p_Error = "Missing/invalid host address or room code";
        return false;
    }
    // Password intentionally NEVER sent via Steam Rich Presence.
    m_InviteDialog(m_Friends, s_Invite.c_str());
    return true;
}

void SteamInvite::Received(const char* p_Raw, size_t p_Length) {
    if (!p_Raw) return;
    const size_t s_Len = strnlen_s(p_Raw, p_Length);
    const auto s_Join = Decode(std::string(p_Raw, s_Len));
    if (s_Join) {
        std::lock_guard s_Lock(m_Mutex);
        m_Pending = s_Join;
    }
}

void SteamInvite::Callback::Run(void* p_Data) {
    if (!p_Data) return;
    // GameRichPresenceJoinRequested_t: uint64 SteamID followed by a 256-byte string.
    m_Owner.Received(static_cast<const char*>(p_Data) + sizeof(uint64_t), 256);
}

std::optional<SteamInvite::Join> SteamInvite::TakeJoin() {
    std::lock_guard s_Lock(m_Mutex);
    auto s_Join = std::move(m_Pending);
    m_Pending.reset();
    return s_Join;
}
