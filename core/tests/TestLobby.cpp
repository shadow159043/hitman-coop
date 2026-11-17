#include "TestFramework.h"
#include "coop/Lobby.h"

using namespace coop;

// Actual scene identifiers observed in the game's scene load metadata. Never
// invent a scene string from a friendly destination name.
static SceneDesc Miami() {
    return { "assembly:/_pro/scenes/missions/miami/scene_flamingo.entity",
             { "assembly:/_pro/scenes/missions/miami/mission_flamingo.brick" }, "flamingo" };
}
static SceneDesc Paris() {
    return { "assembly:/_pro/scenes/missions/paris/_scene_paris.entity",
             { "assembly:/_pro/scenes/missions/paris/mission_peacock.brick" }, "peacock" };
}
TEST(Lobby_OnlyAcceptsRealObservedSceneMetadata) {
    LobbyRoom lobby;
    CHECK(!lobby.Observe(0, {}));
    CHECK(!lobby.Observe(0, { "assembly:/fictional/level.entity", {"mission.fake.brick"}, "made-up" }));
    CHECK(!lobby.Observe(0, { "assembly:/_pro/scenes/missions/miami/scene_flamingo.entity", {}, "flamingo" }));
    CHECK(lobby.Observe(0, Miami()));
    CHECK(!lobby.Observe(0, Miami()));
    CHECK(lobby.State().count == 1);
    CHECK(lobby.State().options[0].observed == 1);
    CHECK(!lobby.LockWinner(0)); // must have two votes and both access confirmed
}
TEST(Lobby_MatchingVotesReadyLaunchSlowLoadingAndReplay) {
    LobbyRoom room;
    REQUIRE(room.Observe(0, Miami()));
    REQUIRE(room.Observe(1, Miami()));
    REQUIRE(room.Observe(0, Paris()));
    REQUIRE(room.Observe(1, Paris()));
    REQUIRE(room.Vote(0, 0));
    REQUIRE(room.Vote(1, 0));
    CHECK(room.State().phase == LobbyPhase::Ready); // unanimous auto-selection
    CHECK(!room.LockWinner(1)); // host can't override a unanimous vote
    CHECK(!room.LockWinner(0)); // can't silently change after ready phase
    CHECK(room.State().selected == 0);
    CHECK(room.State().phase == LobbyPhase::Ready);
    CHECK(!room.SetReady(0, true, false)); // game / mod mismatch
    REQUIRE(room.SetReady(0, true, true));
    CHECK(!room.CanLaunch(true));
    REQUIRE(room.SetReady(1, true, true));
    CHECK(room.CanLaunch(true));
    CHECK(!room.RequestLaunch(0, 1.0, true));
    REQUIRE(room.RequestLaunch(1234, 1.0, true));
    CHECK(!room.RequestLaunch(1234, 2.0, true)); // duplicate launch
    CHECK(room.HoldGameplay());
    CHECK(!room.SceneLoaded(0, Miami())); // no load before peer validates request
    REQUIRE(room.AcceptLaunch(1234));
    CHECK(!room.AcceptLaunch(1234));
    CHECK(!room.SceneLoaded(1, Paris())); // mismatched mission rejected
    REQUIRE(room.SceneLoaded(0, Miami()));
    CHECK(room.State().loaded[0] && !room.State().loaded[1]);
    CHECK(!room.BeginGameplay(false));
    CHECK(!room.BeginGameplay(true)); // one computer not loaded yet
    REQUIRE(room.SceneLoaded(1, Miami()));
    CHECK(!room.BeginGameplay(false)); // current scene must be synchronized
    REQUIRE(room.BeginGameplay(true));
    CHECK(room.State().phase == LobbyPhase::Playing);
    CHECK(!room.HoldGameplay());
    REQUIRE(room.ReturnToVoting());
    CHECK(room.State().selected == kLobbyNoChoice && !room.State().ready[0] && !room.State().ready[1]);
}
TEST(Lobby_TieHostExplicitlyPicksButCannotChangeAfterLock) {
    LobbyRoom room;
    REQUIRE(room.Observe(0, Miami()));
    REQUIRE(room.Observe(1, Miami()));
    REQUIRE(room.Observe(0, Paris()));
    REQUIRE(room.Observe(1, Paris()));
    REQUIRE(room.Vote(0, 0));
    REQUIRE(room.Vote(1, 1));
    CHECK(!room.LockWinner(2));
    REQUIRE(room.LockWinner(1)); // explicit tie breaker
    CHECK(!room.LockWinner(0));
    REQUIRE(room.SetReady(0, true, true));
    REQUIRE(room.SetReady(1, true, true));
    CHECK(!room.Vote(1, 0));
    REQUIRE(room.ReturnToVoting());
    CHECK(room.State().phase == LobbyPhase::Voting);
    CHECK(room.State().votes[0] == kLobbyNoChoice);
    REQUIRE(room.Vote(0, 1));
    REQUIRE(room.Vote(1, 0));
    REQUIRE(room.LockWinner(0));
    CHECK(room.State().selected == 0);
    CHECK(!room.State().ready[0]);
}
TEST(Lobby_TimeoutAndDisconnectRecovery) {
    LobbyRoom room;
    REQUIRE(room.Observe(0, Miami()));
    REQUIRE(room.Observe(1, Miami()));
    REQUIRE(room.Vote(0, 0));
    REQUIRE(room.Vote(1, 0));
    REQUIRE(room.State().phase == LobbyPhase::Ready);
    REQUIRE(room.SetReady(0, true, true));
    REQUIRE(room.SetReady(1, true, true));
    REQUIRE(room.RequestLaunch(3400, 1.0, true));
    CHECK(!room.Timeout(60.0));
    REQUIRE(room.Timeout(122.0));
    CHECK(room.State().phase == LobbyPhase::Failed);
    CHECK(!room.HoldGameplay());
    CHECK(!room.SceneLoaded(1, Miami()));
    REQUIRE(room.ReturnToVoting());
    CHECK(room.State().launchId == 3400);
    REQUIRE(room.Vote(0, 0));
    REQUIRE(room.Vote(1, 0));
    REQUIRE(room.State().phase == LobbyPhase::Ready);
    REQUIRE(room.SetReady(0, true, true));
    REQUIRE(room.SetReady(1, true, true));
    CHECK(!room.RequestLaunch(3400, 150.0, true)); // replay attack
    CHECK(room.RequestLaunch(3401, 150.0, true));
    REQUIRE(room.Abort("Connection lost while loading."));
    CHECK(room.State().phase == LobbyPhase::Failed);
    CHECK(!room.HoldGameplay());
}
TEST(Lobby_SnapshotAndInputWireValidation) {
    LobbyRoom room;
    REQUIRE(room.Observe(0, Miami()));
    REQUIRE(room.Observe(1, Miami()));
    REQUIRE(room.Observe(0, Paris()));
    REQUIRE(room.Vote(0, 0));
    MsgLobbySnapshot message { room.State() };
    const auto data = Encode(message);
    CHECK(data.size() < kMaxMessageSize);
    MsgLobbySnapshot decoded;
    REQUIRE(Decode(data, decoded));
    CHECK(decoded.state.revision == room.State().revision);
    CHECK(decoded.state.count == 2);
    CHECK(decoded.state.options[0].scene.SameAs(Miami()));
    CHECK(decoded.state.options[1].observed == 1);
    CHECK(room.ApplySnapshot(decoded.state) == false); // can't roll back own revision
    LobbyRoom guest;
    REQUIRE(guest.ApplySnapshot(decoded.state));
    CHECK(!guest.ApplySnapshot(decoded.state)); // duplicate/old snapshot
    MsgLobbyInput input;
    input.kind = LobbyInputKind::Observed;
    input.serial = 4;
    input.scene = Miami();
    const auto encoded = Encode(input);
    MsgLobbyInput out;
    REQUIRE(Decode(encoded, out));
    CHECK(out.serial == 4 && out.scene.SameAs(Miami()));
    auto malformed = encoded;
    malformed[0] = 255;
    CHECK(!Decode(malformed, out)); // invalid command kind
    malformed = encoded;
    malformed[1] = malformed[2] = malformed[3] = malformed[4] = 0;
    CHECK(!Decode(malformed, out)); // replay sequence zero
}
