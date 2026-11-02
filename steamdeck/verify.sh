#!/usr/bin/env bash
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$DECK_ROOT/lib/common.sh"
game=""
while (($#)); do
  case "$1" in --game) (($#>=2)) || die "--game requires a path"; game="$2"; shift 2;;
    --help|-h) echo "Usage: bash verify.sh [--game PATH]"; exit 0;;
    *) die "Unknown option: $1";;
  esac
done
retail="$(game_forced_or_auto "$game")" || die "HITMAN not detected."
[[ -f "$MANIFEST" ]] || die "No tracked Artur Edition installation. Run install.sh first."
[[ "$(saved_game)" == "$retail" ]] || die "Install manifest belongs to a different game location."
[[ -f "$retail/HITMAN3.exe" ]] || die "HITMAN3.exe is missing."
checked=0
while IFS=$'\t' read -r rel expected origin; do
  [[ "$rel" == BACKUP ]] && continue
  [[ -n "$rel" && -f "$retail/$rel" ]] || die "Missing installed file: $rel"
  if [[ "$rel" == mods.ini ]]; then
    # mods.ini is shared with other mods and ZHMModSDK; unrelated edits are valid.
    # Never treat config drift as binary corruption or rewrite it during verification.
    grep -Eiq '^[[:space:]]*\[HitmanCoop\][[:space:]]*
done < "$MANIFEST"
[[ $checked -eq 7 ]] || die "Installation manifest is incomplete ($checked tracked files)."
grep -Eiq '^[[:space:]]*\[HitmanCoop\][[:space:]]*$' "$retail/mods.ini" || die "HitmanCoop is not enabled in mods.ini"
log "PASS: $checked tracked files verified for Artur Edition R2.18.1 (protocol 16)."
log "NOTE: This does not prove that Proton loads the mod or multiplayer works on a Steam Deck."
 "$retail/mods.ini" ||
      die "HitmanCoop is not enabled in mods.ini"
    active_conflict "$retail/mods.ini" &&
      die "Conflicting Assassin Rivals 2 section is enabled in mods.ini"
    if [[ "$(hash_file "$retail/mods.ini")" != "$expected" ]]; then
      warn "mods.ini changed since installation; preserving other mod settings. Safe uninstall remains guarded until the change is reviewed."
    fi
  else
    [[ "$(hash_file "$retail/$rel")" == "$expected" ]] ||
      die "Modified or corrupted installed file: $rel"
  fi
  checked=$((checked+1))
done < "$MANIFEST"
[[ $checked -eq 7 ]] || die "Installation manifest is incomplete ($checked tracked files)."
grep -Eiq '^[[:space:]]*\[HitmanCoop\][[:space:]]*$' "$retail/mods.ini" || die "HitmanCoop is not enabled in mods.ini"
log "PASS: $checked tracked files verified for Artur Edition R2.18.1 (protocol 16)."
log "NOTE: This does not prove that Proton loads the mod or multiplayer works on a Steam Deck."
