#pragma once
#include <array>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <limits>
#include <string>
#include <string_view>

namespace coop::duel {
constexpr int kRounds = 12;
constexpr int kTieWindowMs = 35;
constexpr int kRoundMs = 850;
constexpr double kSecondsPerRound = 0.85;
constexpr double kLeadSeconds = 3.5;
constexpr double kDuration = kRounds * kSecondsPerRound;
constexpr float kChallengeRange = 2.75f;

// Four directions are equally available to both players. Each round counts
// a maximum of one correct key press, so button-mashing cannot farm points.
// Follows the same random-looking, seed-derived pattern on both computers.
inline int Prompt(uint32_t p_Seed, int p_Round) {
    uint32_t x = p_Seed ^ (0x9E3779B9u * static_cast<uint32_t>(p_Round + 1));
    x ^= x >> 16; x *= 0x7FEB352Du;
    x ^= x >> 15; x *= 0x846CA68Bu;
    x ^= x >> 16;
    return static_cast<int>(x & 3u);
}

inline int Round(double p_Now, double p_Start) {
    if (!std::isfinite(p_Now) || !std::isfinite(p_Start) || p_Now < p_Start)
        return -1;
    const double t = (p_Now - p_Start) / kSecondsPerRound;
    return t >= kRounds ? kRounds : static_cast<int>(t);
}
// Each game records elapsed local time from its OWN displayed prompt. Comparing
// packet-arrival times would unfairly favor whoever hosts the session.
// -1 means no valid press; -2 means an invalid untrusted value.
inline int Judge(int p_HostMs, int p_ClientMs) {
    if (p_HostMs < -1 || p_HostMs >= kRoundMs ||
        p_ClientMs < -1 || p_ClientMs >= kRoundMs) return -2;
    if (p_HostMs < 0 && p_ClientMs < 0) return 0;
    if (p_ClientMs < 0) return 1;
    if (p_HostMs < 0) return 2;
    if (std::abs(p_HostMs - p_ClientMs) <= kTieWindowMs) return 0;
    return p_HostMs < p_ClientMs ? 1 : 2;
}
inline int Winner(int p_HostScore, int p_ClientScore) {
    if (p_HostScore < 0 || p_HostScore > kRounds ||
        p_ClientScore < 0 || p_ClientScore > kRounds) return -2;
    return p_HostScore == p_ClientScore ? 0 : p_HostScore > p_ClientScore ? 1 : 2;
}

// Strict untrusted event wire parser. Only bounded decimal ID, seed and score;
// no strings, game pointers, remote timings or damage amounts cross the wire.
inline bool Number(std::string_view s, uint32_t& p_Out, uint32_t p_Max = 0xFFFFFFFFu) {
    if (s.empty() || s.size() > 10) return false;
    for (char c : s) if (c < '0' || c > '9') return false;
    auto [ptr, err] = std::from_chars(s.data(), s.data() + s.size(), p_Out);
    return err == std::errc{} && ptr == s.data() + s.size() && p_Out <= p_Max;
}
inline bool Pair(std::string_view s, uint32_t& a, uint32_t& b, uint32_t p_MaxB) {
    auto at = s.find(':');
    return at != std::string_view::npos && s.find(':', at + 1) == std::string_view::npos &&
           Number(s.substr(0, at), a) && a != 0 &&
           Number(s.substr(at + 1), b, p_MaxB);
}
inline bool Triple(std::string_view s, uint32_t& a, uint32_t& b, uint32_t& c, uint32_t p_MaxB, uint32_t p_MaxC) {
    auto p = s.find(':');
    auto q = p == std::string_view::npos ? p : s.find(':', p + 1);
    return p != std::string_view::npos && q != std::string_view::npos &&
           s.find(':', q + 1) == std::string_view::npos &&
           Number(s.substr(0, p), a) && a != 0 &&
           Number(s.substr(p + 1, q - p - 1), b, p_MaxB) &&
           Number(s.substr(q + 1), c, p_MaxC);
}
struct Rhythm {
    int score = 0;
    int lastScored = -1;
    bool Press(uint32_t p_Seed, int p_PressedDirection, double p_Now, double p_Start) {
        const int r = Round(p_Now, p_Start);
        if (r < 0 || r >= kRounds || r == lastScored || p_PressedDirection != Prompt(p_Seed, r))
            return false;
        lastScored = r;
        ++score;
        return true;
    }
};
} // namespace coop::duel
