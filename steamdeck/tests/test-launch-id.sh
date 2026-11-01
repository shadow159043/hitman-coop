#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/fake-steam" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" > "$STEAM_TEST_OUTPUT"
EOF
chmod +x "$tmp/fake-steam"
export STEAM_TEST_OUTPUT="$tmp/args.txt"
bash "$root/launch.sh" --steam "$tmp/fake-steam"
[[ "$(cat "$tmp/args.txt")" == 'steam://rungameid/1659040' ]]
! grep -Rq '1659[4]20' "$root" --exclude='test-launch-id.sh' || { echo "Incorrect App ID still present"; exit 1; }
echo "PASS: official Steam App ID and Steam launch argument."
