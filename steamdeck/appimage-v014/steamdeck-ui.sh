#!/usr/bin/env bash
# Artur Edition v0.14.4 Steam Deck graphical Mission Control. Bundled source stays read-only.
# Never installs anything until user clicks Install; never touches unrelated game folders.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
installer="$root/installer.sh"
updater="$root/steamdeck-updater.sh"
title="HITMAN Co-op - Artur Edition 0.14.4 | Mission Control (EXPERIMENTAL)"
[[ -f "$installer" && -f "$root/files/mods/HitmanCoop.dll" ]] ||
  { echo "Missing bundled Artur 0.14.4 Linux runtime" >&2; exit 1; }
mode=auto
case "${1:-}" in
  --status) mode=status ;;
  --selftest-update) exec bash "$updater" --selftest ;;
  --terminal) mode=terminal ;;
  --gui|'') mode=auto ;;
  --help|-h) echo "Usage: AppImage [--status|--gui|--terminal]"; exit 0 ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac
status_text() {
  local game=""
  game="$(bash "$installer" --list-games 2>/dev/null | head -n 1 || true)"
  printf 'Artur Edition 0.14.4 / protocol 21 - Steam Deck / Proton EXPERIMENTAL\n'
  printf 'Offline v0.14.4 payload: ready (game 3.290 and 3.280)\n'
  if [[ -n "$game" ]]; then
    printf 'Detected HITMAN folder: %s\n' "$game"
    if [[ -f "$game/Retail/mods/HitmanCoop.dll" ]]; then
      printf 'Existing mod: present (choose Verify to check exact files)\n'
    else
      printf 'Existing mod: not found\n'
    fi
  else
    printf 'Detected HITMAN folder: not found (manual selection offered during Install)\n'
  fi
  printf 'Use Check updates to download a newer verified AppImage, if one exists.\n'
  printf 'This is an installer, not proof that HITMAN or multiplayer works on Steam Deck.\n'
}
if [[ "$mode" == status ]]; then status_text; exit 0; fi
backend=terminal
if [[ "$mode" != terminal && -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  if command -v kdialog >/dev/null 2>&1; then backend=kdialog
  elif command -v zenity >/dev/null 2>&1; then backend=zenity
  fi
fi
if [[ "$mode" == auto && "$backend" == terminal && -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  echo "No KDE kdialog or Zenity available. Use the manual Linux tarball installer or --terminal." >&2
  exit 1
fi
ask() {
  case "$backend" in
    kdialog) kdialog --title "$title" --yesno "$1" ;;
    zenity) zenity --title="$title" --question --width=560 --text="$1" ;;
    terminal) local reply=""; read -r -p "$1 [y/N] " reply; [[ "$reply" == [yY]* ]] ;;
  esac
}
message() {
  case "$backend" in
    kdialog) kdialog --title "$title" --msgbox "$1" ;;
    zenity) zenity --title="$title" --info --width=600 --text="$1" ;;
    terminal) printf '%s\n' "$1" ;;
  esac
}
show_results() {
  local logfile="$1" ok="$2"
  if [[ "$ok" != 1 ]]; then message "The action failed. See the next window for details." || true; fi
  case "$backend" in
    kdialog) kdialog --title "$title - results" --textbox "$logfile" 800 520 ;;
    zenity) zenity --title="$title - results" --text-info --filename="$logfile" --width=800 --height=520 ;;
    terminal) cat "$logfile" ;;
  esac
}
choose_game() {
  local -a games=()
  mapfile -t games < <(bash "$installer" --list-games 2>/dev/null || true)
  local game=""
  if (("${#games[@]}" == 1)); then
    game="${games[0]}"
  else
    case "$backend" in
      kdialog) game="$(kdialog --title "$title" --getexistingdirectory "$HOME" 2>/dev/null)" || return 1 ;;
      zenity) game="$(zenity --file-selection --directory --title='Select HITMAN game directory' --filename="$HOME/" 2>/dev/null)" || return 1 ;;
      terminal) read -r -p "HITMAN game directory (blank cancels): " game || return 1 ;;
    esac
  fi
  [[ -n "$game" ]] || return 1
  if [[ "$(basename -- "$game" | tr '[:upper:]' '[:lower:]')" == retail ]]; then game="$(dirname -- "$game")"; fi
  [[ -f "$game/Retail/HITMAN3.exe" ]] ||
    { message "The folder does not contain Retail/HITMAN3.exe. No files were changed." >&2; return 1; }
  printf '%s\n' "$game"
}
verify_game() {
  local game="$1" retail="$game/Retail" mod="$game/Retail/mods/HitmanCoop.dll"
  [[ -f "$retail/HITMAN3.exe" ]] || { echo "HITMAN3.exe missing"; return 1; }
  [[ -f "$mod" ]] || { echo "Artur Edition mod DLL missing"; return 1; }
  [[ -f "$retail/dinput8.dll" && -f "$retail/ZHMModSDK.dll" ]] ||
    { echo "A required mod loader file is missing"; return 1; }
  [[ -f "$retail/mods.ini" ]] && grep -Eiq '^[[:space:]]*\[HitmanCoop\][[:space:]]*$' "$retail/mods.ini" ||
    { echo "HitmanCoop isn't enabled in mods.ini"; return 1; }
  if cmp -s "$mod" "$root/files/mods/HitmanCoop.dll"; then
    echo "PASS: Artur Edition v0.14.4 game 3.290 DLL matches bundled runtime."
  elif [[ -f "$root/files-3.280/mods/HitmanCoop.dll" ]] && cmp -s "$mod" "$root/files-3.280/mods/HitmanCoop.dll"; then
    echo "PASS: Artur Edition v0.14.4 game 3.280 DLL matches bundled runtime."
  else
    echo "FAIL: Installed DLL differs from the v0.14.4 Artur Edition payload."
    return 1
  fi
  echo "PASS: mod loader files and [HitmanCoop] entry present."
  echo "This verifies installation files, not in-game DLL loading or network connections."
}
run_update() {
  local logfile latest downloaded
  logfile="$(mktemp)"
  if ! latest="$(bash "$updater" --check 2>"$logfile")"; then
    show_results "$logfile" 0 || true
    rm -f "$logfile"
    return
  fi
  rm -f "$logfile"
  if [[ -z "$latest" ]]; then
    message "This is already the latest Artur Edition Steam Deck installer."
    return
  fi
  ask "Artur Edition $latest is available.\n\nDownload and verify the new Steam Deck AppImage? Your current AppImage will be kept." || return
  logfile="$(mktemp)"
  if ! downloaded="$(bash "$updater" --download "$latest" 2>"$logfile")"; then
    show_results "$logfile" 0 || true
    rm -f "$logfile"
    return
  fi
  rm -f "$logfile"
  message "Artur Edition $latest is verified and saved to:\n$downloaded\n\nYou can open the new launcher from the Applications menu."
  if ask "Open the updated Steam Deck installer now?"; then
    exec env APPIMAGE_EXTRACT_AND_RUN=1 "$downloaded" --gui
  fi
}

run_action() {
  local action="$1" logfile="" ok=0 game=""
  if [[ "$action" == update ]]; then run_update; return; fi
  if [[ "$action" == launch ]]; then
    ask "Launch HITMAN through the official Steam entry?" || return 0
    command -v steam >/dev/null 2>&1 && steam "steam://rungameid/1659040" || message "Please launch HITMAN from Steam."
    return 0
  fi
  game="$(choose_game)" || return 0
  logfile="$(mktemp)"
  case "$action" in
    install|repair)
      ask "Install/repair Artur Edition v0.14.4 in:\n$game\n\nExisting game files will be backed up by the installer." || { rm -f "$logfile"; return 0; }
      if bash "$installer" --game "$game" --quiet --no-firewall >"$logfile" 2>&1; then ok=1; fi ;;
    uninstall)
      ask "Uninstall Artur Edition from:\n$game\n\nThe installer will restore backed up files." || { rm -f "$logfile"; return 0; }
      if bash "$installer" --game "$game" --uninstall --quiet --no-firewall >"$logfile" 2>&1; then ok=1; fi ;;
    verify)
      if verify_game "$game" >"$logfile" 2>&1; then ok=1; fi ;;
  esac
  show_results "$logfile" "$ok" || true
  rm -f "$logfile"
}
menu() {
  local prompt=""
  prompt="$(status_text)"
  case "$backend" in
    kdialog) kdialog --title "$title" --menu "$prompt" update 'Check for installer updates' install 'Install or repair' verify 'Verify installed files' repair 'Reinstall / repair' launch 'Launch HITMAN via Steam' uninstall 'Uninstall / restore' status 'View status' quit 'Exit' ;;
    zenity) zenity --title="$title" --list --width=800 --height=550 --text="$prompt" --column='Action' --column='Description' --print-column=1 update 'Check for installer updates' install 'Install or repair' verify 'Verify installed files' repair 'Reinstall / repair' launch 'Launch HITMAN via Steam' uninstall 'Uninstall / restore' status 'View status' quit 'Exit' ;;
    terminal)
      printf '%s\n' "$prompt" >&2
      printf '1 Updates | 2 Install | 3 Verify | 4 Repair | 5 Launch | 6 Uninstall | 7 Status | 8 Quit\n' >&2
      local answer=""; read -r -p "Choose: " answer || return 1
      case "$answer" in 1) echo update;; 2) echo install;; 3) echo verify;; 4) echo repair;; 5) echo launch;; 6) echo uninstall;; 7) echo status;; 8) echo quit;; *) echo invalid;; esac ;;
  esac
}
while :; do
  action="$(menu)" || break
  case "$action" in
    update|install|verify|repair|uninstall|launch) run_action "$action" ;;
    status) message "$(status_text)" ;;
    quit|'') break ;;
    *) message "Choose one of the listed actions." ;;
  esac
done
