# HITMAN Co-op by Artur — R2.10 Friendly Fire TEST

**Experimental, non-lethal player HP transfer. NOT verified in live two-player HITMAN.** Original HITMAN Co-op created by Jordan Rodrigues, GPL-3.0-or-later. This edition is not affiliated with IO Interactive.

Requires HITMAN 3.290.1.x, ZHMModSDK 4.2.0, and v0.12.9 on **both PCs** (network protocol 16). No in-game files are modified by packaging.

## What is implemented

- A **Friendly fire (experimental)** checkbox is in CO-OP → Settings → Playing together. **OFF by default**; both players must explicitly enable it.
- Already-installed SDK hook `ZActor_YouGotHit` detects a hit on the partner stand-in. Existing protection remains in place so its NPC body cannot be killed or destabilize the game.
- If the shooter opted in, the session is synced and the local character has a visible held firearm, accumulated hits are relayed through a bounded, reliable `Coop_FriendlyDamage` mission event. The event carries only 1–3 hits, not untrusted damage amounts or health values.
- The victim's own game accepts the event **only** when friendly fire is locally enabled, session/scene is synced, the level is playing, and the local player has plausible valid HP and isn't invincible. HP decreases by 12% of local max HP per received hit, with a separate receiver-side cap of six hits per second.
- Damage currently stops at **1 HP**. Native HITMAN player-death and hit-reaction functions are not exposed in the current SDK headers, so this candidate intentionally does **not** attempt to fake a lethal death animation or reproduce bullet hit-reactions. Native death state and lethal damage need further SDK/game research.
- This is not authoritative bullet attribution! `SHitInfo` is opaque in this SDK and the stand-in hit callback cannot reliably distinguish an impact from a nearby NPC versus the player shooting. Requiring a locally held firearm reduces false positives but does not eliminate them.
- Previous harmless notifications stay available when the local toggle is off. R2.9 performance optimizations, R2.8 Steam invitation/diagnostics, R2.4 movement/combat and body-hiding behavior are retained.

## How to test

1. Back up a working R2.9 installation before trying this experimental build. Install v0.12.9 on BOTH PCs.
2. Load the same mission together using an existing working network connection (Tailscale/direct-IP if Steam P2P is still unavailable).
3. On BOTH PCs open `~ → CO-OP → Settings → Playing together` and enable **Friendly fire**.
4. Equip a normal pistol, shoot the other player's visible stand-in **once**. Confirm the victim sees a friendly-fire message and approximately 12% health loss. Try a few more shots, but do not exceed a few at a time during the first test.
5. Turn off friendly fire on the **victim's** PC. Shooting should now show harmless-hit notification but should NOT lower victim HP. Also test when the shooter disables it.
6. Test with enemy guards firing near the partner, and with melee/takedowns. These are specifically **not** supported yet and can reveal false-positive damage.
7. Test NPC reactions, ordinary NPC fighting, movement, mission switching and all R2.9 performance improvements for regressions.

## Validation limits

Automated C++ unit tests cover strict hit-count parsing and safe HP bounds; a simulated session test verifies the reliable event reaches the partner. They **cannot** prove that directly modifying `ZHM5Health::m_fHitPoints` is fully respected by HITMAN's gameplay systems or that the hit hook attributes the damage correctly. Actual damage, regeneration, HUD behavior and save/reload stability require two-PC live testing.

If anything behaves unexpectedly, switch OFF Friendly fire immediately and revert to the R2.9 performance prerelease. Leave it off for real missions until tested. No changes were made to R2.9 regular/latest release settings or assets.
