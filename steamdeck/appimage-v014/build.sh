#!/usr/bin/env bash
# Package the freshly built Artur Edition v0.14.2 Linux tarball, not the old R2.18.1 ZIP.
set -euo pipefail
if (($# != 4)); then
  echo "Usage: build.sh HitmanCoop-Artur-0.14.2-linux.tar.gz appimagetool.AppImage runtime-x86_64 output.AppImage" >&2
  exit 2
fi
source_tar="$(realpath -- "$1")"
tool="$(realpath -- "$2")"
runtime_file="$(realpath -- "$3")"
output="$(realpath -m -- "$4")"
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
test -s "$source_tar"
test -s "$tool"
test -s "$runtime_file"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/extract"
tar -tzf "$source_tar" | grep -Fx 'HitmanCoop-Artur-0.14.2/installer.sh' >/dev/null ||
  { echo 'Missing Artur 0.14.2 installer in tarball' >&2; exit 1; }
tar -xzf "$source_tar" -C "$tmp/extract" --no-same-owner
source_root="$tmp/extract/HitmanCoop-Artur-0.14.2"
for required in installer.sh files/mods/HitmanCoop.dll files-3.280/mods/HitmanCoop.dll; do
  test -f "$source_root/$required" || { echo "Missing matching v0.14.2 payload: $required" >&2; exit 1; }
done
appdir="$tmp/AppDir"
runtime="$appdir/usr/share/artur-edition"
mkdir -p "$runtime"
cp -a "$source_root/." "$runtime/"
cp "$repo/steamdeck/appimage-v014/steamdeck-ui.sh" "$runtime/steamdeck-ui.sh"
cp "$repo/steamdeck/appimage-v014/AppRun" "$appdir/AppRun"
cp "$repo/steamdeck/appimage/artur-edition.desktop" "$appdir/artur-edition.desktop"
cp "$repo/steamdeck/appimage/artur-edition.svg" "$appdir/artur-edition.svg"
chmod 0755 "$appdir/AppRun" "$runtime/steamdeck-ui.sh" "$runtime/installer.sh"
chmod -R a+rX "$appdir"
mkdir -p "$(dirname "$output")"
export ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1
"$tool" --runtime-file "$runtime_file" "$appdir" "$output"
chmod 0755 "$output"
test -s "$output"
file "$output"
echo "Artur Edition v0.14.2 offline AppImage: $output"
