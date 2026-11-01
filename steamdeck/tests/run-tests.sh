#!/usr/bin/env bash
set -u

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

# Lightweight tests that validate the discovery logic and the backup helpers without
# mutating the game installation. These are intended for use in a CI shell or a
# local Linux test run.

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail"
mkdir -p "$TMPDIR/steamapps/common/Proton - Experimental"
mkdir -p "$TMPDIR/backup-target"

# Fake the home dir so discovery finds the new test path.
HOME="$TMPDIR"
export HOME

cp "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail" "$TMPDIR/steamapps/common/HITMAN World of Assassination/Retail" 2>/dev/null || true

if ! detect_hitman_root | grep -q 'HITMAN World of Assassination'; then
  echo "test-discovery.sh: HITMAN discovery failed" >&2
  exit 1
fi

# Do not install real mod files here; just validate backup generation.
BACKUP_DIR="$(make_backup_dir "$TMPDIR/backup-target")"
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "test-discovery.sh: backup helper failed" >&2
  exit 1
fi

printf 'Steam Deck discovery tests passed.\n'

