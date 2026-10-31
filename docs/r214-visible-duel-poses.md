# HITMAN Co-op by Artur — R2.14 Visible Fistfight Animations Fix (v0.12.13)

**Experimental cosmetic-only animation adjustment.** Player has confirmed R2.13's letter-key reaction fight, HP damage and three-second stun all work, but no useful animations were visible. All existing gameplay mechanics are intentionally unchanged.

## Evidence from both PCs' real gameplay logs

In the ICA Facility, both R2.13 peers loaded the *matching 231-bone skeleton*, the pose hook installed correctly, and the duel completed 7 punches vs. 0 with a normal stun. Both logs contained:
`duel pose arms -1/-1 (torso-only fallback)`

This shows R2.13's shoulder detector failed. Its old detector required left/right arm offsets in the **X coordinate** of at least **0.09m**, which is too specific for the actual skeleton. Only a small rotation on root and pelvis remained, hard to see in normal player animation. The user's observation is supported by those diagnostics.

## R2.14 changes

- New pure C++ **DuelSkeleton.h** infers mirrored candidate upper-arm branches from the already-valid skeleton **in any X/Y/Z axis**, using upper-body hierarchy depth and branch lengths. It never writes game-owned skeleton memory.
- When the actual arms cannot be identified safely, R2.14 finds a likely **upper-torso** bone and applies a more pronounced **reel/jab** there, rather than barely moving the pelvis.
- Stronger but bounded and temporary upper-body bends, jabs and arm responses are blended into the existing **PoseHook::SetTargetPose** stream. Temporary poses are restored to the normal networked skeleton after the animation ends. R2.13's native-NPC melee protections remain unchanged.
- **Reapplies the cosmetic overlay after receiving a fresh remote pose**, preventing the ordinary 15–20 Hz pose sync from replacing the motion between rendered frames. This remains cosmetic, not native NPC combat.
- Adds `duel pose rig map: shoulders=X/Y torso=Z candidates=N`, `duel pose ACTIVE ...` and `duel pose blocked: ...` diagnostics to the standard `Retail\mods\HitmanCoop.log`, rate-limited. This will tell us whether the next problem is arm mapping, pose hook output or a visibility gate.
- No changes to the actual 12-round reaction time comparisons, per-round damage, match scoring, QTE letters, stun, network protocol, Steam invitation, NPC combat, or R2.9 performance optimizations.

## Testing

1. Keep R2.13 available. **Both players install R2.14 (mod v0.12.13), same game/SDK**, and join the same mission.
2. On **both** machines open **CO-OP → Settings → Playing together** and ensure **Duel animations (EXPERIMENTAL stand-in sparring poses)** is CHECKED. It is off by default for first-time installs.
3. Run one normal fistfight; the remote stand-in should visibly move the upper body on punches and recoil, and briefly bend upon losing. The local 47 does **not** play a native NPC punching animation or physically fall; these are remote stand-in procedural poses only.
4. Check the text in `HITMAN 3\Retail\mods\HitmanCoop.log` on both devices, particularly `duel pose rig map`, `duel pose ACTIVE`, and `duel pose blocked`. If there is still no visible motion, these lines will narrow down the specific problem.
5. If any clothing/outfit twists or animates incorrectly, **immediately turn off Duel animations**. The fight mechanics will continue normally. Otherwise send a brief video/observation of the motion to judge its fidelity.
6. Confirm R2.13 punch HP changes and stun are unaffected; if necessary, roll back to R2.13.

## Verification & caveats

R2.14 must pass full verified ZHMModSDK v4.2.0 compilation, automated core regressions including new skeleton tests, Steam probe and installer/ZIP checksum/integrity checks before publication. **Automated passing results do not prove the new animations are visible in HITMAN; another live two-PC test is required.**

This is not HITMAN's engine-native NPC fighting animation. It does not enable a vulnerable stand-in's takedown, ragdoll, pacification or AI control, which could break your multiplayer mission.

Original HITMAN Co-op by Jordan Rodrigues (GPL-3.0-or-later). The user's stable R2.13, R2.12 and older releases must remain untouched.
