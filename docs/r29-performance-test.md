# HITMAN Co-op by Artur — R2.9 Performance Test (v0.12.8 / protocol 16)

**Experimental optimization candidate; not verified in live two-player HITMAN gameplay.** The previous R2.8 Steam diagnostic prerelease stays available and the latest regular R2.3 remains unchanged. Both computers must run **the same R2.9 / v0.12.8**, HITMAN 3.290.1.x, ZHMModSDK 4.2.0.

Original HITMAN Co-op created by Jordan Rodrigues (GPL-3.0-or-later).

## Main-thread CPU work reductions

- **NPC enumeration:** Previously `Session::Tick` invalidated its NPC cache every render frame; `UpdateSharedNpcs` invoked `ReconcilePuppets` every frame. Since `ListNpcs` walks every activated actor in the mission, at 60 FPS this could do at least 60 full NPC enumerations per second. Now the NPC snapshot stays valid up to 1 / `npcScanRate` (30 Hz by default) and puppet reconciliation uses that same rate. Combat/ownership handling is still active and reacts within approximately one NPC scan (33 ms default). No NPC tracking IDs, gameplay protocols, interpolation, or decision rules were changed.
- **Item scan:** At every 0.1-second inventory check, `ForEachSceneItem` now runs **once** and supplies a temporary per-scan unique item-ID index to the pending-event lookup, peer-held visibility reassertion, and pickup/drop detection. Previously each pending/held item called `FindItem`, which made a full two-pass inventory scan per item. The temporary index is intentionally not cached between scans because HITMAN can create or destroy entities at any time. The existing duplicate-ID exclusion rule is unchanged.
- **Lazy repository ID:** No longer converts the repository identifier of every world item to a string on every inventory scan. Only serializes GUIDs for actual pickup/drop/motion events.
- **Alert messages:** Still checks for new/changed NPC alert states every 0.2 seconds, immediately transmitting changed states. Unchanged payloads are sent as heartbeat every approximately 0.4 seconds rather than every 0.2 seconds. The receiving SDK keeps alerts for 1 second, preserving headroom for ordinary packet loss. This is experimental and should be retested during combat.

## Simulated test results (not real-game FPS)

The automated 60 Hz two-player simulation using 120 NPCs ran for 3 seconds after connection:
- Host full NPC enumerations: **80** (prior design invalidated each render frame, approximately **180**).
- Client full NPC enumerations: **80** (prior design approximately **180**).
- This is approximately a **56% reduction in all-actor enumerations**, not a 56% FPS improvement. The complete game's CPU utilization, frame times and GPU performance have **not** been measured yet.
- An additional simulated test ensures unchanged alert messages are suppressed while changes and clearing of alert states still arrive promptly.
- All 89 existing and new core tests passed in the development build, including NPC fighting/ownership and connectivity tests.

## Live regression test checklist

1. Back up working mod installation and make sure both players install R2.9. The installer won't overwrite an active Assassin Rivals 2 mod and should only accept compatible HITMAN builds.
2. Play the **same mission, same location** in R2.8 and R2.9 with the same graphics settings. Record average FPS and 1% lows via a consistent overlay, with one user hosting and then roles swapped. Also watch NPC counts, location and effects.
3. Test walking/sprinting/facing, punches, knocks-outs, NPC ownership swaps, guard pursuit, and kill events. These were confirmed in R2.4 and must not regress.
4. Test world item pickups/drops and disguise/body hiding. Some were still **unresolved/unverified before this optimization**.
5. Test Steam friend invites. R2.8 P2P remains unverified; if it times out, check `%LOCALAPPDATA%\HitmanCoop\SteamP2P.log` and try Tailscale/IP.
6. If a mission gets unstable or newly broken, roll back to R2.8 and share private logs with the maintainer.

## Constraints

These optimizations reduce duplicate CPU work and some redundant network messages. They do not prove FPS improvement, fix the remaining item/disguise/body physics bugs, resolve Steam P2P availability or address room-password encryption. They also do **not** modify the actual HITMAN game files during compilation, tests or installer packaging.
