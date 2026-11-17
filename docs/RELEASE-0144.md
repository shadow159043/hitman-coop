# Artur Edition 0.14.4 — Two-Player Mission Lobby (Development Build)

**Not published as the latest release.** This is a development candidate for testing before exposure to users.

## Features

- Two-player host-authoritative lobby with network protocol 22.
- Mission choices based on actually observed, complete HITMAN scene and brick identifiers. The catalog currently holds two recently observed distinct scenes, NOT all DLC destinations.
- Host/guest votes, tie-break by host, ready and unready, shared status. Changes to selection clear readiness.
- Unique launch IDs, reliable launch acknowledgement and scene-ready notifications. The host checks the guest's real scene status, not the guest's claim alone.
- Both games must load the same mission scene and synchronize before the lobby reports playing. Timeouts, cancellations and connection drops have safe failure/recovery states.
- In-game black/red Lobby tab with mission list, vote visibility, both players' ready statuses, selected scene, connection info and real loading states.
- Existing game-loop named pause request used to hold gameplay while waiting, if the appropriate hook is available. This is not a guarantee that gameplay won't advance before a first frame pause.
- Automatic mission selection through ZHMModSDK **not confirmed safe**. Players use HITMAN's normal mission navigation. Never try arbitrary scene pointers or raw game memory patches.
- No verified entitlement/DLC ownership API yet. Prior mission observation is treated as a prerequisite but not license verification.
- No thumbnail resource API verified; show verified scene labels instead of invented mission art.

## Testing still needed before release

Two genuine HITMAN clients: two-vote and tie scenarios, mismatched DLC, ready/unready, launch cancellation, scene loading, slow partner, disconnect/reconnect while loading, repeated mission restarts and return to lobby. Monitor NPCs, scene transitions, objective completion, and game script state. No physical two-client tests claimed.

## Compatibility

Both players must run the exact same development build (**network protocol 22**); existing published 0.14.3 uses protocol 21. Steam Deck/Proton uses the separately built AppImage and requires physical testing. No default single-player mission navigation is changed.
