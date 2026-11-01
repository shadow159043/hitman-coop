#!/usr/bin/env bash
# Optional integration test of a real, unpacked offline Deck package.
set -euo pipefail
root="${ARTUR_DECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
[[ -f "$root/payload/Retail/mods/HitmanCoop.dll" ]] || { echo "Requires an extracted offline package with real payload" >&2; exit 2; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_STATE_HOME="$tmp/state"
mkdir -p "$HOME" "$tmp/HITMAN Test/Retail"
printf 'fake HITMAN executable' > "$tmp/HITMAN Test/Retail/HITMAN3.exe"
bash "$root/install.sh" --game "$tmp/HITMAN Test" --package "$root/payload"
bash "$root/verify.sh"
[[ -s "$tmp/HITMAN Test/Retail/mods/HitmanCoop.dll" ]]
[[ -s "$tmp/HITMAN Test/Retail/ZHMModSDK.dll" ]]
bash "$root/uninstall.sh"
[[ ! -f "$tmp/HITMAN Test/Retail/mods/HitmanCoop.dll" ]]
[[ -f "$tmp/HITMAN Test/Retail/HITMAN3.exe" ]]
echo 'PASS: Real R2.18.1 DLL and SDK install, verification, and uninstall in a simulated game folder.'
