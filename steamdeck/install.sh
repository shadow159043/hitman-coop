#!/usr/bin/env bash
set -uo pipefail

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
HITMAN Co-op — Artur Edition Steam Deck / Proton installer

Usage:
  ./install.sh [--game PATH] [--package PATH] [--install] [--verify] [--uninstall]

Options:
  --game PATH        Force the HITMAN installation directory or Retail folder.
  --package PATH     Path to the Artur Edition release bundle or extracted package.
  --install          Install the mod (default action).
  --verify           Only check whether the installation is present and valid.
  --uninstall        Restore the backup and remove Steam Deck compatibility files.
  --help             Show this help.

Notes:
  - This package intentionally does not rewrite the Windows multiplayer system.
  - It installs the existing Artur Edition Windows mod files through Proton.
  - Actual gameplay on Steam Deck still requires real hardware validation.
EOF
}

AUTO_INSTALL=1
VERIFY_ONLY=0
UNINSTALL_ONLY=0
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
    --install)
      AUTO_INSTALL=1
      VERIFY_ONLY=0
      UNINSTALL_ONLY=0
      shift
      ;;
    --verify)
      VERIFY_ONLY=1
      AUTO_INSTALL=0
      UNINSTALL_ONLY=0
      shift
      ;;
    --uninstall)
      UNINSTALL_ONLY=1
      AUTO_INSTALL=0
      VERIFY_ONLY=0
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

if [[ "$UNINSTALL_ONLY" -eq 1 ]]; then
  restore_backup "$FORCED_GAME"
  exit $?
fi

GAME_ROOT="$(detect_hitman_root "$FORCED_GAME")" || die "Unable to find a HITMAN installation. Set --game to the game folder manually."
PACKAGE_DIR="$(detect_release_package "$FORCED_PACKAGE")" || die "Unable to find the Artur Edition release package. Supply --package with the extracted release folder or zip folder."

if [[ "$VERIFY_ONLY" -eq 1 ]]; then
  verify_installation "$GAME_ROOT" "$PACKAGE_DIR"
  exit $?
fi

if [[ ! -d "$GAME_ROOT" ]]; then
  die "Game directory does not exist: $GAME_ROOT"
fi

if [[ ! -d "$PACKAGE_DIR" ]]; then
  die "Package directory does not exist: $PACKAGE_DIR"
fi

backup_existing_install "$GAME_ROOT"
if [[ $? -ne 0 ]]; then
  warn "Backup step failed; installation will not continue."
  exit 4
fi

install_artur_edition "$GAME_ROOT" "$PACKAGE_DIR"
if [[ $? -ne 0 ]]; then
  warn "Install step failed. The original backup is still available."
  exit 5
fi

verify_installation "$GAME_ROOT" "$PACKAGE_DIR"
if [[ $? -ne 0 ]]; then
  warn "The installation check failed after copying files. The original backup remains available under the game's backup directory."
  exit 6
fi

log "Steam Deck compatibility install completed."
log "Recommended next step: launch through Steam or use $STEAMDECK_ROOT/launch.sh."
log "If the install fails, run: $STEAMDECK_ROOT/uninstall.sh"

