# HITMAN Co-op by Artur — R2.12 Timed Fistfight Duel

**Experimental two-player quick-time-event duel prototype, not fully animated native HITMAN melee.**

## Gameplay

- Both players must be in the same synchronized mission, **within 2.75 metres** of one another. Either can open **~ → CO-OP → Play → Challenge to fistfight**.
- The invited player receives an in-game notification and chooses **Accept fistfight** or **Decline** in the CO-OP Play menu. An unanswered challenge times out automatically. There is an 8-second rematch cooldown.
- Once accepted, both players have about **3.5 seconds to close the CO-OP menu** using ~. A bold on-screen fistfight prompt appears, even when the ordinary CO-OP window is closed.
- Both receive the **same 12 deterministic direction prompts**, derived from one seed, at roughly **0.85 seconds per round**: UP, RIGHT, DOWN, LEFT arrow keys. One correct fresh keypress earns one point per round; holding a key or mashing the same key cannot earn multiple points. Incorrect/missed prompts earn nothing.
- The host collects both scores over the existing reliable gameplay event channel and determines the outcome. **Higher score wins; a tie results in a draw, with neither player stunned.**
- The loser receives a **three-second, nonlethal control stun** (blocked game digital and analog inputs); controls automatically return. Both screens show win/loss and scores. No HP damage, native death, mission failure or NPC kill state is involved.
- This is a **knockdown gameplay approximation**, not a full physical knockdown or NPC fistfight animation. Animating Agent 47's body as a native NPC-style ragdoll/knockout would require an independently verified engine-specific action hook; this build deliberately does not call unverified native functions.

## Technical details

- Uses existing, tested `Coop_DuelChallenge`, `Coop_DuelAccept`, `Coop_DuelDecline`, `Coop_DuelStart`, `Coop_DuelScore` and `Coop_DuelResult` event transport; no changes to the underlying protocol 16 format.
- The same RNG seed, fixed round durations and strict score validation are enforced by the small, isolated `core/include/coop/Duel.h` rule module. Client start times compensate approximately for half the observed network RTT.
- The host makes the final win/draw decision. Unknown IDs, invalid scores, duplicate acceptances and expired matches are ignored. Incomplete matches timeout with **no knockout**.
- The local Windows keyboard sampling follows the mod's existing virtual-key hotkey pattern. Arrow directions are deliberately used instead of WASD to avoid movement conflicts.
- R2.11 friendly fire remains available. Incidental stand-in collisions during a duel are not forwarded as firearm HP damage.
- Input hooks activate at runtime for temporary control stun. Outside the stun, when the test channel is disabled, they exit immediately without extra synchronization or state scans. The game itself has not yet been observed to play native melee animations or a physical ragdoll for a duel.

## First two-PC test

1. Keep a backup of R2.11. Install **R2.12 / mod v0.12.11 on BOTH machines**, with HITMAN 3.290.1.0 and ZHMModSDK 4.2.0. Use your existing working IP/Tailscale connection.
2. Start the same mission, stand within **2.75m** and put guns away for the fists-only challenge. Open ~ → CO-OP → Play → **Challenge to fistfight**.
3. Your partner opens Play → **Accept fistfight**. Close menus on both PCs quickly. Press the shown **UP / RIGHT / DOWN / LEFT** keys once each when they appear.
4. Confirm 12 equal prompts, meaningful scores and the same winner on both screens. Verify the loser is unable to move for ~3 seconds and that controls resume. **The character does not yet play a real knockout/falling animation.**
5. Repeat with opposite scores, a draw, declined invite, moved-apart invite, low score, tabbed-out game, game restart, or connection loss. No unintended HP loss, stuck input or NPC damage should occur.
6. Try mission scenarios with many NPCs to confirm the R2.9 optimizations and R2.11 friendly fire still work. If the game freezes, the controls do not recover, or there is any regression, roll back to R2.11 immediately.

## Verification caveats

Automated tests validate 12 equal prompts, score caps, invalid payload rejection, host winner/tie calculations and the underlying reliable two-way network messages; they do **not** simulate the real HITMAN engine, ImGui input focus, physical animation or two-PC latency under load. This prerelease must be live-tested before treating it as stable.

Game files are not changed by creating the installer or package. No changes to R2.11, R2.9 or older published releases. Original HITMAN Co-op by Jordan Rodrigues, GPL-3.0-or-later.
