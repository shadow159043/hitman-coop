#pragma once

// Receiver-side disguise visual decisions. Pure helpers keep the late-spawn,
// duplicate-event and visual-expiry rules testable without native HITMAN code.
namespace coop::disguise_visuals {
constexpr bool NeedsRetry(bool pickupLocked, bool stripApplied) {
    return !pickupLocked || !stripApplied;
}
constexpr bool PendingCanExpire(bool pickupLocked, double now, double deadline) {
    // The visual deadline must NEVER discard an uninstalled gameplay lock.
    return pickupLocked && now >= deadline;
}
constexpr bool CanStrip(bool alreadyApplied, bool actorDown, bool isLocalVictim,
                        double now, double deadline) {
    return !alreadyApplied && actorDown && !isLocalVictim && now < deadline;
}
constexpr bool DuplicateNativeStrip(bool alreadyApplied, bool eventNude,
                                    bool sameKit, bool sameCharset, bool sameVariation) {
    return alreadyApplied && eventNude && sameKit && sameCharset && sameVariation;
}
}
