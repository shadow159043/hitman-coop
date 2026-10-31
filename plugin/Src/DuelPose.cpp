#include "SdkWorld.h"
#include "PoseHook.h"
#include "coop/DuelSkeleton.h"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

// A reversible visual override on the already synchronized partner stand-in.
// No native close-combat enabling, AI state, physics, or actual NPC pacification.
void SdkWorld::UpdateDuelPose() {
    if (!m_DuelMotion.Active()) {
        if (m_DuelPoseApplied && m_PartnerActor)
            PoseHook::SetTargetPose(m_RemoteBones, false);
        m_DuelPoseApplied = false;
        return;
    }
    const bool available = m_InScene && m_PartnerActor && !m_PartnerHidden &&
        !m_RigHidden && m_PartnerRig == 1 && !m_Mirror && PartnerPosed() &&
        m_RemoteBones.size() >= 12;
    const bool hierarchy = available &&
        m_RemoteParents.size() == m_RemoteBones.size() &&
        m_RemoteParents[0] == -1 &&
        m_RemoteParents[1] >= 0 && m_RemoteParents[2] >= 0;
    if (!hierarchy) {
        if (m_Trace && m_Now - m_DuelPoseDiagAt > 4.0) {
            m_DuelPoseDiagAt = m_Now;
            m_Trace("duel pose blocked: available=" + std::to_string(available) +
                " rig=" + std::to_string(m_PartnerRig) +
                " hidden=" + std::to_string(m_PartnerHidden || m_RigHidden) +
                " netBones=" + std::to_string(m_RemoteBones.size()) +
                " hierarchy=" + std::to_string(m_RemoteParents.size()));
        }
        if (m_DuelPoseApplied) {
            if (m_PartnerActor && m_PartnerRig == 1 && m_RemoteBones.size() >= 2)
                PoseHook::SetTargetPose(m_RemoteBones, false);
            else PoseHook::ClearTargetPose();
        }
        m_DuelPoseApplied = false;
        return;
    }

    // R2.13 incorrectly searched mirrored shoulders ONLY along X and >=.09m.
    // Both tested rigs matched 231 bones but yielded -1/-1, reducing the
    // animation to almost imperceptible pelvis movements. Inspect any axis,
    // validate upper torso branches and keep a useful torso fallback.
    if (!m_DuelArmChecked && m_LocalBones.size() == m_RemoteBones.size()) {
        std::vector<coop::duel_skeleton::Offset> offsets;
        offsets.reserve(m_LocalBones.size());
        for (const auto& b : m_LocalBones)
            offsets.push_back({b.pos[0], b.pos[1], b.pos[2]});
        const auto match = coop::duel_skeleton::Detect(m_RemoteParents, offsets);
        m_DuelArmLeft = match.shoulderA;
        m_DuelArmRight = match.shoulderB;
        m_DuelUpperTorso = match.upperTorso;
        m_DuelArmChecked = true;
        if (m_Trace) m_Trace("duel pose rig map: shoulders=" +
            std::to_string(m_DuelArmLeft) + "/" +
            std::to_string(m_DuelArmRight) + " torso=" +
            std::to_string(m_DuelUpperTorso) + " candidates=" +
            std::to_string(match.candidatePairs));
    }

    m_DuelPoseScratch = m_RemoteBones;
    auto& bones = m_DuelPoseScratch;
    const float jab = std::clamp(m_DuelMotion.jab, 0.f, 1.f);
    const float recoil = std::clamp(m_DuelMotion.recoil, 0.f, 1.f);
    const float down = std::clamp(m_DuelMotion.down, 0.f, 1.f);
    const float sway = std::clamp(m_DuelMotion.sway, 0.f, .2f);
    const float breathe = std::sin(static_cast<float>(m_Now)*5.f)*sway;

    // Primary movement: twist an actual torso node, not only pelvis/root,
    // which the native locomotion animation can visually cancel.
    const int upper = m_DuelUpperTorso >= 3 &&
        static_cast<size_t>(m_DuelUpperTorso) < bones.size() ?
        m_DuelUpperTorso : 3;
    coop::duel_motion::Twist(bones[1].rot, 0,
        .10f*breathe - .11f*jab + .19f*recoil + .30f*down);
    coop::duel_motion::Twist(bones[upper].rot, 0,
        -.55f*jab + .63f*recoil + .78f*down + .17f*breathe);
    coop::duel_motion::Twist(bones[upper].rot, 1,
        .38f*jab - .23f*recoil + .09f*breathe);
    if (down > .001f)
        bones[1].pos[2] -= .28f*down;

    // Shoulders are optional: never guess via hard-coded unvalidated bone
    // numbers or cause a model to deform when the outfit skeleton differs.
    if (m_DuelArmLeft >= 0 && m_DuelArmRight >= 0 &&
        static_cast<size_t>(std::max(m_DuelArmLeft,m_DuelArmRight)) < bones.size()) {
        coop::duel_motion::Twist(bones[m_DuelArmLeft].rot, 1, -.98f*jab);
        coop::duel_motion::Twist(bones[m_DuelArmRight].rot, 1, .56f*jab);
        coop::duel_motion::Twist(bones[m_DuelArmLeft].rot, 0, -.23f*down);
        coop::duel_motion::Twist(bones[m_DuelArmRight].rot, 0, .23f*down);
    }

    PoseHook::SetTargetPose(bones, false);
    if (m_Trace && m_Now - m_DuelPoseDiagAt > 4.0) {
        m_DuelPoseDiagAt = m_Now;
        m_Trace("duel pose ACTIVE shoulders " +
            std::to_string(m_DuelArmLeft) + "/" +
            std::to_string(m_DuelArmRight) + " torso=" +
            std::to_string(upper) + " jab=" + std::to_string(jab) +
            " recoil=" + std::to_string(recoil) +
            " down=" + std::to_string(down));
    }
    m_DuelPoseApplied = true;
}
