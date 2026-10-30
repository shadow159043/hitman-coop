#pragma once

#include <cmath>

namespace coop {

// Player position comes from the network, independently of the game's NPC stand-in.
// An absent or stale network position must never leave a ghost radar/name marker.
inline bool RemotePositionCurrent(bool p_HasPosition, double p_Now, double p_ReceivedAt, double p_MaxAge = 2.0) {
    return p_HasPosition && std::isfinite(p_Now) && std::isfinite(p_ReceivedAt) &&
        p_ReceivedAt > 0.0 && p_Now >= p_ReceivedAt && p_Now - p_ReceivedAt <= p_MaxAge;
}

// An unavailable camera must not be mistaken for a cutscene at world origin.
inline bool ShouldHideOverlay(bool p_InMission, bool p_MenuOpen, bool p_HasCamera, float p_CameraDistance) {
    return p_InMission && (p_MenuOpen || (p_HasCamera && std::isfinite(p_CameraDistance) && p_CameraDistance > 10.f));
}

} // namespace coop
