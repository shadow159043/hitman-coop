#!/usr/bin/env bash
set -u

STEAMDECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mapfile -t tests < <(find "$STEAMDECK_ROOT/tests" -maxdepth 1 -type f -name '*.sh' | sort)
if [[ ${#tests[@]} -eq 0 ]]; then
  echo "No Steam Deck tests were found." >&2
  exit 1
fi

status=0
for test in "${tests[@]}"; do
  echo "Running $test"
  if ! bash "$test"; then
    status=1
  fi
done

if [[ $status -ne 0 ]]; then
  echo "One or more Steam Deck tests failed." >&2
  exit 1
fi

echo "All Steam Deck tests passed."

