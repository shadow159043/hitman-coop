#!/usr/bin/env bash
set -u

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$STEAMDECK_ROOT/lib/common.sh"

if [[ "$HITMAN_COOP_APP_ID" != "1659040" ]]; then
  echo "test-launch-id.sh: expected App ID 1659040" >&2
  exit 1
fi

printf 'test-launch-id.sh: passed\n'

