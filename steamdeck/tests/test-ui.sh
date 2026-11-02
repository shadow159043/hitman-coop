#!/usr/bin/env bash
# Headless test of native KDE/GTK interface dispatch without a real display or HITMAN.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"
export HOME="$tmp/home" XDG_STATE_HOME="$tmp/state"
export ARTUR_DIALOG_TEST_LOG="$tmp/dialog.log" ARTUR_DIALOG_TEST_COUNT="$tmp/count"
status="$(bash "$root/ui-install.sh" --status)"
[[ "$status" == *"Artur Edition: Not installed"* ]]
[[ "$status" == *"physical Steam Deck: UNTESTED"* ]]
echo "9" | bash "$root/ui-install.sh" --terminal >"$tmp/terminal-out" 2>&1
grep -q 'Mission Control\|Artur Edition\|Steam Deck / Proton' "$tmp/terminal-out"

cat > "$tmp/bin/zenity" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "zenity $*" >> "$ARTUR_DIALOG_TEST_LOG"
case " $* " in
  *' --list '*)
    if [[ -e "$ARTUR_DIALOG_TEST_COUNT" ]]; then printf 'quit\n'
    else touch "$ARTUR_DIALOG_TEST_COUNT"; printf 'status\n'; fi ;;
esac
EOF
cat > "$tmp/bin/kdialog" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "kdialog $*" >> "$ARTUR_DIALOG_TEST_LOG"
case " $* " in
  *' --menu '*)
    if [[ -e "$ARTUR_DIALOG_TEST_COUNT" ]]; then printf 'quit\n'
    else touch "$ARTUR_DIALOG_TEST_COUNT"; printf 'status\n'; fi ;;
esac
EOF
chmod +x "$tmp/bin/zenity" "$tmp/bin/kdialog"
export PATH="$tmp/bin:$PATH"
DISPLAY=:99 XDG_CURRENT_DESKTOP=GNOME bash "$root/ui-install.sh" --gui
grep -q 'zenity --list' "$tmp/dialog.log"
grep -q 'zenity --info' "$tmp/dialog.log"
rm -f "$tmp/count" "$tmp/dialog.log"
DISPLAY=:99 XDG_CURRENT_DESKTOP=KDE bash "$root/ui-install.sh" --gui
grep -q 'kdialog .* --menu' "$tmp/dialog.log"
grep -q 'kdialog .* --msgbox' "$tmp/dialog.log"

# A GUI installation attempt must be harmless if the user cancels folder selection.
cat > "$tmp/bin/zenity" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "zenity $*" >> "$ARTUR_DIALOG_TEST_LOG"
case " $* " in
  *' --list '*)
    if [[ -e "$ARTUR_DIALOG_TEST_COUNT" ]]; then printf 'quit\n'
    else touch "$ARTUR_DIALOG_TEST_COUNT"; printf 'install\n'; fi ;;
  *' --file-selection '*) exit 1;;
esac
EOF
chmod +x "$tmp/bin/zenity"
rm -f "$tmp/count" "$tmp/dialog.log"
DISPLAY=:99 XDG_CURRENT_DESKTOP=GNOME bash "$root/ui-install.sh" --gui
grep -q 'zenity --file-selection --directory' "$tmp/dialog.log"

# The installer shortcut opens Mission Control instead of the Windows game directly.
bash "$root/install-shortcut.sh" >/dev/null
desktop="$HOME/.local/share/applications/hitman-coop-artur-steamdeck.desktop"
[[ -f "$desktop" ]]
grep -q 'ui-install.sh" --gui' "$desktop"
command -v desktop-file-validate >/dev/null && desktop-file-validate "$desktop"

# Opening, viewing status, or cancelling installation must never change game files.
[[ ! -e "$XDG_STATE_HOME/hitman-coop-artur-deck/manifest.tsv" ]] || exit 1
echo "PASS: GTK and KDE graphical menu/status, terminal fallback, read-only startup."
