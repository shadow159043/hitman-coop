# Artur Gameplay Sync Test — R2.4 / v0.12.3 / protocol 14

**Status: EXPERIMENTAL.** This branch is not the previous working R2.3 and has not been validated in live HITMAN gameplay on two PCs. Builds target HITMAN World of Assassination 3.290.1.x with ZHMModSDK 4.2.0. Both players must install R2.4 TEST together. Preserve R2.3 as the rollback.

Original HITMAN Co-op by Jordan Rodrigues, GNU GPL-3.0-or-later. Artur edition adds experimental compatibility fixes.

## Implemented in this candidate

- **Remote partner facing:** In the AI-patrol fallback (no skeletal pose), correct the rendered actor's rotation when it is within 1.5 m of the partner's position, differs by more than 0.45 radians and is moving. Correction affects rotation only, interpolates by 65%, and is throttled to 0.2 seconds. The primary skeleton-pose mode is unchanged.
- **Nearby NPC combat:** A locally alert NPC within 4 m of 47 is temporarily released from remote puppet control, so melee reactions can run in the player's own game. Puppet/transform/pose mirroring resumes after its locally observed tension drops. Knockout/death replication remains as before. This favors responsive local fighting but can temporarily let AI diverge.
- **Item pickup resilience:** Remember up to 256 incoming item events whose scene objects have not spawned locally; retry each scan and clear state on mission/session reset. Existing unique-ID pickup hide/disable/restore code is unchanged. Multiple instances of the same template ID remain intentionally excluded because the code cannot identify them reliably on both PCs. Truly simultaneous pickups may still race.
- **Body drag/drop:** A partner's **moved** corpse now attempts to appear at its latest resting transform rather than being hidden. A body actually hidden in a closet/container stays hidden. Temporarily suppress outgoing body motion echoes for four seconds. **Major limitation:** HITMAN's ragdoll physics can override that placement; this may cause drift or duplicate visuals and needs live testing.
- **Disguise availability:** Outfit packets now optionally identify the specific nearby downed NPC that supplied a newly changed outfit. Detection requires exactly one downed actor of the matching outfit within 2.5 m, avoiding incorrect locks when identical uniforms are nearby. The remote NPC's SDK `m_bBlockDisguisePickup` field/property is set and restored when the session ends. This is only a best-effort source match; dropped disguises, multiple matching bodies, outfits already worn when reconnecting, and simultaneous outfit pickups remain unsolved. Needs confirmation that the runtime respects the per-actor flag.

## Automated validation

- Windows C++/SDK v4.2.0 plugin compilation: success.
- 85 automated core/session tests: passed (0 failures), including local melee release and outfit-source message serialization/relay.
- Previous R2 two-PC Freeform Training success does **not** validate R2.4.

## Recommended live tests (both PCs on R2.4 TEST)

1. Back up each game's `Retail` folder/mods.ini and keep the separate R2.3 installer/release.
2. Confirm both menus show **v0.12.3** and both use SDK 4.2.0, then connect via Tailscale/IP using your room code and optional password.
3. **Facing:** walk, sprint, strafe, and rotate in place. Watch whether the partner faces the correct direction without sliding or stuttering.
4. **Combat:** test punches, sustained melee, and NPC knockout with client as attacker, then reverse roles. Check whether guards freeze, duplicate, damage twice, or remain stuck after combat.
5. **Pickups:** pick up an ordinary mission-placed item and inspect the other PC before trying to take it. Drop it and confirm reappearance. Try repeated template objects separately, report if one cannot sync.
6. **Disguise:** knock out a guard alone, take the outfit, and check whether that NPC on the other PC offers the disguise. Repeat with multiple identical-outfit bodies close together (expected not to force a lock).
7. **Dragging:** knock out one guard, drag around a corner, let go, and compare the body's visible location on both PCs after one and five seconds. Also test putting it in a container.
8. If any crash, model corruption, or body/object disappearance occurs, uninstall R2.4 TEST and return to the known R2.3 build. Preserve logs for diagnosis (private only).

## Release policy

This is a **separate opt-in prerelease**, not a replacement for the R2.3 latest release. No live-game files were modified by the build/package/tests on the development PC. Do not describe the five features as production-verified without successful paired in-game validation.
