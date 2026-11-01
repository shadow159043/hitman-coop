#!/usr/bin/env bash
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# Restoring the original state is equivalent to the tracked uninstall operation.
exec "$DECK_ROOT/uninstall.sh" "$@"
