#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>

namespace coop::duel_motion {
struct Cue {
    float jab = 0.f;
    float recoil = 0.f;
    float sway = 0.f;
    float down = 0.f;
    bool Active() const { return jab > .0001f || recoil > .0001f || sway > .0001f || down > .0001f; }
};

inline float Pulse(double now, double at, double length = .44) {
    if (!std::isfinite(now) || !std::isfinite(at) || now < at || now >= at + length)
        return 0.f;
    return static_cast<float>(std::sin(3.141592653589793 * (now - at) / length));
}
inline Cue Sample(double now, double opponentJabAt, double opponentRecoilAt,
                  double resultAt, bool opponentDown, bool inFight) {
    Cue out;
    if (!std::isfinite(now) || !std::isfinite(resultAt)) return out;
    if (inFight) {
        out.jab = Pulse(now, opponentJabAt);
        out.recoil = Pulse(now, opponentRecoilAt, .55);
        out.sway = .15f;
    }
    if (opponentDown) {
        const double t = now - resultAt;
        if (t >= 0.0 && t < 3.2)
            out.down = static_cast<float>(std::min(std::clamp(t / .4, 0.0, 1.0),
                std::clamp((3.2 - t) / .5, 0.0, 1.0)));
    }
    return out;
}
inline float HealthAfterPunch(float current, float maxHp, int punches = 1) {
    if (!std::isfinite(current) || !std::isfinite(maxHp) || maxHp < 2.f ||
        maxHp > 100000.f || current <= 1.f || current > maxHp * 1.5f ||
        punches < 1 || punches > 12)
        return current;
    return std::clamp(current - maxHp * .045f * punches, 1.f, current);
}
inline void Twist(float (&q)[4], int axis, float radians) {
    if (axis < 0 || axis > 2 || !std::isfinite(radians) || std::abs(radians) > 1.2f) return;
    const float s = std::sin(radians * .5f), c = std::cos(radians * .5f);
    float b[4] = {0,0,0,c};
    b[axis] = s;
    const float a[4] = {q[0],q[1],q[2],q[3]};
    q[0] = a[3]*b[0]+a[0]*b[3]+a[1]*b[2]-a[2]*b[1];
    q[1] = a[3]*b[1]-a[0]*b[2]+a[1]*b[3]+a[2]*b[0];
    q[2] = a[3]*b[2]+a[0]*b[1]+a[1]*b[0]+a[2]*b[3];
    q[3] = a[3]*b[3]-a[0]*b[0]-a[1]*b[1]-a[2]*b[2];
    const float n = std::sqrt(q[0]*q[0]+q[1]*q[1]+q[2]*q[2]+q[3]*q[3]);
    if (n > .5f && std::isfinite(n)) for (float& v : q) v /= n;
}
} // namespace coop::duel_motion
