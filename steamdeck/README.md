#!/usr/bin/env bash
set -uo pipefail

# This project is deliberately modular. The Steam Deck compatibility layer is a thin
# wrapper around the existing Windows mod package and Proton compatibility setup.
# It intentionally does not rewrite the co-op gameplay or networking code.

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cat <<'EOF'
This package is experimental and intentionally separate from the Windows build.
It is designed to run the existing HITMAN Co-op Windows mod through Proton on
Steam Deck devices, but actual gameplay compatibility still requires real
hardware testing.
EOF

