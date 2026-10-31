# Artur R2.18 — NPC disguise visual sync (experimental)

Mod version 0.12.20; protocol 16; HITMAN 3.290.1.0; ZHMModSDK 4.2.1.
Branch: fix/r218-npc-disguise-visuals (based on validated R2.17.2).

## Confirmed behavior before the patch

- Both peers receive the source NPC's disguise ID and cannot steal the same disguise twice.
- The NPC's stripped outfit does not always become visible on the remote computer.
- The native ZActor_SetOutfit hook only sends a body-outfit event when the NPC already registers as down and belongs to the NPC index. It can miss the actual strip event.
- The reliable player outfit update already carries sourceNpcId, so no new network message is needed.

## Change isolated to NPC clothing

When BlockPeerDisguise receives the existing source NPC ID, keep the normal pickup block and request that *specific NPC* be shown stripped by invoking native ZActor_SetOutfit with its own kit, charset and variation and nude=true. Never touch an unrelated NPC, the partner stand-in, a standing actor, or the local player's active takedown victim.

The fallback waits up to 12 seconds if the NPC is not yet down on the receiver. The already-existing reliable Coop_BodyOutfit event remains authoritative and prevents applying the same strip twice. Visual attempts are capped and cleared when leaving or changing scenes. Logs report successful native visual strips or retries timing out.

No edits to item model handling, Steam invitation or transport, player/NPC surrender, combat, duel, dragging or wire format.

## Two-PC validation

1. Fully close HITMAN on both machines. Install identical R2.18 (0.12.20) on both.
2. Join one mission using the working Steam friend invite.
3. Main PC subdues an NPC wearing a unique uniform, then changes into that NPC's disguise. On laptop, verify: NPC is rendered in stripped clothing, remains down, and disguise pickup is unavailable.
4. Reverse roles: laptop steals a different NPC's uniform; verify the PC sees the stripped body.
5. Try taking a disguise during a knockout animation as well as after the body fully settles.
6. Inspect Retail/mods/HitmanCoop.log for "disguise: body ... used by partner" and "disguise: native visual strip applied ...", or a "disguise: visual strip expired ..." error.
7. Confirm a normal suit change without an NPC source does not strip any NPC.

This is an experimental game-renderer change. Core tests and successful compilation do not prove the in-game NPC mesh rebuild. If the game crashes, NPC model disappears, or its pose breaks, close the game and restore the preserved R2.17.2 installer.

Original HITMAN Co-op author: Jordan Rodrigues. GPL-3.0-or-later.