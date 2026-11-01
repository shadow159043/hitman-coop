#!/usr/bin/env bash
set -uo pipefail

# Simple command-line UI for Steam Deck desktop mode.
# This is intentionally lightweight and does not change the Windows codepath.

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

show_menu() {
  cat <<'EOF'
HITMAN Co-op — Artur Edition (Steam Deck / Proton)

1) Install Artur Edition
2) Verify installation
3) Launch HITMAN through Steam / Proton
4) Restore backup
5) Uninstall / restore backup
6) Exit
EOF
}

while true; do
  show_menu
  read -r -p "Select an option [1-6]: " choice || exit 0
  case "$choice" in
    1)
      "$STEAMDECK_ROOT/install.sh" --install
      ;;
    2)
      "$STEAMDECK_ROOT/verify.sh"
      ;;
    3)
      "$STEAMDECK_ROOT/launch.sh"
      ;;
    4)
      "$STEAMDECK_ROOT/restore.sh"
      ;;
    5)
      "$STEAMDECK_ROOT/uninstall.sh"
      ;;
    6)
      exit 0
      ;;
    *)
      warn "Invalid selection."
      ;;
  esac
  printf '\nPress Enter to continue.\n'
  read -r _ || true
  clear
done

