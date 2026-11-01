#!/usr/bin/env bash
# Shared helpers for the independent Artur Edition Steam Deck/Proton installer.
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP_ID=1659040
MOD_VERSION=0.12.21
SDK_VERSION=4.2.1
PROTOCOL_VERSION=16
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hitman-coop-artur-deck"
MANIFEST="$STATE_DIR/manifest.tsv"
GAME_PATH_FILE="$STATE_DIR/game-path"
FILES=(dinput8.dll ZHMModSDK.dll crashpad_handler.exe discord_game_sdk.dll ResourceLib_HM3.dll mods/HitmanCoop.dll)

log() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
hash_file() { sha256sum -- "$1" | cut -d' ' -f1; }
canon_dir() { (cd "$1" 2>/dev/null && pwd -P); }
retail_for() {
  local path="$1"
  if [[ -f "$path/Retail/HITMAN3.exe" ]]; then printf '%s\n' "$path/Retail"
  elif [[ -f "$path/HITMAN3.exe" ]]; then printf '%s\n' "$path"
  else return 1
  fi
}
saved_game() { [[ -f "$GAME_PATH_FILE" ]] && cat "$GAME_PATH_FILE"; }

steam_libraries() {
  local root f line path
  local -a roots=("$HOME/.steam/steam" "$HOME/.local/share/Steam" "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam")
  for root in "${roots[@]}"; do
    [[ -d "$root/steamapps" ]] && printf '%s\n' "$root/steamapps"
    f="$root/config/libraryfolders.vdf"
    [[ -f "$f" ]] || continue
    while IFS= read -r line; do
      if [[ "$line" =~ \"path\"[[:space:]]+\"([^\"]+)\" ]]; then
        path="${BASH_REMATCH[1]}"
        path="${path//\\\\/\\}"
        [[ -d "$path/steamapps" ]] && printf '%s\n' "$path/steamapps"
      fi
    done < "$f"
  done | awk '!seen[$0]++'
}
game_forced_or_auto() {
  local forced="${1:-}" path lib manifest dir line
  if [[ -n "$forced" ]]; then retail_for "$forced" && return 0; return 1; fi
  path="$(saved_game 2>/dev/null || true)"
  if [[ -n "$path" ]] && retail_for "$path" >/dev/null; then retail_for "$path"; return 0; fi
  while IFS= read -r lib; do
    [[ -n "$lib" ]] || continue
    manifest="$lib/appmanifest_${APP_ID}.acf"
    [[ -f "$manifest" ]] || continue
    dir=""
    while IFS= read -r line; do
      if [[ "$line" =~ \"installdir\"[[:space:]]+\"([^\"]+)\" ]]; then dir="${BASH_REMATCH[1]}"; fi
    done < "$manifest"
    [[ -n "$dir" ]] || continue
    path="$lib/common/$dir"
    if retail_for "$path" >/dev/null; then retail_for "$path"; return 0; fi
  done < <(steam_libraries)
  return 1
}
# Accept a release extraction with or without the top-level release folder.
payload_retail() {
  local base="$1" hit
  if [[ -f "$base/Retail/mods/HitmanCoop.dll" ]]; then printf '%s\n' "$base/Retail"; return 0; fi
  if [[ -f "$base/mods/HitmanCoop.dll" ]]; then printf '%s\n' "$base"; return 0; fi
  hit="$(find "$base" -maxdepth 5 -type f -path '*/Retail/mods/HitmanCoop.dll' -print -quit 2>/dev/null)"
  [[ -n "$hit" ]] || return 1
  printf '%s\n' "${hit%/mods/HitmanCoop.dll}"
}
validate_payload() {
  local retail="$1" item
  for item in "${FILES[@]}"; do
    [[ -f "$retail/$item" && ! -L "$retail/$item" && -s "$retail/$item" ]] || { warn "Missing or unsafe release file: $item"; return 1; }
  done
  if [[ -f "$retail/../SHA256SUMS.txt" ]]; then
    # The upstream checksum file has Windows-style separators, and is not relied on
    # as a proof of identity unless the optional packaged runtime checksums validate.
    :
  fi
  local checks="$retail/../RUNTIME-SHA256SUMS.txt" line sha rel actual
  if [[ -f "$checks" ]]; then
    while IFS=$'\t' read -r sha rel; do
      rel="${rel%$'\r'}"
      [[ -n "$rel" ]] || continue
      [[ "$rel" != /* && "$rel" != *..* ]] || { warn "Unsafe checksum entry: $rel"; return 1; }
      [[ -f "$retail/$rel" ]] || { warn "Checksum file not found: $rel"; return 1; }
      actual="$(hash_file "$retail/$rel")"
      [[ "$actual" == "$sha" ]] || { warn "Payload hash mismatch: $rel"; return 1; }
    done < "$checks"
  fi
}
active_conflict() {
  local ini="$1"
  [[ -f "$ini" ]] || return 1
  grep -Eiq '^[[:space:]]*\[AssassinRivals2\][[:space:]]*([;#].*)?$' "$ini"
}
prepare_package() {
  local source="$1" tmp="$2" extracted
  [[ -e "$source" ]] || die "Package not found: $source"
  if [[ -d "$source" ]]; then payload_retail "$source"
  elif [[ "$source" == *.zip ]]; then
    command -v python3 >/dev/null || die "Python 3 is required to import a Windows release ZIP."
    mkdir -p "$tmp/extracted"
    python3 "$DECK_ROOT/lib/extract_release.py" "$source" "$tmp/extracted" || return 1
    payload_retail "$tmp/extracted"
  else die "Expected an extracted release directory or a .zip package."; fi
}
record_game() { mkdir -p "$STATE_DIR"; printf '%s\n' "$1" > "$GAME_PATH_FILE"; }
