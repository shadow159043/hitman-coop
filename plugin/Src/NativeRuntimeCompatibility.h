#pragma once

#include <string_view>

// Pure, engine-independent compatibility check, shared by the plugin and core tests.
// Fail closed on unknown game/SDK combinations: native detours are patch-specific.
// The HITMAN 3.290 build uses SDK 4.2.1; the 3.280 build uses SDK 4.1.1.
namespace coop::runtime {

inline constexpr std::string_view RequiredGame(std::string_view target) noexcept {
    if (target == "3.290")
        return "3.290.1.0";
    if (target == "3.280")
        return "3.280.x";
    return "(unsupported target)";
}

inline constexpr std::string_view RequiredSdk(std::string_view target) noexcept {
    if (target == "3.290")
        return "4.2.1.0";
    if (target == "3.280")
        return "4.1.1.0";
    return "(unsupported target)";
}

inline constexpr bool Compatible(std::string_view game, std::string_view sdk, std::string_view target) noexcept {
    if (target == "3.290")
        return game == "3.290.1.0" && sdk == "4.2.1.0";
    if (target == "3.280")
        return game.starts_with("3.280.") && sdk == "4.1.1.0";
    return false;
}

static_assert(Compatible("3.290.1.0", "4.2.1.0", "3.290"));
static_assert(Compatible("3.280.0.0", "4.1.1.0", "3.280"));
static_assert(!Compatible("3.290.1.0", "4.2.0.0", "3.290"));
static_assert(!Compatible("3.290.1.0", "4.1.1.0", "3.290"));
static_assert(!Compatible("3.290.2.0", "4.2.1.0", "3.290"));
static_assert(!Compatible("3.280.0.0", "4.2.1.0", "3.280"));
static_assert(!Compatible("unknown", "4.2.1.0", "3.290"));

} // namespace coop::runtime
