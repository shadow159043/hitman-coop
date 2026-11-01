#!/usr/bin/env bash
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$DECK_ROOT/lib/common.sh"
game="" source_pkg="" repair=0
usage() { echo "Usage: bash install.sh [--game GAME_ROOT_OR_RETAIL] [--package RELEASE_ZIP_OR_DIRECTORY] [--repair]"; }
while (($#)); do
  case "$1" in
    --game|--package) (($#>=2)) || die "$1 needs a path"; if [[ "$1" == --game ]]; then game="$2"; else source_pkg="$2"; fi; shift 2;;
    --repair) repair=1; shift;;
    --help|-h) usage; exit 0;;
    *) usage; die "Unknown option: $1";;
  esac
done
retail="$(game_forced_or_auto "$game")" || die "HITMAN not found. Use --game with your HITMAN folder."
retail="$(canon_dir "$retail")" || die "Game folder cannot be accessed."
[[ -w "$retail" ]] || die "Cannot write to HITMAN Retail folder."
if command -v pgrep >/dev/null && pgrep -x 'HITMAN3.exe' >/dev/null 2>&1; then
  die "HITMAN appears to be running. Close it before changing mod files."
fi
if [[ -f "$MANIFEST" ]]; then
  if (( !repair )); then
    log "Artur Edition installation is already tracked; use verify.sh or repair.sh."
    bash "$DECK_ROOT/verify.sh" --game "$retail"
    exit $?
  fi
  [[ "$(saved_game)" == "$retail" ]] || die "Refusing repair of a different game folder."
fi
if [[ -z "$source_pkg" && -d "$DECK_ROOT/payload/Retail" ]]; then
  source_pkg="$DECK_ROOT/payload"
fi
[[ -n "$source_pkg" ]] || die "No runtime payload supplied. Use --package with the R2.18.1 Windows ZIP."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
payload="$(prepare_package "$source_pkg" "$tmp")" || die "Could not read the selected Windows release."
validate_payload "$payload" || die "Invalid Artur Edition runtime payload."
active_conflict "$retail/mods.ini" && die "Assassin Rivals 2 is enabled in mods.ini; disable it before installing."
# Preserve originals only on the initial installation, never rewrite rollback backups during repair.
if [[ -f "$MANIFEST" ]]; then
  backup="$(sed -n '1s/^BACKUP\t//p' "$MANIFEST")"
  [[ -d "$backup" ]] || die "Previous installation backup is missing; refusing unsafe repair."
else
  mkdir -p "$STATE_DIR/backups"
  backup="$(mktemp -d "$STATE_DIR/backups/original-XXXXXXXX")"
fi
# Stage exact resulting mods.ini before changing the game.
if [[ -f "$retail/mods.ini" ]]; then cp -p "$retail/mods.ini" "$tmp/mods.ini"
else : > "$tmp/mods.ini"; fi
if ! grep -Eiq '^[[:space:]]*\[HitmanCoop\][[:space:]]*$' "$tmp/mods.ini"; then
  printf '\n[HitmanCoop]\n' >> "$tmp/mods.ini"
fi
if [[ -f "$MANIFEST" ]]; then
  cp "$MANIFEST" "$tmp/old-manifest"
else
  {
    printf 'BACKUP\t%s\n' "$backup"
    for rel in "${FILES[@]}" mods.ini; do
      if [[ -f "$retail/$rel" ]]; then
        mkdir -p "$backup/$(dirname "$rel")"
        cp -p "$retail/$rel" "$backup/$rel"
        printf '%s\t1\t%s\n' "$rel" "$(hash_file "$retail/$rel")"
      else
        printf '%s\t0\t-\n' "$rel"
      fi
    done
  } > "$tmp/origins"
fi
# Stage a complete replacement and hashes; no unvalidated payload files copied.
mkdir -p "$tmp/stage/mods"
for rel in "${FILES[@]}"; do
  mkdir -p "$tmp/stage/$(dirname "$rel")"
  cp "$payload/$rel" "$tmp/stage/$rel"
done
cp "$tmp/mods.ini" "$tmp/stage/mods.ini"
# During repair ensure installed files weren't modified by unrelated software.
if [[ -f "$MANIFEST" ]]; then
  while IFS=$'\t' read -r rel expected origin; do
    [[ "$rel" == BACKUP ]] && continue
    if [[ -f "$retail/$rel" && "$(hash_file "$retail/$rel")" != "$expected" ]]; then
      die "File modified since installation: $rel. Refusing to overwrite it."
    fi
  done < "$MANIFEST"
fi
# Prepare rollback copy of currently installed files, including repair state.
mkdir -p "$tmp/before"
for rel in "${FILES[@]}" mods.ini; do
  if [[ -f "$retail/$rel" ]]; then
    mkdir -p "$tmp/before/$(dirname "$rel")"
    cp -p "$retail/$rel" "$tmp/before/$rel"
  fi
done
rollback() {
  local rel
  warn "Installation failed: restoring pre-installation files."
  for rel in "${FILES[@]}" mods.ini; do
    if [[ -f "$tmp/before/$rel" ]]; then
      cp -p "$tmp/before/$rel" "$retail/$rel" || true
    else
      rm -f "$retail/$rel" || true
    fi
  done
}
trap 'rollback; rm -rf "$tmp"' ERR
for rel in "${FILES[@]}" mods.ini; do
  mkdir -p "$retail/$(dirname "$rel")"
  cp -p "$tmp/stage/$rel" "$retail/$rel"
done
mkdir -p "$STATE_DIR"
new_manifest="$tmp/new-manifest"
printf 'BACKUP\t%s\n' "$backup" > "$new_manifest"
for rel in "${FILES[@]}" mods.ini; do
  if [[ -f "$tmp/origins" ]]; then origin="$(awk -F'\t' -v r="$rel" '$1==r{print $2}' "$tmp/origins")"
  else origin="$(awk -F'\t' -v r="$rel" '$1==r{print $3}' "$MANIFEST")"; fi
  printf '%s\t%s\t%s\n' "$rel" "$(hash_file "$retail/$rel")" "$origin" >> "$new_manifest"
done
cp "$new_manifest" "$MANIFEST.tmp"
mv -f "$MANIFEST.tmp" "$MANIFEST"
record_game "$retail"
trap - ERR
log "SUCCESS: Artur Edition R2.18.1 installed to $retail"
log "Original files backed up outside the game under $backup"
bash "$DECK_ROOT/verify.sh" --game "$retail"
