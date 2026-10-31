#pragma once
// Stand-in inventory model hiding: preserve the *native spatial* flags so a
// shared scene item's mesh is returned to exactly its prior rendering state.
// Pure rules are regression-tested without requiring a live game process.
namespace coop::item_visibility {
struct Flags {
    bool visible = true;
    bool parentHidden = false;
    bool forceVisible = false;
};
constexpr Flags Hidden() { return {false, true, false}; }
constexpr bool IsHidden(Flags v) {
    return !v.visible && v.parentHidden && !v.forceVisible;
}
}
