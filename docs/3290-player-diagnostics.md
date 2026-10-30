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
