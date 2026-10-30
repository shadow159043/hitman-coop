# Live launch tests — 2026-10-30 (HITMAN 3.290.1.0)

The user authorized testing the isolated Co-op 0.12.1 R2 build. Tests were performed on the connected main PC; the second laptop was offline. No remote player joined, so this cannot establish whether the stand-in now spawns in multiplayer.

## Test 1 — direct HITMAN3.exe launch

- Backed up original Retail SDK files and entire Retail/mods root-file set, recording SHA-256 per file
- Temporarily installed verified SDK 4.2.0 and experimental Co-op R2; disabled the conflicting AssassinRivals2.dll and Editor.dll
- Game started and loaded ZHMModSDK.dll and HitmanCoop.dll, but exited shortly after startup
- No matching Application Error event was found in Windows Event Viewer
- Loader reported six patch signatures applied and Co-op module loaded
- Collected logs and restored SDK + mods, verifying all recorded original-file SHA-256 hashes

Report: `_localtest/smoke-20261030-195333/`

## Test 2 — normal Steam launch

- Same backup, isolation, temporary install, and hash-verified restoration
- Launched with Steam application ID 1659040
- Game remained running, loaded SDK and Co-op modules, and reached Co-op frame initialization
- The copied test log contains: `HITMAN Co-op 0.12.1 by Jordan Rodrigues is ready. Press ~ and click CO-OP.`
- Loader reported six crash-protection patches applied
- Game was closed by the test harness, and all original SDK/mod files were restored with verified hashes
- The loader also warned that EOSSDK-Win64-Shipping.dll could not be loaded for EOS_Platform_Create and that crash-reporting's SetUnhandledExceptionFilter patch was not found; neither warning prevented Co-op initialization in this startup check

Report: `_localtest/smoke-20261030-195448/`

## What remains unverified

- Loading the actual mission under SDK 4.2.0
- Host/guest handshake on both PCs
- Partner character model spawning, outfits, animations, name tag, or radar
- Runtime stability in combat, changing disguise, restarting or rejoining
- Native PoseHook's private seven-argument interface and output-pose layout under 3.290.1.0

The second laptop was offline at test time, so these could not be completed.
The original installed SDK remains v4.1.1.0, and neither Assassin Rivals nor installed Co-op was permanently replaced. The experimental R2 archive remains in `_dist`.
