#!/usr/bin/env bash
set -uo pipefail

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
HITMAN Co-op — Artur Edition Steam Deck installer

Usage:
  ./install.sh [--game PATH] [--package PATH] [--verify] [--repair] [--uninstall]

Options:
  --game PATH        Game directory or Retail folder to install into.
  --package PATH     Windows Artur Edition package or extracted release folder.
  --verify           Only perform verification.
  --repair           Repair missing/modded files without removing the user's other data.
  --uninstall         Restore the previous installation from the Steam Deck backup.
  --help             Show this help.
EOF
}

FORCED_GAME=""
FORCED_PACKAGE=""
VERIFY_ONLY=0
REPAIR_ONLY=0
UNINSTALL_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --game)
      [[ $# -ge 2 ]] || die "--game requires a target path."
      FORCED_GAME="$2"
      shift 2
      ;;
    --package)
      [[ $# -ge 2 ]] || die "--package requires a package path."
      FORCED_PACKAGE="$2"
      shift 2
      ;;
    --verify)
      VERIFY_ONLY=1
      shift
      ;;
    --repair)
      REPAIR_ONLY=1
      shift
      ;;
    --uninstall)
      UNINSTALL_ONLY=1
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

if [[ "$UNINSTALL_ONLY" -eq 1 ]]; then
  restore_backup "$FORCED_GAME"
  exit $?
fi

GAME_ROOT="$(resolve_game_root "$FORCED_GAME")" || die "Unable to locate HITMAN World of Assassination. Pass --game or install HITMAN to Steam first."
PACKAGE_ROOT="$(resolve_package_root "$FORCED_PACKAGE")" || die "Unable to find the Artur Edition package. Supply a path to the extracted R2.18.1 release or a bundle containing Retail/."

if [[ "$VERIFY_ONLY" -eq 1 ]]; then
  verify_installation "$GAME_ROOT" "$PACKAGE_ROOT"
  exit $?
fi

retail_dir="$GAME_ROOT"
if [[ -d "$GAME_ROOT/Retail" ]]; then
  retail_dir="$GAME_ROOT/Retail"
fi
if [[ ! -d "$retail_dir" ]]; then
  die "The game installation is missing a valid Retail directory: $retail_dir"
fi

if [[ "$REPAIR_ONLY" -eq 1 ]]; then
  log "Repair mode: verifying and replacing missing Artur Edition files only."
  if ! verify_installation "$GAME_ROOT" "$PACKAGE_ROOT"; then
    log "Repairing required Artur Edition files..."
  fi
fi

backup_dir="$(backup_existing_install "$GAME_ROOT")" || die "Backup step failed."
source_root="$PACKAGE_ROOT"
if [[ -d "$source_root/Retail" ]]; then
  source_root="$source_root/Retail"
elif [[ -d "$source_root/retail" ]]; then
  source_root="$source_root/retail"
elif [[ -d "$source_root/files/Retail" ]]; then
  source_root="$source_root/files/Retail"
elif [[ -d "$source_root/files/retail" ]]; then
  source_root="$source_root/files/retail"
fi

if [[ ! -d "$source_root" ]]; then
  die "The supplied package does not contain the expected nested Retail structure."
fi

for rel in \
  "dinput8.dll" \
  "ZHMModSDK.dll" \
  "mods.ini"; do
  if [[ -f "$source_root/$rel" ]]; then
    copy_if_present "$source_root/$rel" "$retail_dir/$rel"
  fi
done

mkdir -p "$retail_dir/mods"
for rel in \
  "mods/HitmanCoop.dll" \
  "mods/HitmanCoop.ini" \
  "mods/HitmanCoop.log"; do
  if [[ -f "$source_root/$rel" ]]; then
    copy_if_present "$source_root/$rel" "$retail_dir/$rel"
  fi
done

verify_installation "$GAME_ROOT" "$PACKAGE_ROOT"
if [[ $? -ne 0 ]]; then
  warn "Installation verification failed. The game's previous files remain in $backup_dir."
  exit 5
fi

save_install_meta "$GAME_ROOT" "$PACKAGE_ROOT" "$backup_dir"
log "Artur Edition compatibility install succeeded."
log "Installation state saved to: $HITMAN_COOP_MANIFEST"
log "Backup stored at: $backup_dir"
log "Use ./launch.sh to launch HITMAN through Steam."

