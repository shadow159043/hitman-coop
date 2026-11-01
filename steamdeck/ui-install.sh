#!/usr/bin/env bash
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$DECK_ROOT/lib/common.sh"
run_action() {
  local action="$1"
  if [[ "$action" == install ]]; then
    local package=""
    if [[ ! -d "$DECK_ROOT/payload/Retail" ]]; then
      if command -v kdialog >/dev/null; then
        package="$(kdialog --getopenfilename "$HOME/Downloads" '*.zip|Windows Artur Edition release ZIP' 2>/dev/null || true)"
      else
        read -r -p "Path to Windows Artur Edition R2.18.1 ZIP: " package
      fi
      [[ -n "$package" ]] || return 0
      bash "$DECK_ROOT/install.sh" --package "$package"
    else bash "$DECK_ROOT/install.sh"; fi
  else
    bash "$DECK_ROOT/$action.sh"
  fi
}
if command -v kdialog >/dev/null; then
  while true; do
    choice="$(kdialog --title 'Artur Edition — Steam Deck Mission Control' --menu 'Steam Deck / Proton (EXPERIMENTAL)'       install 'Install Artur Edition' verify 'Verify installation' launch 'Launch HITMAN through Steam'       repair 'Repair installed files' restore 'Restore previous files' uninstall 'Uninstall Artur Edition' quit 'Exit' 2>/dev/null || true)"
    [[ -n "$choice" && "$choice" != quit ]] || exit 0
    result="$(run_action "$choice" 2>&1)" && ok=1 || ok=0
    if ((ok)); then kdialog --title 'Artur Edition' --msgbox "$result"
    else kdialog --title 'Artur Edition — Error' --error "$result"; fi
  done
else
  while true; do
    printf '\nArtur Edition — Steam Deck Mission Control (EXPERIMENTAL)\n'
    printf '1 Install | 2 Verify | 3 Launch | 4 Repair | 5 Restore | 6 Uninstall | 7 Quit\n'
    read -r -p 'Choose: ' choice || exit 0
    case "$choice" in 1) run_action install;; 2) run_action verify;; 3) run_action launch;;
      4) run_action repair;; 5) run_action restore;; 6) run_action uninstall;; 7) exit 0;; *) warn "Invalid choice";;
    esac
  done
fi
