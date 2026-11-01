#!/usr/bin/env bash
set -euo pipefail

# Steam Deck / Proton launcher for HITMAN Co-op.
# This does not port the Windows mod to native Linux; instead it launches the
# existing Windows HITMAN install with Proton and adds the dinput8 override that
# the project explicitly documents for Steam Deck / Linux compatibility.
#
# Usage:
#   ./tools/steamdeck-launch.sh
#   ./tools/steamdeck-launch.sh --game /path/to/HITMAN3.exe
#   ./tools/steamdeck-launch.sh --proton /path/to/proton
#
# Notes:
#   - The script expects the normal Windows HITMAN installation and the same mod
#     files already installed by the Windows setup.
#   - It keeps the original Windows mod install path intact and just wraps the
#     game launch in Proton with the required override.

GAME_PATH=""
PROTON_PATH=""

usage() {
  echo "Usage: $0 [--game /path/to/HITMAN3.exe] [--proton /path/to/proton]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --game)
      [[ $# -ge 2 ]] || usage
      GAME_PATH="$2"
      shift 2
      ;;
    --proton)
      [[ $# -ge 2 ]] || usage
      PROTON_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "$PROTON_PATH" ]]; then
  CANDIDATES=(
    "$HOME/.steam/steam/steamapps/common/Proton - Experimental/proton"
    "$HOME/.steam/steam/steamapps/common/Proton 9/proton"
    "$HOME/.local/share/Steam/steamapps/common/Proton - Experimental/proton"
    "$HOME/.local/share/Steam/steamapps/common/Proton 9/proton"
    "/usr/bin/steam"
  )

  for candidate in "${CANDIDATES[@]}"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      PROTON_PATH="$candidate"
      break
    fi
  done
fi

if [[ -z "$GAME_PATH" ]]; then
  CANDIDATES=(
    "$HOME/.steam/steam/steamapps/common/HITMAN 3/HITMAN3.exe"
    "$HOME/.steam/steam/steamapps/common/HITMAN World of Assassination/HITMAN3.exe"
    "$HOME/.steam/steam/steamapps/common/HITMAN 3/Retail/HITMAN3.exe"
    "$HOME/.steam/steam/steamapps/common/HITMAN World of Assassination/Retail/HITMAN3.exe"
    "$HOME/.local/share/Steam/steamapps/common/HITMAN 3/HITMAN3.exe"
    "$HOME/.local/share/Steam/steamapps/common/HITMAN World of Assassination/HITMAN3.exe"
    "$HOME/.local/share/Steam/steamapps/common/HITMAN 3/Retail/HITMAN3.exe"
    "$HOME/.local/share/Steam/steamapps/common/HITMAN World of Assassination/Retail/HITMAN3.exe"
  )

  for candidate in "${CANDIDATES[@]}"; do
    if [[ -f "$candidate" ]]; then
      GAME_PATH="$candidate"
      break
    fi
  done
fi

if [[ -z "$GAME_PATH" ]]; then
  echo "Could not find a HITMAN game installation automatically." >&2
  echo "Set --game to the HITMAN3.exe path manually." >&2
  exit 2
fi

if [[ -z "$PROTON_PATH" ]]; then
  echo "Could not find Proton automatically." >&2
  echo "Set --proton to the Proton executable manually." >&2
  exit 3
fi

# `steam-run` is the easiest path on Steam Deck if available.
# Fall back to the proton executable directly.
if [[ -x "/usr/bin/steam-run" ]]; then
  echo "Launching HITMAN Co-op via Steam Deck Proton compatibility layer..."
  env WINEDLLOVERRIDES="dinput8=n,b" PROTON_NO_ESYNC=1 /usr/bin/steam-run "$GAME_PATH"
  exit $?
fi

if [[ "$PROTON_PATH" == "/usr/bin/steam" ]]; then
  echo "Steam binary found, but no Proton runtime was detected in the usual locations." >&2
  echo "Please pass --proton to the Proton executable, or install Proton compatibility tools." >&2
  exit 4
fi

# Proton expects the game executable path inside the Windows prefix, not a host
# Linux path. The normal Steam Deck flow is to launch the game through Steam,
# while this wrapper is primarily for manual runs.
#
# If the Proton binary is present, we still call it directly to keep the exact
# same Windows install path and use the same dinput8 override documented by the
# project.

echo "Launching HITMAN Co-op with Proton wrapper..."
  env WINEDLLOVERRIDES="dinput8=n,b" PROTON_NO_ESYNC=1 "$PROTON_PATH" run "$GAME_PATH"

