#!/usr/bin/env bash
set -uo pipefail

# Compatibility wrapper for the Windows Artur Edition under Proton on Steam Deck.
# This is intentionally separate from the Windows install flow.

readonly HITMAN_COOP_APP_ID="1659040"
readonly HITMAN_COOP_PROTON_STATIC_OVERRIDE='WINEDLLOVERRIDES="dinput8=n,b;zhmmodsdk=n,b"'

usage() {
  cat <<'EOF'
Steam Deck / Proton launcher wrapper for HITMAN Co-op Artur Edition.

Usage:
  ./tools/steamdeck-launch.sh [--game PATH] [--proton PATH]

Uses the correct Steam App ID: 1659040.
EOF
}

FORCED_GAME=""
FORCED_PROTON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --game)
      [[ $# -ge 2 ]] || { echo "--game requires a path" >&2; exit 2; }
      FORCED_GAME="$2"
      shift 2
      ;;
    --proton)
      [[ $# -ge 2 ]] || { echo "--proton requires a path" >&2; exit 2; }
      FORCED_PROTON="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -n "$FORCED_PROTON" ]]; then
  if [[ -x "$FORCED_PROTON" ]]; then
    PROTON_BIN="$FORCED_PROTON"
  else
    echo "Proton binary was supplied but is not executable: $FORCED_PROTON" >&2
    exit 3
  fi
else
  PROTON_BIN="$(command -v proton || true)"
  if [[ -z "$PROTON_BIN" ]]; then
    PROTON_BIN="$(command -v protontricks || true)"
  fi
fi

if [[ -n "$FORCED_GAME" ]]; then
  GAME_PATH="$FORCED_GAME"
elif [[ -f "$HOME/.steam/steam/steamapps/common/HITMAN World of Assassination/Retail/HITMAN3.exe" ]]; then
  GAME_PATH="$HOME/.steam/steam/steamapps/common/HITMAN World of Assassination/Retail/HITMAN3.exe"
else
  GAME_PATH=""
fi

if [[ -x "$(command -v steam || true)" ]]; then
  echo "Launching HITMAN through Steam App ID ${HITMAN_COOP_APP_ID}"
  exec "$(command -v steam)" "steam://rungameid/${HITMAN_COOP_APP_ID}"
fi

if [[ -n "$PROTON_BIN" && -n "$GAME_PATH" ]]; then
  echo "Steam was unavailable; falling back to Proton direct launch for troubleshooting."
  export WINEDLLOVERRIDES="dinput8=n,b;zhmmodsdk=n,b"
  exec "$PROTON_BIN" run "$GAME_PATH"
fi

echo "Neither Steam nor Proton was found. The Steam Deck package cannot launch HITMAN." >&2
exit 4

