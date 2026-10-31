#pragma once
#include <algorithm>
#include <cstddef>
#include <vector>

// Native item scene-visibility rules. These helpers can be tested without
// calling the HITMAN SDK or dereferencing native renderer internals.
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

// Walk only verified parent->child spatial edges, never an item's parent or
// unrelated siblings. Cycles and huge/malformed lists are bounded by limit.
template<class Node, class Children, class Next, class Parent>
std::vector<Node*> CollectItemNodes(
    std::vector<Node*> roots, Children children, Next next, Parent parent,
    size_t limit = 64) {
    if (roots.size() > limit) roots.resize(limit);
    for (size_t i = 0; i < roots.size() && roots.size() < limit; ++i) {
        Node* current = roots[i];
        if (!current) continue;
        Node* child = children(current);
        size_t siblingGuard = 0;
        while (child && siblingGuard++ < limit && roots.size() < limit) {
            if (parent(child) != current) break;
            if (std::find(roots.begin(), roots.end(), child) == roots.end())
                roots.push_back(child);
            child = next(child);
        }
    }
    return roots;
}
}
