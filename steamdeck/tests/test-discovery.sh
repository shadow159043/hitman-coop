#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_STATE_HOME="$tmp/state"
mkdir -p "$HOME/.steam/steam/config" "$tmp/Library with spaces/steamapps/common/HITMAN World of Assassination/Retail"
cat > "$HOME/.steam/steam/config/libraryfolders.vdf" <<EOF
"libraryfolders"
{
 "1" { "path" "$tmp/Library with spaces" }
}
EOF
printf 'test game' > "$tmp/Library with spaces/steamapps/common/HITMAN World of Assassination/Retail/HITMAN3.exe"
cat > "$tmp/Library with spaces/steamapps/appmanifest_1659040.acf" <<'EOF'
"AppState"
{
  "appid" "1659040"
  "installdir" "HITMAN World of Assassination"
}
EOF
source "$root/lib/common.sh"
expected="$tmp/Library with spaces/steamapps/common/HITMAN World of Assassination/Retail"
actual="$(game_forced_or_auto "")"
[[ "$actual" == "$expected" ]] || { echo "Expected $expected; got $actual"; exit 1; }
[[ "$(game_forced_or_auto "$expected")" == "$expected" ]]
[[ "$APP_ID" == 1659040 ]]
echo "PASS: app manifest, libraryfolders.vdf, directory with spaces, manual path, Steam App ID."
