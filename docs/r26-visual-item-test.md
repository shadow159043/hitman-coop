# Artur R2.6 Visual Item TEST — v0.12.5 / protocol 16

**This is an opt-in experimental build and has NOT been gameplay-verified.** The R2.3 regular release and R2.4/R2.5 test versions remain independently available. Preserve working builds before installing.

Original HITMAN Co-op created by Jordan Rodrigues; GPL-3.0-or-later. Artur is credited for this compatibility edition, not as the original creator.

## Changes

- **In-game UI:** Each input now shows an explicit label and a hint: host IP/Tailscale/relay code, room code and optional password. Paste address/invite accepts the full text copied from the host's Copy full invite button and fills the right fields. The Join button is disabled until an address and room code are entered.
- **Held items:** The source-player held-item scan examines ALL owned world-inventory entries instead of ignoring repeated template IDs. The player status now includes whether the displayed item is a firearm. The receiver uses that flag when requesting a matching visual replica for the partner's hands.
- **Back-mounted large equipment:** In addition to the held item, the source checks for a visible, locally owned, size-LARGE item near 47 that isn't the currently detected held item. The receiver requests a second visual replica and tries eALRifle/eALBack attachments on the stand-in, independent of the weapon in the hands. The SDK may expose different items/outfits differently; false positives or missing items are still possible.
- **Dropped items:** Item events now include the repository identifier. For a matching map entity, the existing item is shown and moved as usual. If the receiver has no corresponding world ID, it requests a **visual-only non-pickable local copy** at the sender's drop transform. Subsequent updates move that copy; a pickup event destroys it. This fallback does NOT create a shared interactable item; no shared-ownership or simultaneous-pickup guarantee is claimed. R2.5 item visibility checks are retained.
- **Everything retained:** R2.5 drag/disguise improvements, R2.4 nearby NPC combat and partner-facing improvements, existing body-hidden-in-container behavior, Steam/Epic auto-detection, Artur branding, and room code/password connection checks.

## How to test

Install R2.6 TEST on **both PCs** after backing up the working release, using HITMAN 3.290.1.x and ZHMModSDK 4.2.0. Confirm BOTH in-game Co-op menus say **v0.12.5**. Different protocol versions cannot connect.

1. Host a room, Copy full invite, paste into the joiner's IP/address box with **Paste address / invite**, confirm the room code and password autofill. Never reuse an account password; the game's room-password handshake is unencrypted.
2. Equip a pistol, then a non-gun tool; confirm the other player sees the correct model in the right hand. Switch and holster.
3. Equip a large rifle/shotgun, then put it on your back while holding a pistol. Check whether the remote model shows the correct rifle mounted and the correct pistol in the hand. Look for models floating, appearing in the wrong place, or duplicating.
4. Drop a unique map-placed item and confirm the remote version becomes visible at the correct location. Try a weapon introduced via loadout/inventory; a cosmetic non-pickable copy should be attempted when no matching map entity exists. Check object cleanup after picking it up again.
5. Reverse host/guest roles. Retest fighting NPCs, walking/turning, and hiding bodies in containers to check for regressions.
6. Record private logs and screenshots of failures. If the game crashes or duplicates items persistently, roll back rather than saving the mission.

## Validation limits

The automated C++ test suite validates network serialization and state relay, **not** actual attachment placement or item-spawned game engine behavior. The back and cosmetic item workflows are SDK-native but unverified; gameplay may behave differently. R2.3 remains the regular latest release until paired testing confirms this build.
