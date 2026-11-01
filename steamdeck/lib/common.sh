#!/usr/bin/env bash
set -uo pipefail

# Shared state and helper functions for the Steam Deck / Proton compatibility package.
# This package intentionally wraps the existing Windows Artur Edition installation.
# It does not rewrite the Windows multiplayer engine or modify other Windows files.

HITMAN_COOP_APP_ID="1659040"
HITMAN_COOP_REQUIRED_GAME_VERSION="3.290.1.0"
HITMAN_COOP_REQUIRED_SDK_VERSION="4.2.1"
HITMAN_COOP_PROTOCOL_VERSION="16"
HITMAN_COOP_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hitman-coop-steamdeck"
HITMAN_COOP_BACKUP_ROOT="$HITMAN_COOP_STATE_DIR/backups"
HITMAN_COOP_MANIFEST="$HITMAN_COOP_STATE_DIR/install-manifest.tsv"

mkdir -p "$HITMAN_COOP_STATE_DIR" "$HITMAN_COOP_BACKUP_ROOT"

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

error() {
  printf 'ERROR: %s\n' "$*" >&2
}

die() {
  error "$*"
  exit 1
}

trim() {
  local value="${1:-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

save_install_meta() {
  local game_root="${1:-}"
  local package_root="${2:-}"
  local backup_dir="${3:-}"
  local stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local manifest_dir
  manifest_dir="$(dirname "$HITMAN_COOP_MANIFEST")"
  mkdir -p "$manifest_dir"
  {
    printf '%s\t%s\t%s\t%s\n' "$stamp" "$game_root" "$package_root" "$backup_dir"
  } > "$HITMAN_COOP_MANIFEST"
}

read_install_meta() {
  if [[ -f "$HITMAN_COOP_MANIFEST" ]]; then
    tail -n 1 "$HITMAN_COOP_MANIFEST"
  fi
}

get_steam_library_roots() {
  local steam_root candidate libfile
  local -a roots=()
  for steam_root in \
    "$HOME/.steam/steam" \
    "$HOME/.local/share/Steam/steam" \
    "$HOME/Steam" \
    "/home/deck/.steam/steam" \
    "/home/deck/.local/share/Steam/steam" \
    "/var/lib/steam"; do
    if [[ -d "$steam_root" ]]; then
      roots+=("$steam_root")
    fi
  done

  for steam_root in "${roots[@]}"; do
    libfile="$steam_root/config/libraryfolders.vdf"
    if [[ -f "$libfile" ]]; then
      while IFS= read -r line; do
        if [[ "$line" =~ \"path\"[[:space:]]+\"(.*)\" ]]; then
          candidate="${BASH_REMATCH[1]}"
          candidate="${candidate//\\/}"
          if [[ -n "$candidate" && -d "$candidate/steamapps" ]]; then
            printf '%s\n' "$candidate/steamapps"
          fi
        fi
      done < "$libfile"
    fi
    if [[ -d "$steam_root/steamapps" ]]; then
      printf '%s\n' "$steam_root/steamapps"
    fi
  done | awk '!seen[$0]++'
}

find_steam_game_manifest() {
  local target_dir="${1:-}"
  local manifest_path
  if [[ -n "$target_dir" ]]; then
    manifest_path="$target_dir/appmanifest_1659040.acf"
    if [[ -f "$manifest_path" ]]; then
      printf '%s\n' "$manifest_path"
      return 0
    fi
  fi
  local library_root
  while IFS= read -r library_root; do
    [[ -n "$library_root" ]] || continue
    manifest_path="$library_root/appmanifest_1659040.acf"
    if [[ -f "$manifest_path" ]]; then
      printf '%s\n' "$manifest_path"
      return 0
    fi
  done < <(get_steam_library_roots)
  return 1
}

resolve_installdir_from_manifest() {
  local manifest_path="${1:-}"
  local install_dir=""
  if [[ -n "$manifest_path" && -f "$manifest_path" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ \"installdir\"[[:space:]]+\"(.*)\" ]]; then
        install_dir="${BASH_REMATCH[1]}"
      fi
    done < "$manifest_path"
    if [[ -n "$install_dir" ]]; then
      printf '%s\n' "$(dirname "$manifest_path")/common/$install_dir"
      return 0
    fi
  fi
  return 1
}

find_hitman_executable() {
  local game_root="${1:-}"
  if [[ -z "$game_root" ]]; then
    return 1
  fi
  local candidate
  for candidate in \
    "$game_root/HITMAN3.exe" \
    "$game_root/Retail/HITMAN3.exe" \
    "$game_root/retail/HITMAN3.exe" \
    "$game_root/steamapps/common/HITMAN World of Assassination/Retail/HITMAN3.exe" \
    "$game_root/steamapps/common/HITMAN 3/Retail/HITMAN3.exe"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

resolve_game_root() {
  local forced="${1:-}"
  local path candidate
  if [[ -n "$forced" ]]; then
    if [[ -d "$forced" ]]; then
      if [[ -f "$forced/HITMAN3.exe" || -f "$forced/Retail/HITMAN3.exe" ]]; then
        printf '%s\n' "$forced"
        return 0
      fi
    fi
  fi

  local manifest_path
  manifest_path="$(find_steam_game_manifest "")" || true
  if [[ -n "$manifest_path" ]]; then
    path="$(resolve_installdir_from_manifest "$manifest_path")" || true
    if [[ -n "$path" && -d "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  fi

  local -a candidate_dirs=(
    "$HOME/Games/HITMAN" \
    "$HOME/Games/HITMAN 3" \
    "$HOME/HITMAN" \
    "$HOME/HITMAN 3" \
    "/mnt/ssd/steamapps/common/HITMAN World of Assassination" \
    "/mnt/ssd/steamapps/common/HITMAN 3" \
    "/run/media/mmcblk0p1/steamapps/common/HITMAN World of Assassination" \
    "/run/media/mmcblk0p1/steamapps/common/HITMAN 3"
  )
  for path in "${candidate_dirs[@]}"; do
    if [[ -d "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 1
}

resolve_package_root() {
  local forced="${1:-}"
  local candidate
  if [[ -n "$forced" ]]; then
    if [[ -d "$forced" ]]; then
      printf '%s\n' "$forced"
      return 0
    fi
  fi

  local -a package_dirs=(
    "$PWD" \
    "$PWD/steamdeck" \
    "$PWD/steamdeck/package" \
    "$PWD/../package" \
    "$PWD/../dist" \
    "$PWD/../_dist" \
    "$HOME/Downloads" \
    "$HOME/Desktop" \
    "/tmp" \
    "/mnt/data"
  )
  for candidate in "${package_dirs[@]}"; do
    if [[ -d "$candidate" ]]; then
      if [[ -d "$candidate/Retail" || -d "$candidate/retail" || -d "$candidate/files/Retail" || -d "$candidate/files/retail" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

copy_if_present() {
  local src="${1:-}"
  local dst="${2:-}"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
  fi
}

create_backup_dir() {
  local stamp
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  local backup_dir="$HITMAN_COOP_BACKUP_ROOT/HitmanCoop-${stamp}"
  mkdir -p "$backup_dir"
  printf '%s\n' "$backup_dir"
}

backup_existing_install() {
  local game_root="${1:-}"
  local retail_dir="$game_root"
  if [[ -d "$game_root/Retail" ]]; then
    retail_dir="$game_root/Retail"
  fi
  local backup_dir
  backup_dir="$(create_backup_dir)"
  if [[ ! -d "$retail_dir" ]]; then
    warn "No valid Retail directory found at $retail_dir"
    return 1
  fi

  local -a files_to_backup=(
    "$retail_dir/dinput8.dll" \
    "$retail_dir/ZHMModSDK.dll" \
    "$retail_dir/mods.ini" \
    "$retail_dir/mods" \
    "$retail_dir/mods/HitmanCoop.dll"
  )

  local item
  for item in "${files_to_backup[@]}"; do
    if [[ -e "$item" ]]; then
      local relative_name="${item#$retail_dir/}"
      if [[ "$relative_name" == "$item" ]]; then
        continue
      fi
      local dest_path="$backup_dir/$relative_name"
      mkdir -p "$(dirname "$dest_path")"
      cp -a "$item" "$dest_path"
    fi
  done

  log "Backup created at: $backup_dir"
  save_install_meta "$game_root" "$retail_dir" "$backup_dir"
  printf '%s\n' "$backup_dir"
  return 0
}

restore_backup() {
  local game_root="${1:-}"
  local retail_dir="$game_root"
  if [[ -d "$game_root/Retail" ]]; then
    retail_dir="$game_root/Retail"
  fi

  local newest
  newest="$(find "$HITMAN_COOP_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1)"
  if [[ -z "$newest" ]]; then
    warn "No Steam Deck backup exists in $HITMAN_COOP_BACKUP_ROOT"
    return 1
  fi
  shopt -s dotglob
  local entry
  for entry in "$newest"/*; do
    if [[ -e "$entry" ]]; then
      local name="$(basename "$entry")"
      if [[ -d "$entry" ]]; then
        mkdir -p "$retail_dir/$name"
        cp -a "$entry"/. "$retail_dir/$name/"
      else
        cp -a "$entry" "$retail_dir/"
      fi
    fi
  done
  shopt -u dotglob
  log "Restored backup from: $newest"
  return 0
}

check_required_artur_files() {
  local retail_dir="${1:-}"
  local -a required=(
    "$retail_dir/HITMAN3.exe" \
    "$retail_dir/dinput8.dll" \
    "$retail_dir/ZHMModSDK.dll" \
    "$retail_dir/mods/HitmanCoop.dll" \
    "$retail_dir/mods.ini"
  )
  local item
  for item in "${required[@]}"; do
    if [[ ! -f "$item" ]]; then
      printf '%s\n' "$item" >&2
      return 1
    fi
  done
  return 0
}

verify_installation() {
  local game_root="${1:-}"
  local package_root="${2:-}"
  local retail_dir="$game_root"
  if [[ -d "$game_root/Retail" ]]; then
    retail_dir="$game_root/Retail"
  fi

  if [[ ! -f "$retail_dir/HITMAN3.exe" ]]; then
    warn "Missing HITMAN3.exe in $retail_dir"
    return 1
  fi

  if ! check_required_artur_files "$retail_dir"; then
    warn "Required Artur Edition files are missing from $retail_dir"
    return 1
  fi

  if [[ -n "$package_root" && -d "$package_root" ]]; then
    local source_root="$package_root"
    if [[ -d "$source_root/Retail" ]]; then
      source_root="$source_root/Retail"
    elif [[ -d "$source_root/retail" ]]; then
      source_root="$source_root/retail"
    elif [[ -d "$source_root/files/Retail" ]]; then
      source_root="$source_root/files/Retail"
    elif [[ -d "$source_root/files/retail" ]]; then
      source_root="$source_root/files/retail"
    fi
    if [[ -f "$source_root/dinput8.dll" && -f "$source_root/ZHMModSDK.dll" && -f "$source_root/mods/HitmanCoop.dll" ]]; then
      log "Package identity looks consistent with the Artur Edition R2.18.1 layout."
    else
      warn "Package bundle does not appear to contain the expected Artur Edition Windows payload."
      return 1
    fi
  fi

  log "Verification passed: Steam Deck compatibility installation appears valid."
  return 0
}

