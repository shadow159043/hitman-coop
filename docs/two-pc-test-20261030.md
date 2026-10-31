# Experimental R2 — live two-PC test, 2026-10-30

## Test environment

- Both Windows PCs ran **HITMAN World of Assassination 3.290.1.0** from Steam (app 1659040)
- Both temporarily loaded the **HITMAN Co-op 0.12.1 R2** fork compiled against **ZHMModSDK 4.2.0**
- The laptop's R2 package was transferred from the desktop over LAN and independently checked against SHA-256 `FA1ABC04FDE88BBF327DEE69A5A21174A0214859B2D5ED7BEBDFA90D5496EFBA`
- Direct LAN hosted UDP session on the original configured Co-op port, both clients joined and remained connected
- Laptop used HITMAN offline mode after its Steam validation failed; the Co-op peer-to-peer session worked independently
- Both game clients enabled the existing `test_control` channel only for this test, then had their original INI files restored

## Mission

Both PCs started **Prologue / ICA Facility / Freeform Training**, reported the same loaded scene:

`assembly:/_PRO/Scenes/Missions/TheFacility/_Scene_Mission_Polarbear_Module_002_B.entity`

Both status reports showed:
- `state: Connected`, `synced: true`, `inScene: true`
- `partnerSpawned: true`, `partnerSpawnFailed: false`
- Partner actor enabled, activated, alive, not hidden
- Same rig/skeleton (231 bones), partner poses arriving and animation updates increasing
- Name tags and radar indicators visible on both screens

### Live diagnostics snapshot

| Metric | Desktop / host | Laptop / client |
| --- | ---: | ---: |
| Peer RTT | 31.2 ms | 28.1 ms |
| Avatar transforms queued | 2,998 | 3,188 |
| Avatar transforms received | 2,967 | 3,219 |
| Local avatar read failures | **0** | **0** |
| Partner distance | 3 m | 3 m |
| Partner model status | Shown, posed | Shown, posed |

Both test logs reported: `partner: shown, posed with the matched skeleton`.

A controlled ~1.5-second forward movement on the laptop displaced it by several meters. The host's received remote coordinates updated, and a screenshot taken on the host visibly showed **two separate characters**, with **"Test client"** above the remote model.

Evidence under:
- Desktop: `_localtest/twopc-live-20261030/control.trace`, `current-desktop.jpg`, and `test-logs/`
- Laptop: `C:\Users\shado\Documents\HitmanCoop-Bugfix-R2-Test\twopc-live-20261030\control.trace` and `test-logs/`

## Result

**PASS for the originally reported failure scenario on this mission**: host -> guest joins -> both load matching mission -> remote NPC stand-ins spawn and render -> name tags, radar and transforms function.

This does **not** establish that the exact underlying root cause among the SDK upgrade and other R2 changes was isolated. It also does not prove stability across every mission, outfit/disguise, combat, kill, restarting mission or prolonged gameplay.

## Rollback

After the test, both clients issued `leave`, the games were closed, and the SDK/runtime files and complete `Retail/mods` original-file sets were restored from per-machine backups.

Both restoration tools reported **RESTORED_SHA_VERIFIED**, checking the original files' SHA-256 hashes. Game processes were no longer running. The desktop's SDK returned to v4.1.1.0 and its original Co-op DLL hash `BF1AC6B8E7F3A9E838A0A305D4127A85998367082D3312210620BDBEE68F76AF`. The same verified rollback was reported on the laptop.

The build remains experimental and separate from Assassin Rivals 2.0. It was **not left installed**.
