# HITMAN Co-op by Artur — R2.17 Item Visibility Only

Experimental isolated item-rendering test / mod **v0.12.17** / custom protocol **16** / SDK 4.2.1 / HITMAN 3.290.1.0.

## Motivation
Two-player testing of R2.16 established that picking up an item on PC A already makes it non-interactable on PC B, but its 3D model remains on the table on PC B. This means the existing item ownership event is reaching the peer. This change targets **only the receiver's graphics state**. It is not a change to networking, item ownership, or physics.

## Source changes
- Preserve existing item pickup/drop behavior and the 100ms item scan from R2.9.
- Under the receiver's per-item visibility override, cache the original **native `ZSpatialEntity` render visibility flags** for the root and the two known item geometry entities: `m_bVisible`, `m_bParentHidden`, `m_bForceVisible`.
- In addition to the existing reflected `m_bVisible` and `ZValueBool` switches, set native renderer flags directly to hidden (including disabling force-visible), and reapply on existing 100ms scans if the game re-enables them.
- On a drop / peer leave, **restore the exact original native render flags** only if the current item pointers still match the saved snapshot. This avoids dereferencing stale scene entities or blindly making an originally hidden prop visible.
- Add bounded, one-time-per-item diagnostics: `item visibility: native hide id=<id> spatial nodes=<count> root=<0/1> geom1=<0/1> geom2=<0/1>` to the existing `HITMAN 3\\Retail\\mods\\HitmanCoop.log` file.
- Add pure `ItemVisibility.h` with a regression test for hide/restore rules.
- No modifications to Steam invitations, networking, NPC surrender, body dragging, disguise handling, melee, or fistfights. Their R2.16 behavior is unchanged (including unresolved R2.16 body/disguise issues).

## First two-PC test
1. Leave R2.16 available as rollback. Install matching Artur Edition **R2.17 / 0.12.17** on both machines, with the unchanged official SDK 4.2.1.
2. Both enter the ICA Facility Freeform Training mission using the known-working Steam invites.
3. Both watch the same **coin or pistol on a table**. Player A picks it up. On PC B, confirm whether the **entire item model disappears**, not just its pickup prompt. Reverse roles.
4. Have player A drop the item and verify it reappears naturally for Player B. Repeat with a second item.
5. After one pickup, check `Retail\\mods\\HitmanCoop.log` on the receiver for `item visibility: native hide id=`. If the model still renders, the `spatial nodes` and `geom1/geom2` fields tell us whether the model is on a separately owned template/mesh not exposed by `ZHM5Item`.
6. Verify no crash or permanent prop disappearance when leaving/rejoining, restarting a mission, or picking up and dropping again.

## Limits
Native visibility flag writes are compiled and unit-tested but not yet **visually verified in HITMAN**. Some scene props may have an independent render mesh and ignore these flags; do not treat this as a guaranteed fix until the user tests both screens. Do **not** destroy, teleport, or reparent the logical item as a visibility workaround: those would risk breaking already-working pickup locks and game physics.

Builds must pass SDK compilation, core tests, Steam probe regression tests and package integrity verification. Original HITMAN Co-op by Jordan Rodrigues, GPL-3.0-or-later. R2.16 and earlier releases are preserved.
