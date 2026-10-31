# HITMAN Co-op by Artur — R2.8 Steam P2P diagnostics test

**Experimental follow-up to R2.7**. The user verified the native Steam friend invitation worked and automatically imported the host's room code, but connecting the two game sessions failed. That evidence supports the Steam invite path only; it does not show successful Steam P2P packet delivery.

## R2.8 changes
- **Steam-specific timeout:** The R2.7 client had the same 10-second timeout as direct UDP. Valve notes the legacy Steam P2P API can take up to about 20 seconds before reporting a connection failure. R2.8 allows **35 seconds** for a Steam-addressed peer. IP/Tailscale/relay retains the existing 10-second default. A new core regression test verifies both behaviors.
- **Failure callback:** Registers `P2PSessionConnectFail_t` (callback 1203) alongside the already-used `P2PSessionRequest_t` (1202) to identify Steam's documented failure errors:
  - 1: other player not running the same app
  - 2: local account lacks rights to the app
  - 3: destination is not logged into Steam
  - 4: P2P timeout / session not accepted or NAT/network failure
- **Non-sensitive instrumentation:** Tracks Steam P2P packet sends, send failures, received packets, session requests and successful acceptances. Includes diagnostic information in the game's Play tab and in a timeout message.
- **Local log file** written on each PC to `%LOCALAPPDATA%\HitmanCoop\SteamP2P.log`. Contains timestamps and event labels/counters, not Steam IDs, passwords, room codes, IPs or packet bodies.
- **Fallback:** If the Steam network cannot connect, the user can retry with the existing Tailscale/IP or configured Co-op relay. Existing working Steam invite and room-code import is unchanged. No change to original HITMAN Steam identity, no Spacewar App ID 480.

## How to test on two Steam accounts
1. Both users install **R2.8 (v0.12.7)** with HITMAN 3.290.1.x and ZHMModSDK 4.2.0. Start the legitimate Steam HITMAN copy and ensure Steam is online and overlay enabled.
2. The host presses HOST, then **Invite Steam friend...**. Friend accepts; verify `steam:` followed by SteamID64 is shown as the address and correct room code is filled. Password, if any, is manually entered as before.
3. Click JOIN and allow up to **35 seconds**. Watch status under Leave session; expect `sent > 0`, and, after success, `received > 0`. Host should show `requests > 0` and `accepted > 0`.
4. If it times out, inspect both computers' `%LOCALAPPDATA%\HitmanCoop\SteamP2P.log` (Windows Run dialog accepts that path). Logs are designed not to include private joining credentials but should still be shared only with someone trusted.
5. Compare diagnostics:
   - Client `sent=0` or `send_failed>0`: Steam send call did not queue packets; inspect Steam App initialization and account rights.
   - Host `requests=0`: peer request never reached Steam API callbacks, or the callback handler was not delivered. Confirm host was running before friend joined.
   - Host `requests>0` but `accepted=0`: acceptance path failed; inspect logs.
   - Host `accepted>0` but `received=0`: P2P transport did not deliver game packets; examine failure error code.
   - Client `received>0` but still rejected: mod handshake, game/mod version, room code, or password might differ.
6. Retry joining the **same hosted room via Tailscale IP**. If that works, the bug is specific to Steam P2P instead of multiplayer gameplay.

## Verification and limitations
- R2.8 uses the same network protocol **16** as R2.7 but both users should install the exact same mod version **0.12.7** to avoid mismatched behavior.
- All core automated tests and Steam probe tests must pass before publishing R2.8. Offline tests cannot establish that Valve's relaying service permits P2P for HITMAN on either account.
- Legacy `ISteamNetworking` is deprecated. Once logs identify the blocker, a modern Steam Networking Sockets adapter may be preferable, but changing networking APIs without evidence would obscure the root cause.
- No game files are modified by compiling or packaging this release. R2.7 is retained for rollback, and R2.3 remains the latest normal release.
- Room password handshake is **not encrypted** in the mod; do not reuse sensitive account passwords.

Original HITMAN Co-op by Jordan Rodrigues, GPL-3.0-or-later. Experimental Artur compatibility edition; not affiliated with IO Interactive.
