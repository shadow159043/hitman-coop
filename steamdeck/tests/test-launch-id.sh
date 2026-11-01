#!/usr/bin/env bash
set -u

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail"
mkdir -p "$TMPDIR/steamapps/common/HITMAN World of Assassination/compatdata"
mkdir -p "$TMPDIR/.steam/steam/config"
mkdir -p "$TMPDIR/.local/share/Steam/steam/config"

cat > "$TMPDIR/.steam/steam/config/libraryfolders.vdf" <<EOF
"libraryfolders"
{
  "0"
  {
    "path"     "$TMPDIR"
  }
}
EOF

cat > "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail/HITMAN3.exe" <<EOF
placeholder
EOF
cat > "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail/dinput8.dll" <<EOF
placeholder
EOF
cat > "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail/ZHMModSDK.dll" <<EOF
placeholder
EOF
mkdir -p "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail/mods"
cat > "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail/mods/HitmanCoop.dll" <<EOF
placeholder
EOF
cat > "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail/mods.ini" <<EOF
[mod]
name=HitmanCoop
EOF

HOME="$TMPDIR"
export HOME

GAME_ROOT="$(resolve_game_root "")"
if [[ -z "$GAME_ROOT" || "$GAME_ROOT" != "$TMPDIR/steamapps/common/HITMAN World of Assassination" ]]; then
  echo "test-discovery.sh: expected game root detection failed" >&2
  exit 1
fi

if [[ "$HITMAN_COOP_APP_ID" != "1659040" ]]; then
  echo "test-discovery.sh: wrong App ID used" >&2
  exit 1
fi

if ! check_required_artur_files "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail"; then
  echo "test-discovery.sh: required Artur files were not recognized" >&2
  exit 1
fi

printf 'test-discovery.sh: passed\n'

