#!/usr/bin/env bash
set -uo pipefail

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

FORCED_GAME=""
FORCED_STEAM=""
FORCED_PROTON=""
FORCE_DIRECT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --game)
      [[ $# -ge 2 ]] || die "--game requires a path."
      FORCED_GAME="$2"
      shift 2
      ;;
    --steam)
      [[ $# -ge 2 ]] || die "--steam requires a path."
      FORCED_STEAM="$2"
      shift 2
      ;;
    --proton)
      [[ $# -ge 2 ]] || die "--proton requires a path."
      FORCED_PROTON="$2"
      shift 2
      ;;
    --force-direct)
      FORCE_DIRECT=1
      shift
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

GAME_ROOT="$(resolve_game_root "$FORCED_GAME")" || die "Unable to locate a HITMAN World of Assassination installation."
STEAM_BIN="$(command -v steam || true)"
if [[ -n "$FORCED_STEAM" ]]; then
  STEAM_BIN="$FORCED_STEAM"
fi
PROTON_BIN="$(command -v proton || true)"
if [[ -n "$FORCED_PROTON" ]]; then
  PROTON_BIN="$FORCED_PROTON"
fi
if [[ -z "$PROTON_BIN" ]]; then
  PROTON_BIN="$(command -v protontricks || true)" 2>/dev/null || true
fi

if [[ "$FORCE_DIRECT" -eq 0 && -n "$STEAM_BIN" ]]; then
  log "Launching HITMAN through Steam (App ID ${HITMAN_COOP_APP_ID})"
  exec "$STEAM_BIN" "steam://rungameid/${HITMAN_COOP_APP_ID}"
fi

if [[ -n "$PROTON_BIN" ]]; then
  GAME_EXE="$(find_hitman_executable "$GAME_ROOT")" || die "Unable to locate HITMAN3.exe under $GAME_ROOT"
  export WINEDLLOVERRIDES="dinput8=n,b;zhmmodsdk=n,b"
  log "Launching HITMAN through Proton direct fallback for troubleshooting."
  exec "$PROTON_BIN" run "$GAME_EXE"
fi

die "No supported Steam or Proton launch route was found."

