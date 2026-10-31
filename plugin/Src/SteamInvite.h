#pragma once
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <Windows.h>
#include <atomic>
#include <cstdint>
#include <mutex>
#include <optional>
#include <string>

// Uses HITMAN's ALREADY INITIALIZED Steamworks client. Never calls SteamAPI_Init,
// substitutes another App ID, changes ownership, or patches Steam/Steamworks.
class SteamInvite {
public:
    struct Join {
        std::string address;
        std::string room;
    };

    SteamInvite();
    ~SteamInvite();
    SteamInvite(const SteamInvite&) = delete;
    SteamInvite& operator=(const SteamInvite&) = delete;

    // Called from the mod's engine update thread; the game's existing Steam callbacks
    // may also run this callback in a different thread.
    void Tick();
    bool Available() const { return m_Ready.load(); }
    uint64_t LocalSteamId() const;
    std::string Status() const;
    bool OpenInviteDialog(const std::string& p_Address, const std::string& p_Room, std::string& p_Error);
    std::optional<Join> TakeJoin();

    // Pure codec intentionally excludes passwords, tokens, and Steam account data.
    static std::string Encode(const std::string& p_Address, const std::string& p_Room);
    static std::optional<Join> Decode(const std::string& p_Value);

private:
    // This is the documented CCallbackBase binary interface, not a replacement for
    // Steam's game-owned SDK or DLL. Callback 337 = GameRichPresenceJoinRequested_t.
    class Callback {
    public:
        explicit Callback(SteamInvite& p_Owner) : m_Owner(p_Owner) {}
        virtual void Run(void* p_Data);
        virtual void Run(void* p_Data, bool, uint64_t) { Run(p_Data); }
        virtual int GetCallbackSizeBytes() { return 264; }
        uint8_t m_Flags = 0;
        int m_CallbackId = 0;
    private:
        SteamInvite& m_Owner;
    };

    using GetUserFn = int32_t (__cdecl*)();
    using GetFriendsFn = void* (__cdecl*)();
    using GetUtilsFn = void* (__cdecl*)();
    using AppIdFn = uint32_t (__cdecl*)(void*);
    using OverlayEnabledFn = bool (__cdecl*)(void*);
    using InviteDialogFn = void (__cdecl*)(void*, const char*);
    using RegisterFn = void (__cdecl*)(void*, int);
    using UnregisterFn = void (__cdecl*)(void*);
    using RunCallbacksFn = void (__cdecl*)();

    void Probe();
    void Received(const char* p_Raw, size_t p_Length);
    HMODULE m_Module = nullptr;
    void* m_Friends = nullptr;
    void* m_Utils = nullptr;
    InviteDialogFn m_InviteDialog = nullptr;
    UnregisterFn m_Unregister = nullptr;
    RunCallbacksFn m_RunCallbacks = nullptr;
    Callback m_Callback;
    bool m_Registered = false;
    std::atomic<bool> m_Ready{false};
    mutable std::mutex m_Mutex;
    std::optional<Join> m_Pending;
    std::string m_Status = "Waiting for HITMAN Steamworks";
    int m_Frames = 0;
    bool m_CommandLineChecked = false;
};
