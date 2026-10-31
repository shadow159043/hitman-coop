# HITMAN Co-op by Artur — R2.15 Upstream v0.13.2 Compatibility Preview

**Experimental partial upstream integration**, mod version **0.12.14**, custom multiplayer protocol **16**. This release is **not the original v0.13.2** and **cannot connect to the original v0.13.2's protocol 13**. Both Artur Edition players must install exactly the same R2.15 build.

## Source provenance
The user supplied:
- `hitman-coop-0.13.2.zip` source archive
- `HitmanCoop-0.13.2.zip` official packaged runtime

The source archive's git blob hashes for CHANGELOG.md, SdkWorld.cpp, Session.cpp and Updater.cpp **exactly matched** the public official git tag `v0.13.2`, after fetching it from `https://github.com/JordanRodrigues021/hitman-coop.git`. Changes were selected and ported, not wholesale copied, so we could preserve R2.9 optimizations, R2.11 friendly fire, R2.13 reaction-fistfight gameplay, and R2.14 opt-in animation experiments.

## Ported in this experimental branch

1. **Game 3.290.1 item list layout** — upstream found world inventory items moved by +0x40 from the SDK header offset; the mod now checks both the SDK's layout and the shifted +0x40 layout before enumerating, rather than walking a stale `m_aItems` member. All held/back-weapon and world-item enumeration paths also use the corrected list. The existing per-scan inventory index and lazy item repository-ID formatting are retained.
2. **Owned item detection** — taking/holding items can mark 47's character or subcontrollers as the item owner, not the outer 47 entity. Use the official upstream owner-reference set to detect these cases and preserve the custom "already tracked but no longer owned" guard against drops.
3. **Guard arrests and combat ownership** — on the host, an NPC that the client's game reports in hunting/arresting/fighting tension (6+) is temporarily assigned to the client's game for 2 seconds, even if the host is physically nearer. This prevents the host puppet from interrupting a locally running arrest. The host evicts expired records and clears them with the session. A new automated two-player simulation covers the handoff and return.
4. **Bodies disappearing due to ragdoll physics** — only report moved corpses as player movement if 47 really dragged or dumped them. Bodies explicitly placed in hiding spots still transmit normally. This intentionally preserves our custom body-reposition logic, which differs from upstream.

5. **ZHMModSDK v4.2.1** — official v4.2.1 development and runtime archives were fetched side-by-side with SHA-256 checks against upstream's pinned values, compiled and used in the R2.15 package (instead of older v4.2.0). Upstream identifies this upgrade as important for current 47 outfit detection. SDK core runtime files packaged are the verified v4.2.1 release assets.

## Not yet imported — deliberate

- **Automatic updater**: the original updater is hardcoded for the original project's latest releases and would overwrite our fork with a protocol-incompatible DLL. No automatic upstream updates are installed.
- **All stripped-body clothing synchronization**: upstream added a ZActor_SetOutfit detour, new body outfit mission event and recipient application. It needs a carefully integrated event handler and multi-PC verification; **not yet merged**.
- **All body hiding/AI unseen guards**: upstream deactivates remote bodies and uses unseen AI agents; our fork has different relocation behavior. Still needs safe merging.
- **Real NPC fistfight animations**: R2.14's cosmetic pose system stays experimental; native melee/ragdoll is not solved by upstream v0.13.2.
- **Full end-to-end real HITMAN multiplayer test**: only simulated sessions and SDK compilation/test packaging are verified so far.

## Testing plan for two PCs

1. Back up R2.14 and confirm installed HITMAN **3.290.1.x** on both PCs.
2. Install identical **Artur Edition R2.15, v0.12.14, SDK 4.2.1**, on both PCs. Keep original upstream v0.13.2 installation separate; do **not** mix its DLL with our mod.
3. Join the same mission over the previously working connection, verifying R2.9 performance, player stand-ins, appearance, R2.11 friendly fire, and R2.13 reaction-based fistfights and knockdown.
4. Place an item on a table, take it on PC A and check it disappears on PC B. Drop it and confirm the state returns or appropriate cosmetic copy appears. Switch roles. Try items from Freeform Training's table.
5. Take a disguise and check outfit changes on the remote stand-in. The SDK upgrade should help, but stripped-body clothing mirroring is **not** yet imported.
6. Stand near each other while a guard arrests or fights the client: check no frozen guard or crash and that it resumes host ownership when it calms.
7. Pacify an NPC and let its body settle on its own. It must not unexpectedly disappear on the other PC. Drag a different body and hide it, checking previous behavior is preserved.
8. If crashes, distorted characters or missing items occur, revert to R2.14 and send both files `HITMAN 3\\Retail\\mods\\HitmanCoop.log` and relevant crash diagnostics.

## Verification

Only report successful live behavior if both machines were actually tested. A passing build with 99 automated tests and package integrity checks does **not** verify dynamic HITMAN offsets or SDK runtime behavior inside a mission.

Original HITMAN Co-op created by Jordan Rodrigues (GPL-3.0-or-later); upstream release v0.13.2 published 2026-10-31. R2.15 is an independent experimental adaptation.
