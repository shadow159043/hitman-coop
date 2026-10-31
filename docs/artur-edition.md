# Artur compatibility edition — HITMAN Co-op 0.12.2 R2.3

This is an experimental fork of [HITMAN Co-op by Jordan Rodrigues](https://github.com/JordanRodrigues021/hitman-coop), distributed under the original GPL-3.0-or-later license. The launcher and in-game CO-OP window/header/About tab now show **by Artur**. The original author remains credited in the About tab and license; this does not replace the original creator's copyright or project history.

## Compatibility
- HITMAN World of Assassination executable **3.290.1.0**.
- **ZHMModSDK 4.2.0** runtime with the R2.3 native plugin on both PCs, **Co-op 0.12.2 / protocol 13**. R2.3 adds room-code/password checks to the existing multiplayer handshake; it cannot connect to older R2/R2.1/R2.2 clients.
- Two-PC Freeform Training test passed on 2026-10-30: partner model, animation poses, names and radar visible on both systems. This is **not** validation of every mission, combat scenario, or disguise.

## Custom rooms (Artur R2.3)
- Before pressing HOST, enter a custom room code (4-16 uppercase letters, numbers or hyphens) or keep the generated code; optionally tick **Require a password** and enter a session-only password of at least four characters.
- Friend opens **CO-OP > Play > Join a friend** and enters the **host LAN/Tailscale IP and UDP port** (or a relay-issued join code if both PCs use the same relay), **room code**, and **room password** if set.
- While hosting, open the in-game CO-OP window with `~`. Directly below **Leave session**, Room details shows the addresses, port, room code, relay code if present, password status and **Copy full invite**. Copying an invite includes any password; share privately.
- A custom room code is **not** a globally routed join code. Without a configured relay, your friend needs an IP/Tailscale connection. No public co-op server is bundled.
- Authentication is checked **before gameplay synchronization**; invalid room codes or passwords are rejected. **The game transport is not encrypted, and the password is transmitted in the handshake.** Do not reuse an account password, and do not treat the password as protection against network eavesdropping. Passwords are kept in memory, not saved in the settings file.
- R2.3 uses protocol 13; previous mod versions cannot connect to R2.3. Both PCs need the R2.3 DLL and matching SDK.

## Artur-branded installer
Build with `powershell -ExecutionPolicy Bypass -File tools/package-artur-r2.ps1` on the Windows build machine after the experimental R2 stage and matching NetTest utility have been built.

Result: `_dist/HitmanCoop-Setup-by-Artur-EXPERIMENTAL-R2.3.exe` and `_dist/HitmanCoop-0.12.2-3290-sdk420-EXPERIMENTAL-R2.3.zip`. The installer automatically checks Steam's registered path, standard Steam roots and extra libraries, the 1659040 appmanifest, Epic .item manifests and LauncherInstalled.dat, and Legendary/Heroic. Browse remains available for other/custom installations.
The embedded installer checks the expected game version and reads `Retail/mods.ini`: an installed but **disabled** Assassin Rivals 2 DLL is permitted, but an **enabled** `[AssassinRivals2]` entry blocks installation to avoid simultaneous multiplayer plugins. Installer testing covers compilation, embedded payload checks, synthetic enabled/disabled cases and 84 core tests; **not** a new in-game install or full gameplay regression.

The original mod loader and both PCs' HITMAN installations were restored after the successful live R2 test. The R2.3 installer was tested via compilation, extracted payload and isolated synthetic library folders; it has **not** been run in install mode against either game installation. In-game UI visuals remain to be confirmed. The previously verified live R2 build remains independently preserved.

## Backup and GitHub
The Git repository retains the upstream history and all commits for the R2 bugfix and tests. Generated build directories (`_build*`), downloaded dependencies (`_deps*`), R2 distribution binaries (`_dist`), and raw test material (`_localtest`) are deliberately ignored by Git.

Back up those ignored assets separately, especially the signed-off R2 ZIP, Artur setup EXE and test evidence; do not claim they are backed up to GitHub unless a release upload has actually succeeded. Raw logs may contain local paths, IP addresses or machine information: review them before sharing.

Original creators and upstream dependencies remain credited in [CREDITS.md](../CREDITS.md) and the distribution license files.
