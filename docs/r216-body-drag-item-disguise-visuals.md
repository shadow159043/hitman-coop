# Artur Edition R2.16 — Body Release & Appearance Sync Preview

**Experimental prerelease, mod v0.12.16, protocol 16, SDK 4.2.1.** Source based on Artur Edition R2.15.1; user confirmed the R2.15.1 Steam invites, shared item pickup restriction, per-body disguise exclusivity, and existing first-key fistfights work.

## User-confirmed regressions / requests
- Inviting directly through Steam works reliably both ways. **Do not disturb this path.**
- Items become unpickable on the other PC but their models remain visibly present.
- A player can take a specific NPC disguise only once across clients, but the stripped NPC still appears in their old clothes on the other screen.
- Fake surrender: the hit/arrest animation appears, but the guard does not visibly approach correctly.
- Dragged bodies stay at their original location on the other PC after release.

## R2.16 code changes
1. **Drag-release body movement**: `CollectBodyChanges` now detects an actual player drag/dump transition, preserves the original position even when a drag starts within four seconds after a takedown, and sends an existing reliable `ItemFlag_Body` event at the *new resting transform* after ~0.35 seconds and brief settling. Supports drags longer than 0.4 m instead of the old >1.5 m threshold. Ordinary physics settling without player dragging is never reported as a move. Receiving PC attempts to reposition its NPC to the requested transform, while suppressing bounce-back events.
2. **Item model visibility**: while a peer owns a shared scene item, repeated visibility updates now hide its **root scene entity** as well as both known geometry refs, the item's `ZValueBool` visible flag, and its pickup-enabled flag. Restores them when the item becomes available again or the peer disconnects. This is a cosmetic-only change; pickup exclusivity was already working.
3. **Stripped-body appearance sync**: selectively ported the original v0.13.2 `ZActor_SetOutfit` detour and body outfit reliable mission event `Coop_BodyOutfit`, with strict parsing, bounds checks and no event echo from remotely applied changes. Clothing changes from stripping a downed NPC are forwarded to the other PC, which uses its local native actor outfit API. The receiver briefly queues a valid outfit change if the NPC's incapacitated state has not caught up yet.
4. **Testing**: Added unit tests for release-event criteria and non-human body movement suppression, and a simulated end-to-end reliable mission event delivery test.

## Not yet fixed / caveats
- **Fake-surrender guard approach is not corrected.** The animation and approach depend on AI target/owner/puppet state, which cannot be verified from source alone. This needs a reproducible two-PC scenario and log comparison before changing NPC AI behavior.
- The game uses ragdoll physics per PC. Even when the body-move event reaches the receiver, the **remote ragdoll may resist or undo a transform-only teleport**. R2.16 improves detection and transmission and attempts the reposition, but does not claim to fully solve physics relocation. Avoid unsafe ragdoll pointer modifications.
- Some items may continue to render if a game's scene script drives hidden meshes separately. This test adds root entity visibility but no unverified native mesh destruction; game-only testing required.
- Changing an NPC's outfit uses native engine code on the receiver, so any invalid or unknown outfit IDs/characters are rejected. Test initially in ICA Freeform Training with one knocked-out NPC; roll back if an outfit glitches.
- The native NPC punch/knockdown animations on the players are still experimental and are not solved by this update.

## Two-PC testing
1. Save a working R2.15.1 install for rollback. Both PCs install exactly **R2.16/v0.12.16**, HITMAN 3.290.1.0, SDK 4.2.1.0. Do not mix original 0.13.2 or old mod version.
2. Check **Steam invites** both directions and player movement. Keep testing the network path you confirmed works.
3. **Body drag**: knock out a guard, wait a few seconds, mark the original location, drag the body 2–5 m, release and wait ~1 second. Confirm on receiver if it moves to the same new location or stays behind. Repeat with 0.5–1m drag and early drag immediately after knockout. Check for message `body: ... dragged/released, sent resting position` (sender) and `body: ... moved by partner (repositioned here)` (receiver) in `HITMAN 3\\Retail\\mods\\HitmanCoop.log`.
4. **Item**: with both watching the same table, pick up a coin, pistol or other world item. Verify the object model disappears, not just its pickup prompt. Drop it and make sure it reappears. Switch roles.
5. **Disguise**: pacify one guard, steal their disguise, and see whether their stripped body changes appearance on the other PC. Check for `body: local outfit ... stripped` / `body: partner changed clothing ... (stripped)` in both logs. Switch roles.
6. **Fake surrender**: while already connected, have one player fake surrender. Observe which player owns the guard's NPC and whether the arresting guard approaches on both screens; share a short clip and each PC's relevant log. No fix is claimed yet.
7. Verify friendly fire, reaction-fistfight punches/stun, normal NPC attacks and R2.9 performance remain unaffected.

## Validation
Compiled against official SHA-256 verified SDK 4.2.1 in a separate Windows build tree; 102+ core tests, Steam regression tests, installer/ZIP integrity tests required before release. **No real two-PC R2.16 test yet.** Packaged files do not overwrite the user's game until they install them.

Original HITMAN Co-op by Jordan Rodrigues, GPL-3.0-or-later; Artur Edition custom modifications. R2.15.1 remains an independent rollback release.
