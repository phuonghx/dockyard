#!/usr/bin/env bash
# Dockyard installer. Per-user, no root needed.
#   ./install.sh              install or upgrade
#   ./install.sh --restart    ...and restart plasmashell so the panel picks it up
#   ./install.sh --uninstall
set -euo pipefail
cd "$(dirname "$0")"

ID="io.dockyard.widget"
ICONS="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"

need() { command -v "$1" >/dev/null 2>&1 || { echo "dockyard: '$1' is required (sudo dnf install $2)" >&2; exit 1; }; }
need kpackagetool6 kf6-kpackage
need python3 python3

if [ "${1:-}" = "--uninstall" ]; then
  kpackagetool6 -t Plasma/Applet --remove "$ID" || true
  rm -f "$ICONS/dockyard.svg"
  echo "Dockyard removed."
  exit 0
fi

if kpackagetool6 -t Plasma/Applet --show "$ID" >/dev/null 2>&1; then
  kpackagetool6 -t Plasma/Applet --upgrade package
else
  kpackagetool6 -t Plasma/Applet --install package
fi

mkdir -p "$ICONS"
install -m 0644 package/contents/icons/dockyard.svg "$ICONS/dockyard.svg"

if [ "${1:-}" = "--restart" ]; then
  echo "Restarting plasmashell..."
  kquitapp6 plasmashell >/dev/null 2>&1 || true
  setsid -f plasmashell >/dev/null 2>&1 || kstart plasmashell
fi

cat <<EOF

Dockyard is installed.
  Add it:   right-click a panel -> Add Widgets -> "Dockyard"
  Try it:   plasmawindowed $ID
  Docker:   if the widget says it can't reach Docker, run
            sudo usermod -aG docker \$USER   and log out and in again.
EOF
