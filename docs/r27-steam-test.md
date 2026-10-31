# Artur Edition R2.7 Steam Friend Invites and P2P TEST

**Experimental, not two-PC verified.** Game build HITMAN 3.290.1.0, Steam App ID 1659040, ZHMModSDK 4.2.0, co-op 0.12.6 (protocol 16). Both players must install this same version. Original HITMAN Co-op by Jordan Rodrigues (GPL-3.0-or-later).

## Findings on the actual installed Steam copy

- `Retail/steam_api64.dll` is present and exports Friends_v018, Utils_v011, SteamNetworking_v006, SteamNetworkingSockets_SteamAPI_v013, ISteamMatchmaking_v009 and Steam overlay invite functions.
- We used the game's **legitimate** Steam App ID **1659040** and its already initialized Steamworks process. No `SteamAPI_Init`, `SteamAPI_Shutdown`, App ID rewriting, `steam_appid.txt` spoofing, and **no Spacewar 480**.
- Valve's SteamNetworking006 packet API is **deprecated**. Modern SteamNetworkingSockets is preferable for a production implementation, but needs a separately tested network adapter. This build isolates the legacy API to an optional transport and retains normal UDP and private co-op relay.
- No live HITMAN Steam session was running for two-PC validation during development. The presence of exports **does not guarantee** that Steam relaying is enabled for this app/account or that an invitation can be received by another account.

## New opt-in Steam workflow

1. Launch **both copies of HITMAN through Steam**. Verify Steam overlay is enabled. Co-op menu should show **v0.12.6** on both PCs. Complete a mission load on the host.
2. HOST a room and choose a room code (password optional). Under **Leave session**, look for **Steam friends invite (experimental)**. Click **Invite Steam friend...** and select your friend in the real Steam overlay.
3. When an invited friend **already has HITMAN running**, Steam sends the `GameRichPresenceJoinRequested_t` callback. The mod parses its strictly limited `arturcoop1|steam:<steamID64>|ROOM` connect string and pre-fills Join fields. The friend should verify the details, supply the password separately if one is set, and click JOIN.
4. When the invited friend's HITMAN is **not running**, Steam may launch it with the connect string. The mod checks command-line arguments for its own strict prefix, then pre-fills Join after startup. This path has not been live-verified.
5. The join connection attempts SteamNetworking006 P2P on isolated channel **127**. If the Steam connection fails, manually copy the host's **Tailscale IP**, local IP, or shared co-op relay code and rejoin. The host keeps UDP and configured private relay listening in parallel.
6. Steam invites never include the room password. The mod's **game-level room-password handshake is still not encrypted**, so do not use an account password.

## Safeguards

- Steam API is used **only if already initialized by HITMAN**, App ID returned by `ISteamUtils::GetAppID` equals **1659040**, required exports exist, and the Steam overlay is enabled for friend invitation.
- No hidden app entitlements or app identity bypass. The feature does not turn Epic or Game Pass installations into Steam builds.
- Steam P2P accepts a bounded number of candidates; the existing two-player handshake, room code, version and optional password remain authoritative. No extra gameplay protocol fields were added.
- An invite only pre-fills the Join panel. It never auto-connects or sends passwords over Steam.
- If the Steam API isn't ready, the feature reports unavailable; direct-IP/Tailscale/relay connections continue unchanged.
- The legacy Steam Networking API may be removed in future Steam updates. Use this only as an **experimental** test while evaluating a modern adapter.

## Tests completed

- Steam invite encode/decode and invalid input tests: passed.
- Steam route selection in `MultiSocket`, strict `steam:<SteamID64>` parsing and fail-closed behavior without initialized Steam: passed.
- Windows C++/ZHMModSDK plugin build and existing multiplayer core tests: passed (86 tests).
- Installer package verifies embedded DLL and source files; does **not** install into HITMAN.
- **Not yet tested:** genuine Steam overlay invitations, two accounts behind different NATs, Steam relay availability, callback delivery when HITMAN was launched from an invitation, long-running sessions, disconnect/reconnect.

## Prioritized next live test

1. Try Steam invite and join while both users are already in-game. Record status and whether the friend's address field starts with `steam:`.
2. If the Steam P2P path connects, check ping and movement for 5 minutes, then change mission and reconnect.
3. If Steam P2P fails, try the same room via Tailscale to verify no multiplayer regressions. Capture private logs of any failures.
4. If Steam Overlay is missing or the Steam identity check fails, verify both clients are launching their legitimately owned Steam copies and overlay is allowed in Steam settings.
5. Retain older R2.6 test and latest regular R2.3 release as rollback.
