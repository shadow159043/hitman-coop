#!/usr/bin/env bash
# Verify root launcher finds the extracted package, including paths with spaces.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/A Folder With Spaces/steamdeck" "$tmp/bin" "$tmp/home"
cp "$root/INSTALL-ARTUR-EDITION.desktop" "$root/START-ARTUR-EDITION.sh" "$tmp/A Folder With Spaces/"
cat > "$tmp/A Folder With Spaces/steamdeck/ui-install.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "arg=$1" "path=$0" > "$ARTUR_ONE_CLICK_LOG"
EOF
cat > "$tmp/bin/kdialog" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin/kdialog"
export HOME="$tmp/home" ARTUR_ONE_CLICK_LOG="$tmp/launch.log"
export DISPLAY=:99 XDG_CURRENT_DESKTOP=KDE PATH="$tmp/bin:$PATH"
launcher="$tmp/A Folder With Spaces/INSTALL-ARTUR-EDITION.desktop"
test -f "$launcher"

# Emulate the FreeDesktop Exec field and expansion of %k (the .desktop file location).
python3 - "$launcher" <<'PY'
import pathlib, shlex, subprocess, sys
desktop = pathlib.Path(sys.argv[1])
line = next(line for line in desktop.read_text().splitlines() if line.startswith("Exec="))
# Simulate Desktop Entry's additional backslash unescaping before execution.
argv = [p.replace("\\$", "$") for p in shlex.split(line.partition("=")[2])]
argv = [str(desktop) if arg == "%k" else arg for arg in argv]
subprocess.run(argv, check=True)
PY
grep -Fx 'arg=--gui' "$tmp/launch.log"
grep -F 'A Folder With Spaces/steamdeck/ui-install.sh' "$tmp/launch.log"

# Opening from arbitrary working directory must succeed.
(cd / && bash "$tmp/A Folder With Spaces/START-ARTUR-EDITION.sh")
grep -Fx 'arg=--gui' "$tmp/launch.log"

# Launching an incomplete extraction must fail, never attempting an install.
rm "$tmp/A Folder With Spaces/steamdeck/ui-install.sh"
if bash "$tmp/A Folder With Spaces/START-ARTUR-EDITION.sh" >"$tmp/out" 2>&1; then
  echo 'FAIL: incomplete extraction launched' >&2
  exit 1
fi
grep -q 'Extract the complete ZIP first' "$tmp/out"
echo 'PASS: one-click launcher resolves paths with spaces and handles incomplete ZIP safely.'
