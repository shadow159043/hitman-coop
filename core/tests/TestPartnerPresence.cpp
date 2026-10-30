#include <limits>

#include "TestFramework.h"
#include "coop/PartnerPresence.h"

TEST(PartnerPresence_ReceivesMarkerWithoutSpawnedActor) {
    CHECK(coop::RemotePositionCurrent(true, 103.0, 102.0));
    CHECK(coop::RemotePositionCurrent(true, 104.0, 102.0));
    CHECK(!coop::RemotePositionCurrent(false, 103.0, 102.0));
    CHECK(!coop::RemotePositionCurrent(true, 104.01, 102.0));
}

TEST(PartnerPresence_CameraAbsenceIsNotACutscene) {
    CHECK(!coop::ShouldHideOverlay(true, false, false, 1000.f));
    CHECK(!coop::ShouldHideOverlay(true, false, true, 5.f));
    CHECK(coop::ShouldHideOverlay(true, false, true, 11.f));
    CHECK(coop::ShouldHideOverlay(true, true, false, 0.f));
    CHECK(!coop::ShouldHideOverlay(false, true, true, 1000.f));
}

TEST(PartnerPresence_RejectsStaleAndInvalidPositionTimes) {
    CHECK(!coop::RemotePositionCurrent(true, 200.0, 0.0));
    CHECK(!coop::RemotePositionCurrent(true, 50.0, 51.0));
    CHECK(!coop::RemotePositionCurrent(true, 200.0, 100.0));
    CHECK(!coop::RemotePositionCurrent(true, std::numeric_limits<double>::quiet_NaN(), 199.0));
    CHECK(!coop::RemotePositionCurrent(true, 200.0, std::numeric_limits<double>::infinity()));
}
