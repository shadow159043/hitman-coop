#!/usr/bin/env bash
set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly HITMAN_COOP_STEAM_APP_ID="1659040"
readonly HITMAN_COOP_FORCE_LAUNCH_OPTION="WINEDLLOVERRIDES='dinput8.dll=n,b;zhmmodsdk.dll=n,b'"

usage() {
  cat <<'EOF'
HITMAN Co-op — Artur Edition Steam Deck / Proton compatibility launcher

Usage:
  ./launch.sh [--game PATH] [--steam PATH] [--proton PATH] [--force-direct]

Notes:
  - This package is a compatibility wrapper around the existing Windows Artur Edition.
  - It prefers launching through Steam to preserve Steam authentication, overlays, and friend invitations.
  - Real Steam Deck gameplay compatibility still requires hardware testing.
EOF
}

