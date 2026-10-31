#pragma once

#include <algorithm>
#include <cmath>
#include <string_view>

namespace coop::friendly_fire {

// Decide whether a stand-in hit may become a player-damage event.
// IMPORTANT: do not depend on LocalHeldWeapon or held-weapon cosmetic detection.
// The old gate was unreliable and mislabeled enabled friendly fire as off.
inline bool ShouldSendDamage(bool p_FriendlyFireEnabled, bool p_BothInSameMission) {
    return p_FriendlyFireEnabled && p_BothInSameMission;
}

// Strictly bounded text in the existing reliable co-op MissionEvent. Never trust
// peer-provided health/damage values: only a hit count may cross the network.
inline int ParseHits(std::string_view p_Value) {
    if (p_Value.size() != 1 || p_Value[0] < '1' || p_Value[0] > '3')
        return 0;
    return p_Value[0] - '0';
}

// Prototype is intentionally non-lethal. Direct modification of ZHM5Health
// doesn't guarantee that HITMAN's normal death transition is executed.
// Always validate the actual HP range before touching TCheatProtect<float>.
inline float HealthAfterHit(float p_Current, float p_Max, int p_Hits) {
    if (!std::isfinite(p_Current) || !std::isfinite(p_Max) ||
        p_Max < 2.f || p_Max > 100000.f || p_Current <= 1.f ||
        p_Current > p_Max * 1.5f || p_Hits < 1 || p_Hits > 3)
        return p_Current;
    return std::clamp(p_Current - 0.12f * p_Max * p_Hits, 1.f, p_Current);
}

} // namespace coop::friendly_fire
