#include "SteamInvite.h"
#include "SteamP2P.h"
#include "coop/Socket.h"
#include <cassert>
#include <iostream>

struct FakeSocket : coop::IDatagramSocket {
    int sent = 0, ready = 0;
    bool SendTo(const coop::Endpoint&, const uint8_t*, size_t) override { ++sent; return true; }
    int RecvFrom(coop::Endpoint& from, uint8_t* buffer, size_t capacity) override {
        if (!ready || !capacity) return -1;
        from = coop::Endpoint::Steam(76561198000000000ULL);
        buffer[0] = 42; --ready; return 1;
    }
};
int main() {
    const std::string good = SteamInvite::Encode("steam:76561198000000000", "ARTUR-42");
    assert(good == "arturcoop1|steam:76561198000000000|ARTUR-42");
    auto decoded = SteamInvite::Decode(good);
    assert(decoded && decoded->address == "steam:76561198000000000" && decoded->room == "ARTUR-42");
    assert(!SteamInvite::Decode("arturcoop1|steam:76561198000000000|EXTRA|SEP"));
    assert(!SteamInvite::Decode("arturcoop1|127.0.0.1:47047|no"));
    assert(SteamInvite::Encode("bad;address", "ARTUR-42").empty());
    assert(!SteamInvite::Encode("100.68.41.2:47047", "SAMPLE").empty());
    uint64_t id = 0;
    assert(SteamP2PSocket::ParseAddress("steam:76561198000000000", id) && id == 76561198000000000ULL);
    assert(!SteamP2PSocket::ParseAddress("steam:480", id));
    assert(!SteamP2PSocket::ParseAddress("steam:76561198abc", id));
    const auto target = coop::Endpoint::Steam(76561198000000000ULL);
    assert(target.IsSteam() && !target.IsRelay() && target != coop::Endpoint::Relay(3));
    auto u = std::make_unique<FakeSocket>(), r = std::make_unique<FakeSocket>(), p = std::make_unique<FakeSocket>();
    FakeSocket* up = u.get(), *rp = r.get(), *pp = p.get();
    coop::MultiSocket mux(std::move(u), std::move(r), std::move(p));
    uint8_t buf[] = {1, 2, 3};
    assert(mux.SendTo(target, buf, 3));
    assert(mux.SendTo(coop::Endpoint::Relay(3), buf, 3));
    assert(mux.SendTo(coop::Endpoint{0x7f000001, 47047}, buf, 3));
    assert(up->sent == 1 && rp->sent == 1 && pp->sent == 1);
    pp->ready = 1;
    coop::Endpoint from;
    assert(mux.RecvFrom(from, buf, sizeof(buf)) == 1 && from == target && buf[0] == 42);
    SteamInvite test;
    std::string error;
    assert(!test.OpenInviteDialog("steam:76561198000000000", "ARTUR-42", error) && !error.empty());
    std::cout << "Steam invite parser, Steam routing, fail-closed: PASS\n";
    return 0;
}
