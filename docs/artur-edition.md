# Artur compatibility edition — HITMAN Co-op 0.12.1 R2.1

This is an experimental fork of [HITMAN Co-op by Jordan Rodrigues](https://github.com/JordanRodrigues021/hitman-coop), distributed under the original GPL-3.0-or-later license. The launcher and in-game CO-OP window/header/About tab now show **by Artur**. The original author remains credited in the About tab and license; this does not replace the original creator's copyright or project history.

## Compatibility
- HITMAN World of Assassination executable **3.290.1.0**.
- **ZHMModSDK 4.2.0** runtime with the R2.1 native plugin (both computers must use the matching pair). R2.1 retains R2's networking and synchronization code, with only menu strings/credits modified in the plugin.
- Two-PC Freeform Training test passed on 2026-10-30: partner model, animation poses, names and radar visible on both systems. This is **not** validation of every mission, combat scenario, or disguise.

## Artur-branded installer
Build with `powershell -ExecutionPolicy Bypass -File tools/package-artur-r2.ps1` on the Windows build machine after the experimental R2 stage and matching NetTest utility have been built.

Result: `_dist/HitmanCoop-Setup-by-Artur-EXPERIMENTAL-R2.1.exe` and `_dist/HitmanCoop-0.12.1-3290-sdk420-EXPERIMENTAL-R2.1.zip`.
The embedded installer checks the expected game version and reads `Retail/mods.ini`: an installed but **disabled** Assassin Rivals 2 DLL is permitted, but an **enabled** `[AssassinRivals2]` entry blocks installation to avoid simultaneous multiplayer plugins. Installer testing covers compilation, embedded payload checks, synthetic enabled/disabled cases and 83 core tests; **not** a new in-game install or full gameplay regression.

The original mod loader and both PCs' HITMAN installations were restored after the successful live R2 test. The new R2.1 installer has **not** been run against either game installation; in-game UI visuals remain to be confirmed. The previously verified live R2 build remains independently preserved.

## Backup and GitHub
The Git repository retains the upstream history and all commits for the R2 bugfix and tests. Generated build directories (`_build*`), downloaded dependencies (`_deps*`), R2 distribution binaries (`_dist`), and raw test material (`_localtest`) are deliberately ignored by Git.

Back up those ignored assets separately, especially the signed-off R2 ZIP, Artur setup EXE and test evidence; do not claim they are backed up to GitHub unless a release upload has actually succeeded. Raw logs may contain local paths, IP addresses or machine information: review them before sharing.

Original creators and upstream dependencies remain credited in [CREDITS.md](../CREDITS.md) and the distribution license files.
