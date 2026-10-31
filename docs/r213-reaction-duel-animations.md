# HITMAN Co-op by Artur — R2.13 Reaction-Punch Duel + Optional Animated Stand-In

**Experimental optional prerelease**; v0.12.12 (protocol 16). R2.12 is known to work in the player's two-PC test. R2.13 was built/tested offline but **not verified in two live games**.

## Gameplay
1. Both PCs install R2.13/v0.12.12 and join the **same mission** using the already-working connection. Stand within 2.75 metres, open **~ → CO-OP → Play → Challenge to fistfight**, and have your partner **Accept**.
2. When both close the menu, a 3.5-second countdown begins. Twelve ~0.85-second prompts display one letter: **E, F, Q, or R**. Both players receive the **same letter** in the same round. Press it once as quickly as possible.
3. Each computer measures the time from its **own displayed prompt** to its first correct press. The host adjudicates the shorter reaction time, **not which network message arrived first**. Times within 35ms count as a draw, neither is punched. Missing/wrong presses earn no punch; if just one presses correctly, that player punches.
4. The host sends **one authoritative round result** to both games. The round winner lands one punch. The loser loses approximately **4.5% of their maximum player health** on *their own machine*, never to less than **1 HP**. Each result can be applied only once; tampered scores/IDs/times are rejected. The current game engine may regenerate health.
5. The most punches landed after 12 rounds wins the match; the loser is temporarily **stunned for three seconds**, with controls then automatically restored. A tie has no end stun. No game death, permanent NPC pacification, or mission score kill is generated.
6. During the QTE, normal game inputs are temporarily suppressed, so pressing interaction keys does not trigger unwanted in-game interactions. The QTE itself reads actual keyboard state. Gameplay resumes on result or when the session disconnects.

## Experimental animations
- **OFF by default for safety.** On both computers open **CO-OP → Settings → Playing together → Duel animations (EXPERIMENTAL stand-in sparring poses)**.
- Uses the existing working ZHMModSDK / Morpheme **PoseHook** synchronization and matched partner skeleton. When the *remote* player wins a round, their stand-in's upper body makes a **procedural jab** on the receiving PC. When the local player wins, the remote stand-in visibly **recoils**. If your friend loses the overall fight, their stand-in performs a short **crouched/reeling pose** for about three seconds.
- Mirrored arm branches are detected conservatively from the existing skeleton parent information (fallback to torso-only). All rotations/offsets are bounded. The mod never enables stand-in native close-combat takedowns, alters NPC AI ownership, runs an unsafe direct native animation pointer, or pacifies the stand-in. The local Agent 47 receives a control stun, **not a physical ragdoll**.
- This is **not** fully native NPC punch or synchronized cinematic choreography. A genuine native knockout/fall animation still requires a verified reversible engine action and further research. If shoulders deform or an outfit behaves strangely, **turn the Duel animations option OFF immediately**; the fight/scoring continues.

## Fairness and connection limitations
- Reaction times are relative to when the prompt appears locally. Host compensates approximately for RTT/2 when scheduling the start. Comparing local reaction times avoids penalizing a player only because a packet takes longer to arrive.
- Up to approximately 35ms simultaneous presses are ties; the host allows an additional ~0.55–0.95s for remote reaction packets. Very high jitter can still cause a missed/late round and client-supplied timestamps are not cryptographically attestable. This is for friends, not cheat-proof competitive tournaments.
- Reliable gameplay events: `Coop_DuelPress` (round+reaction ms), `Coop_DuelRound` (round+winner), `Coop_DuelResult` (host score+client score). No wire protocol changes and no sending raw game pointers or HP amounts.
- Turning **Friendly fire OFF** does not disable consented fistfight punches. Friendly fire's separate 12%-damage mechanic remains opt-in outside duels.

## Required two-PC regression tests
1. Back up R2.12 and run the **same R2.13 version on both**. Confirm challenge accept/decline and same letters.
2. One player presses early every round, other late; winner must be the faster **correct** presser on both machines. Try reverse host/client roles, 30–40ms near-ties, no inputs, incorrect inputs, and intermittent network lag.
3. Check the HP bar decreases **only for the losing player per round**, never reaches zero, and no NPC kill or mission failure occurs.
4. Enable animations on both sides and watch both 47 stand-ins for **jabs, recoil, and short end-of-fight crouch**. Re-test outfit changes and large/small NPC skeleton variations; disable immediately if a model deforms.
5. Confirm normal movement/interaction controls return after a fight, disconnect, restart, or timeout. Check R2.9 performance and R2.11 friendly fire still function.
6. If any issues arise, revert to the existing R2.12 prerelease and share **Retail/mods/HitmanCoop.log** excerpts.

Original HITMAN Co-op created by Jordan Rodrigues, GPL-3.0-or-later. No game files were changed by compiling or packaging this release.
