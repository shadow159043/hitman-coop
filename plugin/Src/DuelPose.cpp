#include "SdkWorld.h"
#include "PoseHook.h"
#include <algorithm>
#include <cmath>

// Overlay conservative, reversible punches and recoils on the existing
// networked skeleton. The original native NPC knock-out hooks are NOT invoked.
void SdkWorld::UpdateDuelPose() {
    if (!m_InScene || !m_PartnerActor || m_PartnerHidden || m_RigHidden ||
        m_PartnerRig != 1 || m_Mirror || !PartnerPosed() ||
        m_RemoteBones.size() < 4) {
        m_DuelPoseApplied = false;
        return;
    }
    if (!m_DuelMotion.Active()) {
        if (m_DuelPoseApplied)
            PoseHook::SetTargetPose(m_RemoteBones, false);
        m_DuelPoseApplied = false;
        return;
    }
    if (m_RemoteParents.size() != m_RemoteBones.size() ||
        m_RemoteParents[0] != -1 || m_RemoteParents[1] < 0 ||
        m_RemoteParents[2] < 0) {
        m_DuelPoseApplied = false; // Fail closed on unverified skeleton layout.
        return;
    }

    if (!m_DuelArmChecked && m_RemoteParents.size() == m_LocalBones.size()) {
        m_DuelArmChecked = true;
        const int n = static_cast<int>(std::min<size_t>(m_RemoteParents.size(), 160));
        float best = 0.f;
        // Look for two mirrored shoulder branches with two or more descendants.
        // If the skeleton differs from the known 47 layout, use torso only.
        for (int parent = 3; parent < n; ++parent) {
            int depth = 0, at = parent;
            for (; at > 0 && depth < 25; ++depth) {
                const int next = m_RemoteParents[at];
                if (next < 0 || next >= at) break;
                at = next;
            }
            if (depth < 4 || depth > 11) continue;
            for (int a = parent + 1; a < n; ++a) {
                if (m_RemoteParents[a] != parent) continue;
                const float x = m_LocalBones[a].pos[0];
                if (!std::isfinite(x) || x < .09f || x > .75f) continue;
                for (int b = parent + 1; b < n; ++b) {
                    if (m_RemoteParents[b] != parent) continue;
                    const float y = m_LocalBones[b].pos[0];
                    if (!std::isfinite(y) || y > -.09f || y < -.75f ||
                        std::abs(x+y) > .25f) continue;
                    const auto twoLinks = [&](int node) {
                        for (int child = node + 1; child < n; ++child) {
                            if (m_RemoteParents[child] != node) continue;
                            for (int grand = child + 1; grand < n; ++grand)
                                if (m_RemoteParents[grand] == child) return true;
                        }
                        return false;
                    };
                    if (twoLinks(a) && twoLinks(b) && x-y > best) {
                        best = x-y;
                        m_DuelArmLeft = a; m_DuelArmRight = b;
                    }
                }
            }
        }
        if (m_Trace) m_Trace("duel pose arms " + std::to_string(m_DuelArmLeft) +
            "/" + std::to_string(m_DuelArmRight) +
            (m_DuelArmLeft < 0 ? " (torso-only fallback)" : ""));
    }

    m_DuelPoseScratch = m_RemoteBones;
    auto& bones = m_DuelPoseScratch;
    const float jab = std::clamp(m_DuelMotion.jab, 0.f, 1.f);
    const float recoil = std::clamp(m_DuelMotion.recoil, 0.f, 1.f);
    const float down = std::clamp(m_DuelMotion.down, 0.f, 1.f);
    const float sway = std::clamp(m_DuelMotion.sway, 0.f, .2f);
    const float breathe = std::sin(static_cast<float>(m_Now) * 5.f) * sway;
    // Root and pelvis offsets are not moved sideways, avoiding teleporting a
    // standing actor or triggering ragdoll/AI state. Shallow reel only.
    coop::duel_motion::Twist(bones[1].rot, 0,
        .12f*breathe - .19f*jab + .40f*recoil + .50f*down);
    coop::duel_motion::Twist(bones[2].rot, 1,
        .08f*breathe + .24f*jab - .12f*recoil);
    coop::duel_motion::Twist(bones[2].rot, 0, .35f*down);
    if (down > .001f)
        bones[1].pos[2] -= .18f*down;

    if (m_DuelArmLeft >= 0 && m_DuelArmRight >= 0 &&
        static_cast<size_t>(std::max(m_DuelArmLeft, m_DuelArmRight)) < bones.size()) {
        coop::duel_motion::Twist(bones[m_DuelArmLeft].rot, 1, -.65f*jab);
        coop::duel_motion::Twist(bones[m_DuelArmRight].rot, 1, .45f*jab);
        coop::duel_motion::Twist(bones[m_DuelArmLeft].rot, 0, -.18f*down);
        coop::duel_motion::Twist(bones[m_DuelArmRight].rot, 0, .18f*down);
    }
    PoseHook::SetTargetPose(bones, false);
    m_DuelPoseApplied = true;
}
