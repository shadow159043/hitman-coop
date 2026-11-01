#!/usr/bin/env bash
set -uo pipefail

# Common helpers for the Steam Deck / Proton compatibility package.
# This code intentionally does not redefine the Windows multiplayer implementation.

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

die() {
  fail "$*"
}

find_steam_libraries() {
  local root
  for root in \
    "$HOME/.steam/steam/steamapps" \
    "$HOME/.local/share/Steam/steamapps" \
    "$HOME/Steam/steamapps" \
    "/home/deck/.steam/steam/steamapps" \
    "/home/deck/.local/share/Steam/steamapps" \
    "/var/lib/steam/steamapps";
  do
    if [[ -d "$root" ]]; then
      printf '%s\n' "$root"
    fi
  done
}

find_steam_root() {
  local root
  for root in \
    "$HOME/.steam/steam" \
    "$HOME/.local/share/Steam/steam" \
    "$HOME/Steam" \
    "/home/deck/.steam/steam" \
    "/home/deck/.local/share/Steam/steam" \
    "/var/lib/steam";
  do
    if [[ -d "$root" ]]; then
      printf '%s\n' "$root"
    fi
  done
}

find_hitman_executable() {
  local game_root="${1:-}"
  local candidate
  if [[ -z "$game_root" ]]; then
    return 1
  fi
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

detect_hitman_root() {
  local forced="${1:-}"
  if [[ -n "$forced" ]]; then
    if [[ -d "$forced" ]]; then
      printf '%s\n' "$forced"
      return 0
    fi
    if [[ -d "$forced/Retail" ]]; then
      printf '%s\n' "$forced/Retail"
      return 0
    fi
  fi
  local lib
  local candidate
  for lib in $(find_steam_libraries); do
    for candidate in \
      "$lib/common/HITMAN 3" \
      "$lib/common/HITMAN World of Assassination" \
      "$lib/common/HITMAN 3/Retail" \
      "$lib/common/HITMAN World of Assassination/Retail"; do
      if [[ -d "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  done
  for candidate in \
    "$HOME/Games/HITMAN" \
    "$HOME/Games/HITMAN 3" \
    "$HOME/HITMAN" \
    "$HOME/HITMAN 3" \
    "/mnt/ssd/steamapps/common/HITMAN World of Assassination" \
    "/run/media/mmcblk0p1/steamapps/common/HITMAN World of Assassination"; do
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

detect_release_package() {
  local forced="${1:-}"
  if [[ -n "$forced" ]]; then
    if [[ -d "$forced" ]]; then
      printf '%s\n' "$forced"
      return 0
    fi
  fi
  local pkg
  for pkg in \
    "$STEAMDECK_ROOT/../artifacts" \
    "$STEAMDECK_ROOT/../dist" \
    "$STEAMDECK_ROOT/../release" \
    "$STEAMDECK_ROOT/../releases" \
    "$STEAMDECK_ROOT/../windows" \
    "$STEAMDECK_ROOT/../artur-edition" \
    "$STEAMDECK_ROOT/../HITMAN-Coop-Artur-Edition" \
    "$STEAMDECK_ROOT/../HITMAN-Coop-Artur-Edition-R2.18.1" \
    "$STEAMDECK_ROOT/../HITMAN-Coop-Artur-Edition-Release"; do
    if [[ -d "$pkg" ]]; then
      printf '%s\n' "$pkg"
      return 0
    fi
  done
  return 1
}

find_support_files() {
  local base="${1:-}"
  local item
  for item in "$base"/*; do
    if [[ -e "$item" ]]; then
      printf '%s\n' "$item"
    fi
  done
}

detect_proton_bin() {
  local forced="${1:-}"
  if [[ -n "$forced" && -x "$forced" ]]; then
    printf '%s\n' "$forced"
    return 0
  fi
  local candidate
  for candidate in \
    "$HOME/.steam/steam/steamapps/common/Proton - Experimental/proton" \
    "$HOME/.steam/steam/steamapps/common/Proton 9/proton" \
    "$HOME/.local/share/Steam/steamapps/common/Proton - Experimental/proton" \
    "$HOME/.local/share/Steam/steamapps/common/Proton 9/proton" \
    "/usr/bin/steam-run" \
    "/usr/bin/proton" \
    "/home/deck/.steam/steam/steamapps/common/Proton - Experimental/proton" \
    "/home/deck/.local/share/Steam/steamapps/common/Proton - Experimental/proton"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

detect_steam_bin() {
  local forced="${1:-}"
  if [[ -n "$forced" && -x "$forced" ]]; then
    printf '%s\n' "$forced"
    return 0
  fi
  local candidate
  for candidate in \
    "$HOME/.steam/steam/steam" \
    "$HOME/.local/share/Steam/steam" \
    "/usr/bin/steam" \
    "/home/deck/.steam/steam/steam" \
    "/home/deck/.local/share/Steam/steam"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

make_backup_dir() {
  local target="${1:-}"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  local backup_dir="${target%/}/HitmanCoop-Backup-${stamp}"
  mkdir -p "$backup_dir"
  printf '%s\n' "$backup_dir"
}

backup_existing_install() {
  local game_root="${1:-}"
  local backup_dir
  local retail_dir="$game_root"
  if [[ -d "$game_root/Retail" ]]; then
    retail_dir="$game_root/Retail"
  fi
  backup_dir="$(make_backup_dir "$retail_dir")"
  if [[ ! -d "$retail_dir" ]]; then
    warn "The installation directory does not exist: $retail_dir"
    return 1
  fi
  for item in "$retail_dir"/*; do
    if [[ -e "$item" ]]; then
      cp -a "$item" "$backup_dir/"
    fi
  done
  log "Backup created at: $backup_dir"
  printf '%s\n' "$backup_dir"
}

install_artur_edition() {
  local game_root="${1:-}"
  local package_dir="${2:-}"
  local retail_dir="$game_root"
  if [[ -d "$game_root/Retail" ]]; then
    retail_dir="$game_root/Retail"
  fi
  if [[ ! -d "$retail_dir" ]]; then
    die "Cannot install into missing Retail directory: $retail_dir"
  fi
  if [[ ! -d "$package_dir" ]]; then
    die "Package directory not found: $package_dir"
  fi

  local item
  local copied=0
  for item in $(find_support_files "$package_dir"); do
    local name
    name="$(basename "$item")"
    case "$name" in
      *.dll|*.asi|*.exe|*.cfg|*.ini|*.json|*.txt|*.md|*.log|*.pak)
        cp -a "$item" "$retail_dir/"
        copied=$((copied + 1))
        ;;
      *)
        ;;
    esac
  done

  if [[ "$copied" -eq 0 ]]; then
    warn "No installable Artur Edition files were found in the package directory: $package_dir"
    warn "Expected a release bundle containing Windows mod DLLs or a pre-extracted Artur Edition install folder."
    return 1
  fi

  log "Installed Artur Edition compatibility files to: $retail_dir"
  return 0
}

verify_installation() {
  local game_root="${1:-}"
  local package_dir="${2:-}"
  local retail_dir="$game_root"
  if [[ -d "$game_root/Retail" ]]; then
    retail_dir="$game_root/Retail"
  fi
  if [[ ! -f "$retail_dir/HITMAN3.exe" ]]; then
    printf 'FAIL: HITMAN3.exe not found under %s\n' "$retail_dir" >&2
    return 1
  fi

  local installed=0
  local file
  for file in "$retail_dir"/*; do
    if [[ -e "$file" ]]; then
      case "$(basename "$file")" in
        *Coop*|*ZHM*|*ModSDK*|*dll|*asi|*exe)
          installed=$((installed + 1))
          ;;
      esac
    fi
  done

  if [[ "$installed" -eq 0 ]]; then
    printf 'FAIL: no Artur Edition mod markers were found under %s\n' "$retail_dir" >&2
    return 1
  fi

  if [[ -n "$package_dir" && -d "$package_dir" ]]; then
    local expected=0
    for file in "$package_dir"/*; do
      if [[ -e "$file" ]]; then
        case "$(basename "$file")" in
          *.dll|*.asi|*.exe|*.cfg|*.ini|*.json|*.txt|*.md)
            expected=$((expected + 1))
            ;;
        esac
      fi
    done
    if [[ "$expected" -eq 0 ]]; then
      warn "Artur Edition package directory exists but appears empty or not packaged with installable files."
    fi
  fi

  log "Verification passed: HITMAN installation and Artur Edition mod files appear present."
  return 0
}

restore_backup() {
  local game_root="${1:-}"
  local retail_dir="$game_root"
  if [[ -d "$game_root/Retail" ]]; then
    retail_dir="$game_root/Retail"
  fi
  local newest
  newest="$(find "$retail_dir" -maxdepth 1 -type d -name 'HitmanCoop-Backup-*' 2>/dev/null | sort | tail -n 1)"
  if [[ -z "$newest" ]]; then
    warn "No backup directory was found under $retail_dir. Nothing to restore."
    return 1
  fi
  log "Restoring the most recent backup from $newest"
  find "$newest" -mindepth 1 -maxdepth 1 -exec cp -a {} "$retail_dir/" \;
  return 0
}

