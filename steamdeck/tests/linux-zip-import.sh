#!/usr/bin/env bash
# Linux-only integration test: real Python ZIP import, checksums and hostile ZIP rejection.
# The test never opens HITMAN or touches a real Steam library.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v python3 >/dev/null || { echo "Python 3 is required" >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_STATE_HOME="$tmp/state"
mkdir -p "$HOME" "$tmp/Game With Spaces/Retail"
printf 'fake-game\n' > "$tmp/Game With Spaces/Retail/HITMAN3.exe"

python3 - "$tmp" <<'PY'
import hashlib
import pathlib
import stat
import sys
import zipfile

root = pathlib.Path(sys.argv[1])
prefix = "Windows-Artur-R2.18.1\\"
files = {
    "dinput8.dll": b"mock loader",
    "ZHMModSDK.dll": b"mock sdk",
    "crashpad_handler.exe": b"mock handler",
    "discord_game_sdk.dll": b"mock discord",
    "ResourceLib_HM3.dll": b"mock resource",
    "mods/HitmanCoop.dll": b"mock coop",
}
lines = [
    hashlib.sha256(data).hexdigest() + "\t" + name
    for name, data in files.items()
]
def make_zip(path, corrupt=False):
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for name, data in files.items():
            if corrupt and name == "ZHMModSDK.dll":
                data = b"corrupted sdk"
            # Real Windows release archives can use backslashes in ZIP member names.
            archive.writestr(prefix + "Retail\\" + name.replace("/", "\\"), data)
        archive.writestr(prefix + "RUNTIME-SHA256SUMS.txt", "\n".join(lines) + "\n")
make_zip(root / "good-release.zip")
make_zip(root / "bad-hash-release.zip", corrupt=True)
with zipfile.ZipFile(root / "traversal.zip", "w") as archive:
    archive.writestr("../outside.txt", "escape attempt")
with zipfile.ZipFile(root / "symlink.zip", "w") as archive:
    entry = zipfile.ZipInfo("link")
    entry.create_system = 3
    entry.external_attr = (stat.S_IFLNK | 0o777) << 16
    archive.writestr(entry, "/etc/passwd")
PY

# Reject malicious ZIPs before allowing any installation.
if python3 "$root/lib/extract_release.py" "$tmp/traversal.zip" "$tmp/traversal-out" >/dev/null 2>&1; then
  echo "FAIL: path-traversal ZIP was accepted" >&2; exit 1
fi
if python3 "$root/lib/extract_release.py" "$tmp/symlink.zip" "$tmp/symlink-out" >/dev/null 2>&1; then
  echo "FAIL: symlink ZIP was accepted" >&2; exit 1
fi
[[ ! -f "$tmp/outside.txt" ]] || { echo "FAIL: ZIP escaped extraction directory" >&2; exit 1; }

# Incorrect checksum in a real ZIP must stop before game files or backups change.
if bash "$root/install.sh" --game "$tmp/Game With Spaces" --package "$tmp/bad-hash-release.zip" >/dev/null 2>&1; then
  echo "FAIL: corrupt release passed payload validation" >&2; exit 1
fi
[[ ! -f "$tmp/Game With Spaces/Retail/mods/HitmanCoop.dll" ]] || {
  echo "FAIL: corrupt ZIP modified game files" >&2; exit 1
}

# Import Windows-style ZIP members and perform a complete Linux install cycle.
bash "$root/install.sh" --game "$tmp/Game With Spaces" --package "$tmp/good-release.zip"
bash "$root/verify.sh" --game "$tmp/Game With Spaces"
[[ -f "$tmp/Game With Spaces/Retail/mods/HitmanCoop.dll" ]]
bash "$root/uninstall.sh" --game "$tmp/Game With Spaces"
[[ ! -e "$tmp/Game With Spaces/Retail/mods/HitmanCoop.dll" ]]
[[ -f "$tmp/Game With Spaces/Retail/HITMAN3.exe" ]]
echo "PASS: Linux ZIP import, runtime hashes, malicious archive rejection, install/verify/uninstall."
