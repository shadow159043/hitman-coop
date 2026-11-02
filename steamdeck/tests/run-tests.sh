#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
count=0
for test in "$root"/tests/test-*.sh; do
  echo "=== $(basename "$test") ==="
  bash "$test"
  count=$((count+1))
done
echo "PASS: $count Steam Deck test suites."

bash "$root/test-one-click.sh"
