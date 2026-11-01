#!/usr/bin/env bash
set -u

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SCRIPT_DIR="$STEAMDECK_ROOT/tests"
for test in "$SCRIPT_DIR"/*.sh; do
  if [[ -f "$test" ]]; then
    echo "Running $test"
    bash "$test"
  fi
done

