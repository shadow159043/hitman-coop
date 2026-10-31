# Artur R2.5 Gameplay Reliability TEST (0.12.4 / protocol 15)

**Experimental only.** Based on the R2.4 test build. The user confirmed that facing/walking/sprinting and NPC fighting are working and that bodies disappear correctly when placed in hiding spots. This release deliberately preserves those behaviors. The R2.4 test showed that items still remained visible, duplicate disguises could be taken and body dragging did not render on the other PC. The improvements below have NOT been verified in HITMAN gameplay.

## Changes for testing

- **Items:** Peer pickup now applies the item's visible state (`m_rItemVisible`) as well as its geom visibility and pickup-enabled property. Reapplies hidden/pickup-disabled state each 0.1-second item scan to resist game scripts re-enabling the item. Original unique-entity-ID matching remains. Identical template instances and simultaneous pickup races may still fail. Test by collecting a unique named world item first, then try common repeated items and note differences.
- **Disguises:** Try both an NPC's outfit kit ID and its stored outfit repository ID; recognize dead/pacified bodies. If the matching source NPC cannot be found immediately, keep trying for 2.5 seconds and send a source-body update without rebuilding the peer's avatar outfit again. Still requires one unambiguous nearby downed matching NPC. The recipient sets `m_bBlockDisguisePickup` and restores its original value on disconnect. This engine field is not live-verified.
- **Drag:** Victim messages now explicitly mark the dragged state (protocol 15) and allow an empty animation-bone list. The sender can stream body transforms while dragging even if animation capture failed. The receiver starts following before the previous 0.75 m movement threshold when the dragged bit is present, and can apply the root transform without requiring compatible pose bones. Physics may override the transform or cause visible artifacts.
- **Unchanged:** R2.4's remote player facing correction; local AI during nearby NPC melee; distinct body-moved vs container-hidden handling. Do not regress these.
- **Security and compatibility:** Room passwords continue to be sent unencrypted in the game protocol. Both PCs need **v0.12.4 / protocol 15**, HITMAN 3.290.1.x and ZHMModSDK 4.2.0.

## Suggested checks

1. Back up both game folders and keep the working R2.4 test installer. Neither the build nor packaging process installs the mod.
2. Confirm `v0.12.4` appears in the CO-OP menu on both PCs before joining.
3. Pick up a unique weapon or tool from the floor; check if it becomes invisible and unpickable for the other user, then drop it and check its reappearance. Repeat with multiple identical tools.
4. Knock out one guard with a unique outfit, take the outfit, then see whether the guard's remaining disguise is blocked on the partner. Test both host and guest as first picker.
5. Drag a knocked-out guard at least 3 m while the other player watches; check position and animations during drag and after release. Test placing the body in a closet again.
6. Retest two NPC fistfights and walking/turning to detect regressions. If any crash, duplicate model, disappearing body outside a hiding place, or game freeze occurs, roll back and preserve logs privately.

## Verification state

Core C++/SDK build and automated tests are required before publishing any prerelease. Real two-PC behavior for the three outstanding features remains **unverified**. No guarantee of complete item/disguise/body-drag synchronization.

Original HITMAN Co-op author: Jordan Rodrigues. Artur experimental compatibility edition, GPL-3.0-or-later.
