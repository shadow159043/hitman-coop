#!/usr/bin/env bash
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$DECK_ROOT/lib/common.sh"
game=""
while (($#)); do
  case "$1" in --game) (($#>=2)) || die "--game needs a path"; game="$2"; shift 2;;
    --help|-h) echo "Usage: bash uninstall.sh [--game PATH]"; exit 0;;
    *) die "Unknown option: $1";;
  esac
done
[[ -f "$MANIFEST" ]] || die "No tracked installation to uninstall."
retail="$(game_forced_or_auto "$game")" || die "HITMAN not found."
[[ "$retail" == "$(saved_game)" ]] || die "Manifest belongs to another installation."
backup="$(sed -n '1s/^BACKUP\t//p' "$MANIFEST")"
[[ -d "$backup" ]] || die "Original-file backup is missing: $backup"
# Check every file before touching any files; never overwrite user modifications.
while IFS=$'\t' read -r rel expected origin; do
  [[ "$rel" == BACKUP ]] && continue
  if [[ -f "$retail/$rel" && "$(hash_file "$retail/$rel")" != "$expected" ]]; then
    die "Refusing to remove a file changed after installation: $rel"
  fi
  if [[ "$origin" == 1 && ! -f "$backup/$rel" ]]; then die "Cannot restore missing backup: $rel"; fi
done < "$MANIFEST"
while IFS=$'\t' read -r rel expected origin; do
  [[ "$rel" == BACKUP ]] && continue
  if [[ "$origin" == 1 ]]; then
    mkdir -p "$retail/$(dirname "$rel")"
    cp -p "$backup/$rel" "$retail/$rel"
  else
    rm -f "$retail/$rel"
  fi
done < "$MANIFEST"
rm -f "$MANIFEST" "$GAME_PATH_FILE"
log "SUCCESS: Artur Edition removed; original files restored."
log "Backup retained at $backup for safety."
