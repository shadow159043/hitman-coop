#!/usr/bin/env bash
set -uo pipefail

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
HITMAN Co-op — Artur Edition Steam Deck restore

Usage:
  ./restore.sh [--game PATH]

Restores the game from the most recent backup without reinstalling.
EOF
}

FORCED_GAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --game)
      [[ $# -ge 2 ]] || die "--game requires a path."
      FORCED_GAME="$2"
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

restore_backup "$FORCED_GAME"
exit $?

