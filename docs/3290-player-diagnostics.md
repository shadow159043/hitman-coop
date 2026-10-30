# HITMAN 3.290.1.0 player-visibility investigation

This is an isolated bug-fix fork of JordanRodrigues021/hitman-coop v0.12.1. It does not modify an installed game or the separate Assassin Rivals project.

## Source-level finding

Prior to this patch, `SdkWorld::BuildOverlay()` only marked a remote player as visible to the overlay when `HasPartner()` and `GetPartnerPosition()` succeeded. Both required a successfully spawned NPC stand-in. Thus failure to spawn an NPC also suppressed its name tag, compass and radar dot, even if network position packets had been received.

The patch uses the last received **fresh** player position (at most 2 seconds old) to render the overlay when the stand-in is unavailable. It clears the last position on session hide/disconnect. It also avoids mistaking a temporarily unavailable camera for a cutscene (which previously hid all overlay markers at maps far from world origin). It does **not** repair 3.290.1.0 NPC spawning, skeleton mapping, or private SDK hooks.

## Two-PC acceptance checklist (requires a user-run game test)

1. Preserve the installed Co-op game files and logs. Do not hot-replace a DLL in a running HITMAN process.
2. Use matching mod builds on both PCs. Capture full game-file version and SDK runtime/build versions.
3. Host and join, then load an identical mission on both PCs. Record the Co-op UI `synced` state, not merely `connected`.
4. Check whether radar/name tag appears with fresh network positions even if NPC stand-in fails.
5. In Co-op > About > Copy diagnostics, inspect `Partner's 47` and record whether the stand-in waits for an outfit, NPC template or a remote position.
6. Collect `Retail\\mods\\HitmanCoop.log` from both PCs and `HitmanCoop-crash.txt` if produced. Compare scene IDs and epochs.
7. Verify game restart/reconnect and no ghost radar dot after the guest leaves.

## Remaining compatibility risk

The source's `tools/fetch-sdk.ps1` pins ZHMModSDK v4.1.1 and private game hooks documented against 3.280.0. ZHMModSDK v4.2.0 is the first official SDK release claiming 3.290.1.0 support and contains breaking changes. A build using v4.1.1 demonstrates compilation against an older SDK, **not** compatibility with the current HITMAN build.

Do not deploy this experimental native DLL as a fix for 3.290.1.0 until its game-version-specific native assumptions have been reviewed and it has passed real two-PC gameplay tests.

## What the old SDK hid

Comparing the official v4.1.1 and v4.2.0 DevPkg headers revealed that the
`ZHitman5::m_rOutfitKit` field moved from offset `0xFC0` to `0x1010`.
`m_nOutfitCharset` moved `0xFD0` to `0x1020`, and `m_nOutfitVariation`
moved `0xFD4` to `0x1024`. This project reads these fields in
`SdkWorld::GetLocalOutfit`, which feeds stand-in spawning, so the original
v4.1.1-compiled plugin may read invalid outfit data on HITMAN 3.290.1.0.
This is a specific candidate mechanism, **not confirmed as the player's exact bug**.

An isolated build now compiles against v4.2.0 with both packages verified
against the GitHub release SHA-256 checksums. Run
`powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-sdk420.ps1`
in the cloned folder to reproduce the build and tests; the script does not install.

## New copied diagnostics: Avatar transforms (this scene)

- **synced no**: the session/scene handshake is not yet complete; avatar packets
  are deliberately suppressed even if the TCP/UDP connection is connected
- **synced yes, queued 0, local read failures increasing**: the game adapter
  cannot obtain the local player's transform (SDK/player pointer/lifecycle)
- **synced yes, queued increases, peer received 0**: investigate protocol
  epochs, payload validation and network delivery; inspect both PCs
- **synced yes, received increasing, partner still not shown**: focus on stand-in
  spawn, outfit resource, NPC template, visibility and pose matching
- **received increasing but no new packet for over 2 seconds**: position markers
  are intentionally suppressed rather than keeping stale ghost positions

Build compilation and simulated tests do not validate the private animation
vtable slot, rig pointer offsets, CrashGuards patches or pause/restart hooks on
3.290.1.0. An SDK v4.2.0 build is **experimental and not deployment-ready**.
