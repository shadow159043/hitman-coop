#!/usr/bin/env bash
# Fork-specific Steam Deck/Linux AppImage update checker. No installation unless
# the player explicitly chooses Update; the current AppImage is never overwritten.
set -euo pipefail
current_version="0.14.4"
repo="shadow159043/hitman-coop"
api="https://api.github.com/repos/$repo/releases/latest"
release_base="https://github.com/$repo/releases/download"
app_dir="${HOME:?}/Applications/Artur-Edition"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing prerequisite: $1" >&2; exit 1; }
}
need python3
need curl
need sha256sum

# Parse a GitHub release from stdin. Use exact repo and asset names, not arbitrary
# release-supplied URLs. On no newer release, print nothing and return success.
parse_release() {
  local desired="${1:-}"
  python3 -c '
import json,re,sys
current=sys.argv[1]
desired=sys.argv[2]
try:
    r=json.load(sys.stdin)
    tag=r.get("tag_name","")
    m=re.fullmatch(r"artur-v(\d+\.\d+\.\d+)",tag)
    if r.get("draft") or r.get("prerelease") or m is None:
        sys.exit(2)
    version=m.group(1)
    if tuple(map(int,version.split("."))) <= tuple(map(int,current.split("."))):
        sys.exit(0)
    if desired and version!=desired:
        sys.exit(2)
    name="Steam-Deck-Artur-Edition-"+version+"-Installer.AppImage"
    url="https://github.com/shadow159043/hitman-coop/releases/download/"+tag+"/"+name
    required={name:url,name+".sha256":url+".sha256"}
    found={a.get("name"):a.get("browser_download_url") for a in r.get("assets",[]) if isinstance(a,dict)}
    if any(found.get(n)!=u for n,u in required.items()):
        sys.exit(3)
    print(version)
except (ValueError,TypeError,KeyError,AttributeError,json.JSONDecodeError):
    sys.exit(2)
' "$current_version" "$desired"
}

fetch_release() {
  curl --fail --silent --show-error --location --retry 2 --max-time 25 \
    -H 'Accept: application/vnd.github+json' \
    -H 'User-Agent: ArturEdition-SteamDeck-Updater' "$api"
}

check() {
  local data
  data="$(fetch_release)" || { echo 'Cannot reach the Artur Edition GitHub release.' >&2; return 1; }
  printf '%s' "$data" | parse_release ""
}

download() {
  local version="${1:-}" tag name checksum_url download_url expected actual temp dest
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid update version.' >&2; return 1; }
  local data
  data="$(fetch_release)" || return 1
  [[ "$(printf '%s' "$data" | parse_release "$version")" == "$version" ]] ||
    { echo 'The requested version is not the verified latest release.' >&2; return 1; }
  tag="artur-v$version"
  name="Steam-Deck-Artur-Edition-$version-Installer.AppImage"
  download_url="$release_base/$tag/$name"
  checksum_url="$download_url.sha256"
  mkdir -p -- "$app_dir"
  temp="$(mktemp -d "$app_dir/.downloading.XXXXXXXX")"
  trap 'rm -rf -- "$temp"' RETURN
  curl --fail --silent --show-error --location --retry 2 --max-time 40 \
    --max-filesize 2048 "$checksum_url" -o "$temp/$name.sha256" || return 1
  expected="$(awk -v n="$name" 'NF==2 && $1 ~ /^[a-fA-F0-9]{64}$/ && $2==n {print tolower($1)}' "$temp/$name.sha256")"
  # awk intervals are not portable on all SteamOS versions; check with Python if empty.
  if [[ -z "$expected" ]]; then
    expected="$(python3 - "$temp/$name.sha256" "$name" <<'PY'
import re,sys
with open(sys.argv[1],encoding="ascii",errors="strict") as f: text=f.read().strip()
m=re.fullmatch(r"([a-fA-F0-9]{64})\s+\*?([A-Za-z0-9_.-]+)",text)
if not m or m.group(2)!=sys.argv[2]:sys.exit(1)
print(m.group(1).lower())
PY
)" || { echo 'The update checksum format was invalid.' >&2; return 1; }
  fi
  echo "Downloading and verifying Artur Edition $version..." >&2
  curl --fail --silent --show-error --location --retry 2 --max-time 240 \
    --max-filesize 160000000 "$download_url" -o "$temp/$name" || return 1
  actual="$(sha256sum "$temp/$name" | cut -d' ' -f1)"
  [[ "$expected" == "$actual" ]] || { echo 'SHA-256 verification failed. Update was not installed.' >&2; return 1; }
  chmod 0755 "$temp/$name"
  dest="$app_dir/$name"
  mv -f -- "$temp/$name" "$dest"
  ln -sfn -- "$name" "$app_dir/current.AppImage"

  # Persistent menu shortcut always opens the newest verified AppImage. Do not
  # modify an existing unrelated shortcut or overwrite the original AppImage.
  local shortcuts="$HOME/.local/share/applications"
  if [[ "$app_dir" != *[\"$'\n']* ]]; then
    mkdir -p -- "$shortcuts"
    cat > "$shortcuts/artur-edition-mission-control.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=HITMAN Co-op - Artur Edition Mission Control
Comment=Install, update and repair Artur Edition for Proton
Exec="$app_dir/current.AppImage" --gui
Terminal=false
Categories=Game;Utility;
Icon=applications-games
EOF
    chmod 0644 "$shortcuts/artur-edition-mission-control.desktop"
  fi
  echo "$dest"
}

selftest() {
  local good bad
  good='{"tag_name":"artur-v0.14.5","draft":false,"prerelease":false,"assets":[{"name":"Steam-Deck-Artur-Edition-0.14.5-Installer.AppImage","browser_download_url":"https://github.com/shadow159043/hitman-coop/releases/download/artur-v0.14.5/Steam-Deck-Artur-Edition-0.14.5-Installer.AppImage"},{"name":"Steam-Deck-Artur-Edition-0.14.5-Installer.AppImage.sha256","browser_download_url":"https://github.com/shadow159043/hitman-coop/releases/download/artur-v0.14.5/Steam-Deck-Artur-Edition-0.14.5-Installer.AppImage.sha256"}]}'
  [[ "$(printf '%s' "$good" | parse_release "")" == "0.14.5" ]] || return 1
  [[ "$(printf '%s' "$good" | parse_release "0.14.5")" == "0.14.5" ]] || return 1
  if printf '%s' "$good" | parse_release "0.14.6" >/dev/null; then return 1; fi
  bad="${good//shadow159043\/hitman-coop/someotherfork\/hitman-coop}"
  if printf '%s' "$bad" | parse_release "" >/dev/null; then return 1; fi
  echo "Steam Deck updater release validation passed (offline)."
}

case "${1:-}" in
  --check) check ;;
  --download) download "${2:-}" ;;
  --selftest) selftest ;;
  *) echo "Usage: steamdeck-updater.sh [--check|--download VERSION|--selftest]" >&2; exit 2 ;;
esac
