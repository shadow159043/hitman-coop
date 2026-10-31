# Artur compatibility edition — HITMAN Co-op 0.12.1 R2

This is an experimental fork of [HITMAN Co-op by Jordan Rodrigues](https://github.com/JordanRodrigues021/hitman-coop), distributed under the original GPL-3.0-or-later license. The launcher's visible credit reads **by Artur**; it does not replace the original author's copyright or project history.

## Compatibility
- HITMAN World of Assassination executable **3.290.1.0**.
- **ZHMModSDK 4.2.0** runtime with the R2 native plugin (both computers must use the matching pair).
- Two-PC Freeform Training test passed on 2026-10-30: partner model, animation poses, names and radar visible on both systems. This is **not** validation of every mission, combat scenario, or disguise.

## Artur-branded installer
Build with `powershell -ExecutionPolicy Bypass -File tools/package-artur-r2.ps1` on the Windows build machine after the experimental R2 stage and matching NetTest utility have been built.

Result: `_dist/HitmanCoop-Setup-by-Artur-EXPERIMENTAL-R2.exe`.
The embedded installer enforces the expected game version and refuses installation while Assassin Rivals 2 is installed, to avoid simultaneous multiplayer plugins. Installer testing has been limited to source/payload checks and successful compilation, **not** a new live installation or full-game regression test.

The original mod loader and both PCs' HITMAN installations were restored after the successful live R2 test. The new installer has **not** been run against either game installation.

## Backup and GitHub
The Git repository retains the upstream history and all commits for the R2 bugfix and tests. Generated build directories (`_build*`), downloaded dependencies (`_deps*`), R2 distribution binaries (`_dist`), and raw test material (`_localtest`) are deliberately ignored by Git.

Back up those ignored assets separately, especially the signed-off R2 ZIP, Artur setup EXE and test evidence; do not claim they are backed up to GitHub unless a release upload has actually succeeded. Raw logs may contain local paths, IP addresses or machine information: review them before sharing.

Original creators and upstream dependencies remain credited in [CREDITS.md](../CREDITS.md) and the distribution license files.
