#pragma once
#include <string_view>

// Fail closed on untested game/SDK combinations, but centralize the supported
// pairing so an SDK upgrade cannot accidentally retain a stale guard.
namespace coop::runtime_compat {
inline constexpr std::string_view kGameVersion = "3.290.1.0";
inline constexpr std::string_view kSdkVersion = "4.2.1.0";

inline bool Supported(std::string_view game, std::string_view sdk) {
    return game == kGameVersion && sdk == kSdkVersion;
}
}
