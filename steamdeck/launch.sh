#!/usr/bin/env bash
set -uo pipefail

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
HITMAN Co-op — Artur Edition Steam Deck launcher

Usage:
  ./launch.sh [--game PATH] [--steam PATH] [--proton PATH] [--force-direct]

Options:
  --game PATH         Force a HITMAN installation path.
  --steam PATH        Force a Steam executable path.
  --proton PATH       Force a Proton binary path.
  --force-direct      Bypass Steam and launch via Proton directly.
  --help              Show this help.

Notes:
  - This script prefers launching the game via Steam so Steam authentication and
    friend invites remain available where Proton supports them.
  - Direct Proton launch is only a fallback when Steam is unavailable.
  - Actual gaming compatibility still requires real hardware testing.
EOF
}

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

GAME_ROOT="$(detect_hitman_root "$FORCED_GAME")" || die "Unable to find a HITMAN installation. Install HITMAN World of Assassination first."

STEAM_BIN="$(detect_steam_bin "$FORCED_STEAM")" || STEAM_BIN=""
PROTON_BIN="$(detect_proton_bin "$FORCED_PROTON")" || PROTON_BIN=""

if [[ "$FORCE_DIRECT" -eq 1 || -z "$STEAM_BIN" ]]; then
  if [[ -z "$PROTON_BIN" ]]; then
    die "Proton is required for direct launch, but none was found. Install Proton Experimental or set --proton."
  fi

  GAME_EXE="$(find_hitman_executable "$GAME_ROOT")" || die "Could not find HITMAN3.exe under $GAME_ROOT"
  export WINEDLLOVERRIDES="dinput8=n,b"
  log "Launching HITMAN through Proton directly: $GAME_EXE"
  exec "$PROTON_BIN" run "$GAME_EXE"
fi

if [[ -n "$STEAM_BIN" ]]; then
  # Prefer launching through Steam so Steam UI, overlays, and friend invites stay available.
  log "Launching HITMAN through Steam: $STEAM_BIN"
  exec "$STEAM_BIN" steam://rungameid/1659420
fi

# Fallback path if Steam is not installed or not usable.
if [[ -n "$PROTON_BIN" ]]; then
  GAME_EXE="$(find_hitman_executable "$GAME_ROOT")" || die "Could not find HITMAN3.exe under $GAME_ROOT"
  export WINEDLLOVERRIDES="dinput8=n,b"
  log "Steam not available; falling back to Proton direct launch."
  exec "$PROTON_BIN" run "$GAME_EXE"
fi

die "No supported Steam or Proton launch path was found."

