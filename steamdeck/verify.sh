#!/usr/bin/env bash
set -uo pipefail

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
HITMAN Co-op — Artur Edition Steam Deck verification

Usage:
  ./verify.sh [--game PATH] [--package PATH]

Checks whether a HITMAN installation already contains the Artur Edition mod files
and whether the directory layout is compatible with Proton/Steam Deck.
EOF
}

FORCED_GAME=""
FORCED_PACKAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --game)
      [[ $# -ge 2 ]] || die "--game requires a path."
      FORCED_GAME="$2"
      shift 2
      ;;
    --package)
      [[ $# -ge 2 ]] || die "--package requires a path."
      FORCED_PACKAGE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      warn "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

GAME_ROOT="$(detect_hitman_root "$FORCED_GAME")" || die "Unable to find a HITMAN installation."
PACKAGE_DIR="$(detect_release_package "$FORCED_PACKAGE")" || warn "No Artur Edition package directory was found; continuing with game-only checks."

verify_installation "$GAME_ROOT" "$PACKAGE_DIR"
exit $?

