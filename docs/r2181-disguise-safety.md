# R2.18.1 — NPC disguise visual safety review

Version: **0.12.21**, protocol **16**, HITMAN 3.290.1.0, ZHMModSDK **4.2.1**.
Base: R2.18 (0.12.20) with working R2.17.2 item visibility unchanged.

## Safety issues corrected before player testing

- **Double outfit rebuild:** a delayed reliable `Coop_BodyOutfit` event could arrive after the source-ID fallback. Skip a matching nude/outfit/charset/variation event; a different outfit is still applied.
- **Competing delayed events:** process authoritative pending body-outfit events before the heuristic source-ID visual fallback.
- **Partially initialized body tracking:** neither outfit path creates a `Body` entry ahead of the normal scanner's initial position/dragging baseline.
- **Dropped outfit during takedowns:** defer received outfit events while the NPC is the local or remote current victim, instead of discarding them or rebuilding an actively streamed skeleton.
- **Late NPC and lost pickup lock:** a visual attempt expires after 12 seconds but keeps the source ID pending until the NPC's pickup lock is installed, even if an outfit event already applied.
- **Invalid outfit variation:** validate kit, charset, actor-type collection and actual variation before calling the native outfit setter. This prevents requesting an invalid variation from a received packet.
- **Stale pending outfit:** latest authoritative pending event wins without continually extending its deadline.

Only NPC clothing code, its pure decision helper, regression tests and build labels changed. Networking, Steam invitations, item visibility, surrender, fighting, body movement and the protocol layout remain untouched.

## Regression tests
New tests:
- `DisguiseVisuals_KeepLateNpcPickupLockAfterVisualDeadline`
- `DisguiseVisuals_StrippingRequiresDownedUnoccupiedBodyBeforeDeadline`
- `DisguiseVisuals_NativeEventCanSkipDuplicateButNotDifferentOutfit`

## In-game test checklist

1. Close HITMAN completely on both computers, then install the same R2.18.1 (v0.12.21).
2. Join a mission using Steam invitations.
3. PC player knocks out a guard and steals their disguise. Confirm the laptop renders the guard in the stripped appearance and cannot steal the same outfit.
4. Reverse roles, with the laptop taking an NPC's disguise and main PC observing.
5. Attempt taking the disguise immediately after a takedown and after the body has settled.
6. Test a normal suit switch with no NPC source; no random guard should be changed.
7. Check `Retail\mods\HitmanCoop.log` on both devices for `disguise: body ... used by partner`, `disguise: native visual strip applied ...`, and any visual-expiry messages.

**Not yet confirmed:** the engine's real NPC renderer and ragdoll transitions in a two-PC HITMAN session. A passing compiler/test suite cannot guarantee these visuals. Revert to preserved R2.17.2 if there is a crash or the clothing model breaks.

Original mod author: Jordan Rodrigues, GPL-3.0-or-later.
