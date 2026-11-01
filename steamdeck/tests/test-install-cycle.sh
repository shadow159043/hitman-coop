#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_STATE_HOME="$tmp/state"
game="$tmp/Game With Spaces"
retail="$game/Retail"
pkg="$tmp/Artur Windows R2.18.1/Retail"
mkdir -p "$retail/mods" "$pkg/mods" "$HOME"
printf 'fake-hitman' > "$retail/HITMAN3.exe"
for name in dinput8.dll ZHMModSDK.dll crashpad_handler.exe discord_game_sdk.dll ResourceLib_HM3.dll; do
  printf 'mod-%s' "$name" > "$pkg/$name"
done
printf 'mod-coop' > "$pkg/mods/HitmanCoop.dll"
printf 'previous sdk' > "$retail/ZHMModSDK.dll"
printf '[OtherMod]\nsetting=true\n' > "$retail/mods.ini"
if bash "$root/verify.sh" --game "$game" >/dev/null 2>&1; then echo "Unmodified HITMAN unexpectedly verified"; exit 1; fi
bash "$root/install.sh" --game "$game" --package "$tmp/Artur Windows R2.18.1"
bash "$root/verify.sh"
[[ "$(cat "$retail/ZHMModSDK.dll")" == 'mod-ZHMModSDK.dll' ]]
grep -Fq '[OtherMod]' "$retail/mods.ini"
grep -Fq '[HitmanCoop]' "$retail/mods.ini"
[[ ! -d "$retail/HitmanCoop-Backup" ]] || exit 1
[[ -f "$XDG_STATE_HOME/hitman-coop-artur-deck/manifest.tsv" ]]
bash "$root/install.sh" --game "$game" --package "$tmp/Artur Windows R2.18.1"
rm -f "$retail/mods/HitmanCoop.dll"
bash "$root/repair.sh" --game "$game" --package "$tmp/Artur Windows R2.18.1"
bash "$root/verify.sh"
bash "$root/uninstall.sh"
[[ "$(cat "$retail/ZHMModSDK.dll")" == 'previous sdk' ]]
grep -Fq '[OtherMod]' "$retail/mods.ini"
! grep -Fq '[HitmanCoop]' "$retail/mods.ini"
[[ ! -e "$retail/mods/HitmanCoop.dll" ]]
[[ ! -e "$retail/dinput8.dll" ]]
# Enabled conflict must fail before backup or modifications.
printf '[AssassinRivals2]\n' >> "$retail/mods.ini"
if bash "$root/install.sh" --game "$game" --package "$tmp/Artur Windows R2.18.1" >/dev/null 2>&1; then
  echo "Enabled conflicting mod was incorrectly accepted"; exit 1
fi
echo "PASS: install, checksums, repeat, repair, rollback, unrelated config, conflict guard."
