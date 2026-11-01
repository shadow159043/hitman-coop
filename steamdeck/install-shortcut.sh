#!/usr/bin/env bash
set -euo pipefail
DECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
dest="$HOME/.local/share/applications/hitman-coop-artur-steamdeck.desktop"
mkdir -p "$(dirname "$dest")"
# Freedesktop Exec uses double quotes for paths containing spaces.
escaped="${DECK_ROOT//\\/\\\\}"
escaped="${escaped//\"/\\\"}"
cat > "$dest" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=HITMAN Co-op - Artur Edition (Steam Deck)
Comment=Experimental Steam Deck/Proton installer and launcher
Exec=/usr/bin/env bash "$escaped/ui-install.sh" --gui
Icon=applications-games
Terminal=false
Categories=Game;Utility;
EOF
chmod 644 "$dest"
printf 'Desktop Mode launcher installed: %s\n' "$dest"
