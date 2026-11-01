#!/usr/bin/env bash
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$DECK_ROOT/lib/common.sh"
steam_cmd="${STEAM_BIN:-}"
while (($#)); do
  case "$1" in --steam) (($#>=2)) || die "--steam needs an executable"; steam_cmd="$2"; shift 2;;
    --help|-h) echo "Usage: bash launch.sh [--steam STEAM_EXECUTABLE]"; exit 0;;
    *) die "Unknown option: $1";;
  esac
done
[[ -n "$steam_cmd" ]] || steam_cmd="$(command -v steam || true)"
[[ -n "$steam_cmd" ]] || die "Steam not found. Launch HITMAN from Steam Desktop Mode instead."
if [[ "$steam_cmd" == */* ]]; then [[ -x "$steam_cmd" ]] || die "Steam executable is not available: $steam_cmd"; fi
log "Launching officially installed HITMAN through Steam App ID $APP_ID"
log 'If using an older Proton, consult the ZHMModSDK Deck instructions for DLL overrides.'
exec "$steam_cmd" "steam://rungameid/$APP_ID"
