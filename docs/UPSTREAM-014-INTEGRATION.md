# Artur Edition — integration of Jordan's HITMAN Co-op v0.14.0

**Status:** Artur Edition v0.14.2 fixes the hard-coded SDK compatibility blocker and is the [latest experimental release](https://github.com/shadow159043/hitman-coop/releases/tag/artur-v0.14.2). The previous 0.14.0 release remains available. Live multiplayer and physical Steam Deck update testing are still required.

## Base and preserved work

The integration is a real Git merge from Jordan Rodrigues's official Git tag `v0.14.0` into shadow159043's Artur Edition branch. Jordan remains the original creator and copyright holder. It preserves the fork's Artur presentation, avatar position/visibility diagnostics, network status counters, partner outfit safety validation, the independent Linux/Steam Deck Mission Control/AppImage source and existing R2.18.1 release history.

Upstream components added by the merge include the flight recorder/blackbox and crash reporting, improved body and dropped-item positions, NPC position/pose alignment and ownership behavior, scripted mission actions, game-server reconnection tuning, the updated Windows GUI installer with Tailscale help, the v0.14.0 Linux installer, and separate game 3.290 and 3.280 SDK builds.

The underlying game and co-op code is experimental. This merge does not claim to have passed a live two-PC session or physical Steam Deck test.

## Version and compatibility

* Upstream code base: `0.14.0`; current Artur Edition mod version: `0.14.2`, with **protocol 21** to prevent cross-fork peer mismatches with Jordan's official protocol 18 and the previously shipped Artur protocol 16.
* Both peers must install this same Artur integration when binaries are released; **no** mixing with Jordan v0.14.0 or Artur R2.18.1.
* The [published R2.18.1 release](https://github.com/shadow159043/hitman-coop/releases/tag/artur-r2.18.1-npc-disguise-safety-20261031) has not been changed.
* New source-based Linux installation and the old Artur Mission Control AppImage have different payload formats. **Do not use the old R2.18.1 AppImage to install or repair this v0.14.0 integration.** A matching new installer must be built and tested.

## Updater safety

Jordan's signed update manifests and public key cannot be repurposed for Artur Edition. Starting in 0.14.1, Artur Edition embeds its **own ECDSA P-256 public key** and checks the fork's signed `updates` branch with SHA-256 validation. The private key lives only in the release PC's gitignored `.signing/update-key.blob`; it must be backed up securely. Official Jordan DLLs are never downloaded over Artur Edition. 0.14.0 and earlier need a one-time manual upgrade; Proton/physical Steam Deck updating is still unverified.

## Gameplay validation still needed after publishing the experimental release

1. Pass Windows core tests, Linux installer static checks, build the mod against pinned SDK 4.2.1 (game 3.290), and validate the build for SDK 4.1.1 (game 3.280).
2. Package matching Windows and Linux artifacts; ensure the new Linux installer is not a renamed R2.18.1 payload. Verify hashes and file versions.
3. Test Windows to Windows and Windows to SteamOS / Steam Deck connections, room code, join through Tailscale, reconnect, restart, exit, body dragging, items and disguise ownership.
4. Verify About > Save bug report produces the blackbox and correct Artur Edition version/protocol.
5. Promote a future build to fully validated stable status only after live gameplay succeeds; keep the current v0.14.0 release explicitly marked experimental in the meantime.

## Credits

Original HITMAN Co-op created and developed by Jordan Rodrigues, licensed under GPL-3.0-or-later. This is an independent Artur Edition fork; original author and contributors remain credited in [CREDITS.md](../CREDITS.md).
