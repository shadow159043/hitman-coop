#!/usr/bin/env bash
# Steam Deck Mission Control: KDE and GNOME graphical dialogs, terminal fallback.
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$DECK_ROOT/lib/common.sh"
TITLE="HITMAN Co-op - Artur Edition | Mission Control (EXPERIMENTAL)"
MODE="${ARTUR_UI_BACKEND:-auto}"
STATUS_ONLY=0
usage() {
  cat <<'EOF'
Usage: bash steamdeck/ui-install.sh [--gui|--terminal|--status|--help]
  --gui        Require KDE kdialog or GNOME Zenity and a graphical session
  --terminal   Use the text menu even when graphical dialogs are installed
  --status     Print read-only installation status
Steam Deck KDE uses kdialog; Ubuntu GNOME uses zenity (sudo apt install zenity).
Opening Mission Control never installs or changes the game automatically.
EOF
}
while (($#)); do
  case "$1" in
    --gui) MODE=required;; --terminal) MODE=terminal;;
    --status) STATUS_ONLY=1;; -h|--help) usage; exit 0;;
    *) usage >&2; die "Unknown option: $1";;
  esac
  shift
done
status_text() {
  local retail state payload
  retail="$(game_forced_or_auto "" 2>/dev/null || true)"
  if [[ -f "$MANIFEST" ]]; then
    if [[ -n "$retail" ]] && bash "$DECK_ROOT/verify.sh" --game "$retail" >/dev/null 2>&1; then
      state="Installed; file verification passed"
    else state="Install tracked; repair or game detection required"; fi
  else state="Not installed by Artur Edition"; fi
  if [[ -d "$DECK_ROOT/payload/Retail" ]]; then
    payload="Complete offline R2.18.1 runtime present"
  else payload="Installer only; matching Windows release ZIP required"; fi
  printf 'Steam Deck / Proton: EXPERIMENTAL\n'
  printf 'HITMAN: %s\n' "${retail:-Not detected (manual selection available)}"
  printf 'Artur Edition: %s\n' "$state"
  printf 'Runtime: %s\n' "$payload"
  printf 'Version: R2.18.1 / 0.12.21 | SDK 4.2.1 | Protocol 16\n'
  printf 'Steam App ID: 1659040\n'
  printf 'Proton DLL loading and cross-platform multiplayer: UNTESTED'
}
if ((STATUS_ONLY)); then status_text; exit 0; fi
if [[ "$MODE" == terminal ]]; then
  BACKEND=terminal
elif [[ "$MODE" == kdialog || "$MODE" == zenity ]]; then
  command -v "$MODE" >/dev/null || die "Missing dialog program: $MODE"
  BACKEND="$MODE"
elif [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] && command -v kdialog >/dev/null; then BACKEND=kdialog
  elif command -v zenity >/dev/null; then BACKEND=zenity
  elif command -v kdialog >/dev/null; then BACKEND=kdialog
  else BACKEND=terminal; fi
else BACKEND=terminal; fi
if [[ "$MODE" == required && "$BACKEND" == terminal ]]; then
  die "Graphical dialogs unavailable. For Ubuntu: sudo apt install zenity; for Steam Deck use kdialog."
fi

dialog_info() {
  case "$BACKEND" in
    kdialog) kdialog --title "$TITLE" --msgbox "$1";;
    zenity) zenity --info --title="$TITLE" --width=650 --text="$1";;
    terminal) printf '%s\n' "$1";;
  esac
}
dialog_error() {
  case "$BACKEND" in
    kdialog) kdialog --title "$TITLE" --error "$1";;
    zenity) zenity --error --title="$TITLE" --width=650 --text="$1";;
    terminal) printf 'ERROR: %s\n' "$1" >&2;;
  esac
}
dialog_confirm() {
  case "$BACKEND" in
    kdialog) kdialog --title "$TITLE" --yesno "$1";;
    zenity) zenity --question --title="$TITLE" --width=650 --text="$1";;
    terminal)
      local answer=""
      read -r -p "$1 [y/N]: " answer || return 1
      [[ "$answer" == y || "$answer" == Y || "$answer" == yes || "$answer" == YES ]]
      ;;
  esac
}
menu_action() {
  local choice=""
  case "$BACKEND" in
    kdialog)
      choice="$(kdialog --title "$TITLE" --menu "$(status_text)" \
        install 'Install Artur Edition' verify 'Verify installed files' \
        launch 'Launch HITMAN through Steam' repair 'Repair installation' \
        restore 'Restore original files' uninstall 'Uninstall Artur Edition' \
        status 'View compatibility status' help 'Read installation help' \
        quit 'Exit' 2>/dev/null)" || return 1 ;;
    zenity)
      choice="$(zenity --list --title="$TITLE" --width=800 --height=560 \
        --text="$(status_text)" --column='Action' --column='Description' --print-column=1 \
        install 'Install Artur Edition R2.18.1' verify 'Verify installed files' \
        launch 'Launch HITMAN via official Steam entry' repair 'Repair installation' \
        restore 'Restore original files' uninstall 'Uninstall Artur Edition' \
        status 'View compatibility status' help 'Read installation help' \
        quit 'Exit Mission Control' 2>/dev/null)" || return 1 ;;
    terminal)
      printf '\n%s\n' "$(status_text)" >&2
      printf '\n1 Install | 2 Verify | 3 Launch | 4 Repair | 5 Restore | 6 Uninstall | 7 Status | 8 Help | 9 Quit\n' >&2
      read -r -p 'Choose: ' choice || return 1
      case "$choice" in
        1) choice=install;; 2) choice=verify;; 3) choice=launch;;
        4) choice=repair;; 5) choice=restore;; 6) choice=uninstall;;
        7) choice=status;; 8) choice=help;; 9) choice=quit;;
        *) choice=invalid;;
      esac ;;
  esac
  printf '%s\n' "$choice"
}
choose_game() {
  local selected=""
  case "$BACKEND" in
    kdialog) selected="$(kdialog --title "$TITLE" --getexistingdirectory "$HOME" 2>/dev/null)" || return 1;;
    zenity) selected="$(zenity --file-selection --directory --title='Select HITMAN game folder' --filename="$HOME/" 2>/dev/null)" || return 1;;
    terminal) read -r -p 'HITMAN folder (blank cancels): ' selected || return 1;;
  esac
  [[ -n "$selected" ]] || return 1
  if ! retail_for "$selected" >/dev/null; then
    dialog_error 'The selected folder does not contain HITMAN3.exe (or Retail/HITMAN3.exe).' >&2
    return 1
  fi
  printf '%s\n' "$selected"
}
choose_package() {
  local selected=""
  case "$BACKEND" in
    kdialog) selected="$(kdialog --title "$TITLE" --getopenfilename "$HOME/Downloads" '*.zip|Windows Artur Edition ZIP' 2>/dev/null)" || return 1;;
    zenity) selected="$(zenity --file-selection --title='Select Artur Edition Windows release ZIP' --filename="$HOME/Downloads/" --file-filter='Windows release ZIP | *.zip' 2>/dev/null)" || return 1;;
    terminal) read -r -p 'Windows R2.18.1 release ZIP (blank cancels): ' selected || return 1;;
  esac
  [[ -n "$selected" ]] || return 1
  if [[ ! -f "$selected" ]]; then dialog_error "File not found: $selected" >&2; return 1; fi
  printf '%s\n' "$selected"
}
show_output() {
  local file="$1" good="$2"
  if [[ "$BACKEND" == terminal ]]; then cat "$file"; return; fi
  if [[ "$good" == 0 ]]; then dialog_error 'Action failed. Review the log in the next window.' || true; fi
  case "$BACKEND" in
    kdialog) kdialog --title "$TITLE - results" --textbox "$file" 780 500;;
    zenity) zenity --text-info --title="$TITLE - results" --filename="$file" --width=780 --height=500;;
  esac
}
read_help() {
  local file="$DECK_ROOT/README.md"
  if [[ "$BACKEND" == terminal ]]; then
    printf 'Open %s for full help.\n' "$file"
  elif [[ "$BACKEND" == kdialog ]]; then
    kdialog --title 'Artur Edition - Help' --textbox "$file" 780 560
  else
    zenity --text-info --title='Artur Edition - Help' --filename="$file" --width=780 --height=560
  fi
}
perform_action() {
  local action="$1" retail="" package="" logfile="" passed=0
  local -a args=()
  case "$action" in
    status) dialog_info "$(status_text)"; return;;
    help) read_help; return;;
    invalid) dialog_error 'Please choose a listed action.'; return;;
    install|verify|repair|restore|uninstall|launch) ;;
    *) dialog_error "Unknown action: $action"; return;;
  esac
  if [[ "$action" == launch ]]; then
    dialog_confirm 'Launch the official Steam game (App ID 1659040)?' || return 0
  else
    retail="$(game_forced_or_auto "" 2>/dev/null || true)"
    if [[ -z "$retail" ]]; then
      if [[ "$action" != install && ! -f "$MANIFEST" ]]; then
        dialog_error 'There is no tracked installation yet. Install Artur Edition first.'
        return
      fi
      retail="$(choose_game)" || return 0
    fi
    args+=(--game "$retail")
  fi
  case "$action" in
    install|repair)
      if [[ "$action" == repair && ! -f "$MANIFEST" ]]; then
        dialog_error 'No tracked installation exists to repair.'; return
      fi
      if [[ -d "$DECK_ROOT/payload/Retail" ]]; then
        package="$DECK_ROOT/payload"
      else package="$(choose_package)" || return 0; fi
      args+=(--package "$package")
      if [[ "$action" == install ]]; then
        dialog_confirm "Install Artur Edition into:
$retail

Original files will be backed up outside HITMAN." || return 0
      else
        dialog_confirm 'Repair Artur Edition files? Modified files are protected.' || return 0
      fi ;;
    restore|uninstall)
      dialog_confirm "Restore pre-installation files and remove Artur Edition components from:
$retail" || return 0 ;;
  esac
  logfile="$(mktemp)"
  if bash "$DECK_ROOT/$action.sh" "${args[@]}" >"$logfile" 2>&1; then passed=1; fi
  if [[ "$action" == launch && "$passed" == 1 ]]; then
    printf '\nSteam launch requested; game startup is not yet verified.\n' >>"$logfile"
  fi
  show_output "$logfile" "$passed" || true
  rm -f "$logfile"
}
while true; do
  action="$(menu_action)" || break
  [[ -n "$action" && "$action" != quit ]] || break
  perform_action "$action"
done
