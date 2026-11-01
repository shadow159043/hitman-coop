#!/usr/bin/env bash
set -uo pipefail

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
HITMAN Co-op — Artur Edition Steam Deck verification

Usage:
  ./verify.sh [--game PATH] [--package PATH]

Verifies that the required Artur Edition files exist in the target HITMAN installation.
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
    -h|--help)
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

GAME_ROOT="$(resolve_game_root "$FORCED_GAME")" || die "Unable to locate a HITMAN installation."
PACKAGE_ROOT="$(resolve_package_root "$FORCED_PACKAGE")" || warn "No package bundle was supplied; continuing with game-only checks."
verify_installation "$GAME_ROOT" "$PACKAGE_ROOT"
exit $?

