#!/usr/bin/env bash
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
exec bash "$DECK_ROOT/install.sh" --repair "$@"
