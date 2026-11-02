#!/usr/bin/env bash
# Build a standalone, offline, x86_64 AppImage from an already-published
# Steam Deck Proton ZIP. The ZIP remains as a manual-install fallback.
set -euo pipefail
if (($# != 3)); then
  printf 'Usage: bash steamdeck/appimage/build.sh verified-release.zip appimagetool.AppImage output.AppImage\n' >&2
  exit 2
fi
source_zip="$(realpath -- "$1")"
tool="$(realpath -- "$2")"
output="$(realpath -m -- "$3")"
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
test -s "$source_zip"
test -s "$tool"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
appdir="$tmp/AppDir"
runtime="$appdir/usr/share/artur-edition"
mkdir -p "$runtime"
unzip -q "$source_zip" -d "$runtime"
for required in "steamdeck/ui-install.sh" "steamdeck/payload/Retail/mods/HitmanCoop.dll" "steamdeck/payload/RUNTIME-SHA256SUMS.txt"; do
  test -f "$runtime/$required" || { echo "Missing bundled file: $required" >&2; exit 1; }
done
cp "$repo/steamdeck/appimage/AppRun" "$appdir/AppRun"
cp "$repo/steamdeck/appimage/artur-edition.desktop" "$appdir/artur-edition.desktop"
cp "$repo/steamdeck/appimage/artur-edition.svg" "$appdir/artur-edition.svg"
chmod 0755 "$appdir/AppRun"
find "$runtime/steamdeck" -type f -name '*.sh' -exec chmod 0755 {} +
chmod -R a+rX "$appdir"
mkdir -p "$(dirname "$output")"
export ARCH=x86_64
export APPIMAGE_EXTRACT_AND_RUN=1
"$tool" "$appdir" "$output"
chmod 0755 "$output"
test -s "$output"
file "$output"
echo "Standalone offline Steam Deck installer: $output"
