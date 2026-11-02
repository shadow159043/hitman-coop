#!/usr/bin/env bash
# Open Mission Control from the extracted ZIP without changing the current working directory.
set -euo pipefail
package_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
installer="$package_dir/steamdeck/ui-install.sh"

show_error() {
  local message="$1"
  if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && command -v kdialog >/dev/null 2>&1; then
    kdialog --title 'Artur Edition Installer' --error "$message" || true
  elif [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && command -v zenity >/dev/null 2>&1; then
    zenity --error --title='Artur Edition Installer' --text="$message" || true
  fi
  printf 'ERROR: %s\n' "$message" >&2
}

if [[ ! -f "$installer" ]]; then
  show_error 'Cannot find steamdeck/ui-install.sh. Extract the complete ZIP first, then open INSTALL-ARTUR-EDITION.desktop from the extracted folder.'
  exit 1
fi
if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  show_error 'Desktop Mode is required. Switch to Steam Deck Desktop Mode to open Mission Control.'
  exit 1
fi
if ! command -v kdialog >/dev/null 2>&1 && ! command -v zenity >/dev/null 2>&1; then
  show_error 'No graphical dialog tool found. Steam Deck KDE normally provides kdialog; on Ubuntu GNOME install zenity.'
  exit 1
fi
exec bash "$installer" --gui
