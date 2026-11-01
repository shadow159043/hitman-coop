#!/usr/bin/env bash
set -u

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat <<'EOF'
#!/usr/bin/env bash
set -u

# Automatically discovers the Steam Deck's Proton and game installation paths.
# This script intentionally does not modify the existing Windows release.

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

printf 'Steam Deck game search:\n'
for p in $(find_steam_libraries); do
  printf '  %s\n' "$p"
done

printf '\nProton detection:\n'
for p in $(detect_proton_bin 2>/dev/null); do
  printf '  %s\n' "$p"
done

printf '\nHITMAN detection:\n'
for p in $(detect_hitman_root 2>/dev/null); do
  printf '  %s\n' "$p"
done
EOF

