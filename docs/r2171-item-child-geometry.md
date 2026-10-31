# HITMAN Co-op by Artur R2.17.1 — Item Child Geometry Visibility

**Experimental item-only visibility test**, Artur Edition **v0.12.18**, custom protocol **16**, HITMAN **3.290.1.0**, verified SDK **4.2.1**.

## User-confirmed one-way failure
With R2.17 installed on both PCs:
- When **laptop picks up an item**, the **main PC** correctly stops showing its model.
- When **main PC picks up an item**, the **laptop** disables the pickup but still draws the original item's model.
- Both game instances loaded the **same SHA256 hash** for `Retail/mods/HitmanCoop.dll`, both logged `HITMAN Co-op 0.12.17`.
- Main PC logs `item visibility: native hide id=...` for three laptop pickups; laptop logs the same for two main PC pickups, proving the reliable item event and native-hide routine ran **in both directions**.
- In both logs, root, `m_rGeomentity`, and `m_pGeomEntity` are the **same one spatial entity** (`spatial nodes=1 root=1 geom1=1 geom2=1`). This may not include the actual renderer child entity.

## R2.17.1 changes (only item rendering)
- The local item model's **transform hierarchy** is walked from each distinct root/geometry entity to its spatial children. Only child nodes with a matching `m_pTransformParent` are included; this avoids touching unrelated scene siblings.
- The traversal is bounded to **64 unique spatial nodes** per item, and linked-sibling iterations are also bounded; malformed cycles cannot hang the main game.
- The already-working R2.17 reversible native render-flag suppression now applies to the item **and its known child render nodes**, with a bounded 128-snapshot cap per item for churn. No stored raw pointer is dereferenced to restore a previously freed entity; current live item descendants are enumerated anew and matched by identity.
- The old `ZValueBool` and reflected visibility writes are retained. The existing R2.9 100ms scan reapplies suppression; no new background scans.
- **Enhanced diagnostic:** `item visibility: native hide id=<ID> spatial nodes=<N> direct=<N> children=<N>`. Use this on both PCs if a model still renders. This tells whether a child mesh is accessible through the item's transform subtree.
- Added `ItemVisibility_ChildTraversalDoesNotHideUnrelatedWorldObjects` core unit test covering nested descendants, unrelated sibling, finite traversal cap and malformed linked cycles.
- Version only bumped to 0.12.18. **No changes** to Steam invites, protocol, pickup exclusivity, surrender animations, physics, body drag syncing, disguises, friendly fire, fistfights or NPC ownership. All other R2.16/R2.17 behavior retained.

## Test on both PCs
1. Leave R2.17 installed as rollback if desired. Install **R2.17.1/v0.12.18** on both computers, each with the correct HITMAN 3.290.1 and SDK 4.2.1.
2. Join with the same working Steam invite.
3. Watch the **same coin/pistol on a table**; main PC picks it up, laptop observes whether its model vanishes. Drop the object and check appearance restores. Repeat **reverse direction**.
4. If laptop still sees it, inspect `HITMAN 3\\Retail\\mods\\HitmanCoop.log` on both computers for `item visibility: native hide`, especially `children=`. Zero children means the visible mesh may be an independent scene script/spawned prop not attached through the known item geometry references; further targeted instrumentation will be needed.
5. If the item disappears permanently, scenery vanishes, or either PC crashes, exit the mission, revert to R2.17, and share both logs.

**Not live verified.** Compilation and automated simulation cannot prove the HITMAN renderer's behavior. This is an experimental test, not a guaranteed fix. Previous Artur releases are preserved.

Original HITMAN Co-op by Jordan Rodrigues, GPL-3.0-or-later.
