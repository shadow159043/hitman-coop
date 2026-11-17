# HITMAN Co-op - Artur Edition 0.14.0 (Experimental Update)

**The newest Artur Edition release.** This is a substantial, **experimental** integration of Jordan Rodrigues's HITMAN Co-op v0.14.0, plus Artur Edition improvements and new mission-restart crash protections. Automated tests and builds pass, but the new multiplayer build has **not yet been validated in a real two-player session or on physical Steam Deck hardware**.

## Download and install

- **Windows (recommended):** `HitmanCoop-Setup-by-Artur-0.14.0.exe` - the one-file installer, which detects HITMAN game 3.290.x or 3.280.x and selects matching files.
- **Windows ZIP:** `HitmanCoop-Artur-0.14.0.zip` - extract everything and run `HitmanCoop-Setup.exe` inside the extracted folder.
- **Steam Deck / SteamOS / Linux (Proton):** `Artur-Edition-0.14.0-SteamDeck-Linux-Installer-x86_64.AppImage` - in Desktop Mode, mark executable if necessary and launch the standalone installer.
- **Linux script alternative:** `HitmanCoop-Artur-0.14.0-linux.tar.gz` - extract and use the included `installer.sh`.
- `.sha256` files accompany each download so you can verify integrity.

**Both players must use this exact Artur Edition release (network protocol 21)**. It will **not** connect to official Jordan v0.14.0 (protocol 18), the older Artur Edition R2.18.1 (protocol 16), or earlier Artur 0.14.0 development builds (protocol 19/20). Do not mix their DLLs or installers.

## Changes

- Integrates original upstream v0.14.0 improvements to NPC and pose synchronization, bodies, dropped items, scripted mission events, network behavior, in-game diagnostics and crash flight recorder.
- Preserves Artur Edition branding, avatar/visibility diagnostics, outfit safety checks, and Steam Deck / Proton installer support.
- Adds restart-message epoch checks so a late restart command for an older run cannot restart the newly loaded mission.
- Scopes world-affecting mission events to the current session epoch; old body, item, and scripted events are discarded during reloads.
- Skips incoming skeleton/rig updates while a mission is unloaded or unsynchronized.
- Includes scene cleanup / restart guard work from upstream, including a guard for a reported HITMAN 3.290.1 crash at `HITMAN3.exe+0x16AB68`. Static signature checks passed against the tested 3.290.1 executable; actual in-game prevention is not proven.
- Windows 3.290 and 3.280 builds, core/regression tests, relay tests, and standalone Linux AppImage smoke tests pass in GitHub Actions.

## Important limitations

- **Experimental:** two-PC restart, connect, disconnect, NPC behavior, inventory, outfit handling, and physical Steam Deck tests are still needed. This release should not be represented as proven crash-free.
- This is a fan-made modification and is not affiliated with IO Interactive.
- Automatic in-game updates are **disabled** for this fork until it has its own signed update feed. Install new versions manually.
- Windows setup files may be unsigned and can trigger antivirus / SmartScreen warnings. Obtain files only from this repository's Releases page.
- Back up your existing mod installation before upgrading. The previous R2.18.1 release remains available for rollback, but both players must roll back together.
- For crash debugging, go to **CO-OP > About > Save bug report** in each game. The report ZIPs are under `Retail\mods\HitmanCoop-reports`; avoid sharing minidumps publicly because they can contain process memory.

## Credits

Original HITMAN Co-op created by **Jordan Rodrigues**, with contributions credited in [CREDITS.md](https://github.com/shadow159043/hitman-coop/blob/artur-v0.14.0/CREDITS.md). This is an independent Artur Edition fork under GPL-3.0-or-later. Thanks to all upstream and fork contributors.

Build revision: `9892342` and any subsequent release-documentation-only changes.
