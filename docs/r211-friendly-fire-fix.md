# HITMAN Co-op by Artur — R2.11 Friendly Fire Toggle Fix

**Experimental follow-up to R2.10.** Both PCs must install R2.11 / v0.12.10 with HITMAN 3.290.1.x and ZHMModSDK 4.2.0. Protocol 16 remains unchanged; exact mod version still must match between clients.

## Evidence from both connected computers

- The ShadowV2 PC's mod log on 2026-10-31 showed **v0.12.9**, successful co-op entry, and repeated "You hit test's stand-in. Friendly fire is off." warnings.
- Laptop log showed **v0.12.9**, successful co-op entry, and both outbound and inbound harmless-hit notifications. The players reported both checkboxes were enabled.
- R2.10 source required `m_FriendlyFireSetting && m_World.LocalHeldWeapon()` before sending damage; the visual-only `LocalHeldWeapon()` helper is not a reliable detector for an equipped gun. When it returned false, R2.10 mislabeled the feature as disabled.

## Fix

- Removed `LocalHeldWeapon()` dependency. A stand-in hit is now eligible for bounded reliable damage whenever **the sender's Friendly fire checkbox is ON** and both players are synchronized in the same mission.
- Receiver still accepts events only while locally opted in and in a synced, playing mission; it validates the hit count (1–3) and player health, with a limit of 6 counted hits per second.
- The nonlethal prototype continues to deduct **12% of max HP per hit** and stops at **1 HP**. No native player kill, respawn, bullet reactions, or shooter attribution is implemented.
- The UI now displays **Friendly fire ON locally** beneath the checked option. "Friendly fire is off" appears only when **the sender's actual local setting** is disabled. An old harmless-hit event received while enabled is called out as a sender-side notice, not mislabeled as an off setting on the receiver.
- The plugin appends local diagnostics in the standard mod log for outgoing hit event count and incoming damage event processing, showing local setting ON/OFF and whether HP was reduced. It does not log room credentials.
- Automated regression test now asserts the decision is enabled when both the setting and scene synchronization are true, with no weapon-cosmetic state as an input.

## Important limitation and test steps

1. Install R2.11 on both PCs (do not mix with R2.10). Open the game through the normal Steam HITMAN installation.
2. Join the same mission via whatever connection already works. Open **CO-OP → Settings → Playing together** on BOTH PCs, check **Friendly fire**, and confirm **Friendly fire ON locally** appears under the checkbox.
3. Try **one pistol shot** at the partner's visible stand-in. Watch for a "Friendly fire" notice on the shooting client and a "hit you" notice on the receiving client. Check whether actual player HP drops.
4. If HP does not change, compare each PC's `Retail/mods/HitmanCoop.log` for `friendly-fire: queued` versus `friendly-fire: received` / `HP reduced` / `ignored`.
5. Turn friendly fire OFF on one computer: that machine should neither send damage when OFF nor accept damage when OFF.
6. Check for false positives when **NPCs** shoot near the stand-in; the current SDK hit hook does not reliably identify the shooter, so **an NPC hit on the stand-in can also transfer damage**. This is a known experimental limitation; disable the setting or revert to R2.9 if this occurs.

## Verification status

Windows plugin build, offline network/hit-count regression tests and installer payload integrity must pass before release. Live two-PC damage **has not been verified** for R2.11. Previous experimental R2.10 and performance-stable R2.9 releases are preserved.

Original HITMAN Co-op by Jordan Rodrigues; GPL-3.0-or-later.
