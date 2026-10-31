#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>

namespace coop {

// Where a peer is: an IPv4 address and port (host byte order), or a peer reached through the
// co-op relay server when relayPeer is set (see RelaySocket).
struct Endpoint {
    uint32_t ip = 0;
    uint16_t port = 0;
    uint32_t relayPeer = 0;
    uint64_t steamPeer = 0; // SteamID64, never an App ID or a spoofed identity.

    bool IsRelay() const { return relayPeer != 0; }
    bool IsSteam() const { return steamPeer != 0; }

    bool operator==(const Endpoint& p_Other) const {
        return ip == p_Other.ip && port == p_Other.port && relayPeer == p_Other.relayPeer && steamPeer == p_Other.steamPeer;
    }

    bool operator!=(const Endpoint& p_Other) const { return !(*this == p_Other); }

    static Endpoint Relay(uint32_t p_Peer) { return { 0, 0, p_Peer }; }
    static Endpoint Steam(uint64_t p_Peer) { return { 0, 0, 0, p_Peer }; }

    std::string ToString() const;
};

class IDatagramSocket {
public:
    virtual ~IDatagramSocket() = default;

    virtual bool SendTo(const Endpoint& p_To, const uint8_t* p_Data, size_t p_Size) = 0;

    // Non-blocking. Returns the datagram size, or -1 when nothing is waiting.
    virtual int RecvFrom(Endpoint& p_From, uint8_t* p_Buffer, size_t p_Capacity) = 0;
};

// Winsock UDP socket. Bind port 0 to get an ephemeral port.
class UdpSocket final : public IDatagramSocket {
public:
    ~UdpSocket() override;

    static std::unique_ptr<UdpSocket> Open(uint16_t p_Port, std::string& p_Error);

    bool SendTo(const Endpoint& p_To, const uint8_t* p_Data, size_t p_Size) override;
    int RecvFrom(Endpoint& p_From, uint8_t* p_Buffer, size_t p_Capacity) override;

    uint16_t LocalPort() const { return m_Port; }

private:
    UdpSocket() = default;

    uintptr_t m_Socket = ~static_cast<uintptr_t>(0);
    uint16_t m_Port = 0;
};

// One socket over two transports: relay endpoints go to p_Relay, everything else to p_Udp.
// Either may be null. A host listens on both, so friends can join with a code or by address.
class MultiSocket final : public IDatagramSocket {
public:
    MultiSocket(std::unique_ptr<IDatagramSocket> p_Udp, std::unique_ptr<IDatagramSocket> p_Relay,
                std::unique_ptr<IDatagramSocket> p_Steam = nullptr) :
        m_Udp(std::move(p_Udp)), m_Relay(std::move(p_Relay)), m_Steam(std::move(p_Steam)) {}

    bool SendTo(const Endpoint& p_To, const uint8_t* p_Data, size_t p_Size) override {
        IDatagramSocket* s_Socket = p_To.IsSteam() ? m_Steam.get() :
            (p_To.IsRelay() ? m_Relay.get() : m_Udp.get());
        return s_Socket && s_Socket->SendTo(p_To, p_Data, p_Size);
    }

    int RecvFrom(Endpoint& p_From, uint8_t* p_Buffer, size_t p_Capacity) override {
        // Round-robin all three transports so none starves during a busy mission.
        for (int i = 0; i < 3; ++i) {
            m_Next = (m_Next + 1) % 3;
            IDatagramSocket* s_Socket = m_Next == 0 ? m_Udp.get() :
                (m_Next == 1 ? m_Relay.get() : m_Steam.get());
            if (s_Socket) {
                const int s_Size = s_Socket->RecvFrom(p_From, p_Buffer, p_Capacity);
                if (s_Size >= 0)
                    return s_Size;
            }
        }

        return -1;
    }

private:
    std::unique_ptr<IDatagramSocket> m_Udp;
    std::unique_ptr<IDatagramSocket> m_Relay;
    std::unique_ptr<IDatagramSocket> m_Steam;
    int m_Next = 0;
};

// Resolves "host", "host:port", or "a.b.c.d:port". Uses p_DefaultPort when no port is given.
bool ResolveEndpoint(const std::string& p_Address, uint16_t p_DefaultPort, Endpoint& p_Out, std::string& p_Error);

// This PC's address on the local network (the one a router's port forward should point at),
// or empty if there is no network. Sends no packets.
std::string LocalLanAddress();

// This PC's Tailscale address (100.64.0.0/10), or empty when Tailscale isn't running.
std::string LocalTailscaleAddress();

} // namespace coop
