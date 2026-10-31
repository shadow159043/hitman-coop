#pragma once
#include <cmath>
namespace coop::body_sync {
// Report only user-handled body changes after the drag has actually ended.
// Unlike old 1.5m-at-rest-only rule, supports short and early drags. Never
// broadcast ordinary ragdoll physics as player movement.
inline bool ShouldSendMoved(bool wasHandled, bool released, bool stationary,
                            float distanceFromLastAgreed, double elapsedSinceRelease) {
    return wasHandled && released && stationary &&
        std::isfinite(distanceFromLastAgreed) &&
        distanceFromLastAgreed > 0.4f && elapsedSinceRelease >= 0.35;
}
}
