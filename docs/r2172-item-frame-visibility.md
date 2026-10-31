# HITMAN Co-op by Artur — R2.17.2: Item Visibility Per-Frame Test

Experimental item-only hotfix. Internal mod version **v0.12.19**, custom protocol **16**, HITMAN **3.290.1.0**, SDK **4.2.1.0**.

## User's R2.17.1 evidence

Real two-player test of R2.17.1 (v0.12.18) showed:
- Main PC picks up item: laptop blocks pickup and sometimes hides the model.
- Laptop picks up item: main PC blocks pickup and sometimes still draws the model.
- Visibility direction flips between test sessions, and failures are intermittent in **both** directions.
- Both PCs loaded the exact same DLL in R2.17. R2.17.1 logs **on both PCs** confirm receipt of a remote pickup event and successful enumeration of the item's native scene nodes.
- R2.17.1 logs in latest test: laptop had item child counts **12 and 53**, main PC had **41, 11, 11**. Thus item model child traversal works at least structurally. Game-native scene script / render flags may be refreshed *after* the 100ms item scan.

## Single-problem change

Previous code re-applied visual hiding only in `CollectItemChanges`, once every **100ms**. R2.17.2 retains that existing inventory scan but **also re-applies the renderer's native hide flags every game frame** for already-recognized remote-held items.

- The existing 100ms indexed scan caches current scene item entity references only for peer-held items.
- The game-frame pass uses at most 64 known items. It does *not* perform an expensive full inventory scan per frame and does not send new network packets. It writes native visibility flags but **does not invoke reflected property-change handlers every frame**; those remain on the original slower scan.
- Item child traversal and exact original render-flag snapshots from R2.17.1 are preserved, as are restores on drop or disconnect.
- The cached identities are cleared on scene teardown, on disconnect, and on drop; the normal inventory scan also evicts references to despawned items and rebuilds snapshots if an entity changes.
- Diagnostics now report `item visibility: game re-enabled model id=<id> count=<N>` when existing native-hidden nodes become visible again (at 10, 90, 450 observations), in addition to `item visibility: native hide ... children=...`.
- No change to Steam networking, session protocol, pickup ownership, disguises, body dragging, fake-surrender animations, combat, friendly fire, duel/QTE, SDK or HITMAN installation.

## First experiment

1. Fully close HITMAN on **both** computers, then install matching **R2.17.2, mod v0.12.19**, with SDK 4.2.1 and game 3.290.1.0.
2. Join ICA Facility Freeform Training using the same working Steam invite path.
3. Stand together and choose a clearly identified pistol or coin. **Main PC picks it up first**, laptop checks model and interaction prompt for at least three seconds.
4. Drop it and ensure the model reappears and can be picked up again. Repeat with laptop picking it up and PC observing.
5. Repeat with at least three distinct items, as the bug has been inconsistent.
6. If any model remains, inspect both `HITMAN 3\\Retail\\mods\\HitmanCoop.log` and send `item visibility` messages, especially **game re-enabled model count**. If crashes, broken world geometry or FPS drops occur, revert to preserved R2.17.1.

## What this does not prove

Compilation, core tests, installer integrity and Steam probe tests do **not** prove model disappearance in HITMAN's live renderer. This is an experiment to test the per-frame renderer reset hypothesis, not a guaranteed fix.

Original HITMAN Co-op created by Jordan Rodrigues; GPL-3.0-or-later. Artur Edition R2.17.1 and older release artifacts remain preserved.
