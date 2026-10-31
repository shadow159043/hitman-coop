# Artur Edition R2.15.1 — SDK 4.2.1 startup compatibility hotfix

R2.15.1 / mod version 0.12.15, custom protocol 16, **experimental prerelease**.

## Why R2.15 was blocked
The R2.15 mod was compiled against and packaged with the official **ZHMModSDK 4.2.1**, and correctly supported HITMAN game version **3.290.1.0**. But its `HitmanCoop::Init` startup safety gate still required **SDK runtime 4.2.0.0**. When the correct 4.2.1 runtime was loaded, co-op deliberately disabled itself before applying native patches, showing an incorrect game incompatibility message.

## Fix
- The exact native compatibility pairing is now **HITMAN 3.290.1.0 + ZHMModSDK 4.2.1.0**. This is checked at startup and remains **fail closed** for other unknown game or SDK versions. The guard is not bypassed.
- Added a standalone `coop/RuntimeCompatibility.h` constant and automated regression test for the expected accepted pair and rejection of outdated SDK 4.2.0, unknown runtimes and unsupported game versions.
- Corrected the red error message to distinguish the mod's game/SDK compatibility check from an outdated game. No need to reinstall HITMAN when the loaded game version already matches.
- Internal mod version incremented to **v0.12.15** so clients must both use the corrected build.
- Rebuilt and packaged with the same official, SHA-256-verified SDK 4.2.1 files as R2.15; no native hooks or gameplay algorithms modified.

## Preserved R2.15 features
Original upstream 0.13.2 item-list and subcontroller-owner fixes, improved guard arrest/chase ownership, body physics guard, R2.9 performance tuning, R2.11 friendly fire, R2.13 punch QTE, and optional R2.14 pose-animation experiment remain unchanged. We still do not import upstream's automatic updater or body clothing transfer, and upstream 0.13.2 protocol 13 cannot interoperate with our protocol 16.

## How to test
1. Leave game and mod fully closed. Back up your R2.14 working installation if useful.
2. Install **R2.15.1** on *both* PCs, not old R2.15. Required actual versions: game 3.290.1.0, SDK 4.2.1.0, Artur Edition 0.12.15.
3. Start HITMAN and open the CO-OP panel. The red compatibility error should no longer appear; if it does, inspect both loaded version numbers and the game log.
4. Connect in the same mission, confirm partner movement. Test item pickup/drop, NPC chase/arrests, disguise changes, friendly fire, fistfights and body hiding; watch for performance regressions.
5. This build has only automated SDK compilation, transport, and package integrity checks, **not live two-PC confirmation**. If a crash or animation issue occurs, stop testing and revert to R2.14.

Original HITMAN Co-op by Jordan Rodrigues (GPL-3.0-or-later). Older R2.15 and R2.14 releases are preserved.
