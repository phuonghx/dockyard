#!/usr/bin/env bash
# Regenerates docs/images/*.png from a fake engine, so no real container is ever shown.
# Captures only the Dockyard window (by X11 id, via XWayland), never your screen.
#   tools/screenshots.sh            all shots (about 4 minutes, charts need time to fill)
#   tools/screenshots.sh empty      one shot
# Needs: plasmawindowed, xprop, ImageMagick (import, magick), python3.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="docs/images"; RC="$HOME/.config/plasmawindowedrc"; SOCK=/tmp/dockyard-fake.sock; EMPTY=/tmp/dockyard-empty.sock
mkdir -p "$OUT"; cp -f "$RC" "$RC.dockyard-bak" 2>/dev/null || true
cleanup() { pkill plasmawindowed 2>/dev/null || true; kill $(jobs -p) 2>/dev/null || true
            [ -f "$RC.dockyard-bak" ] && mv -f "$RC.dockyard-bak" "$RC"; rm -f "$SOCK" "$EMPTY" /tmp/dockyard-dead.sock; }
trap cleanup EXIT
python3 tools/fake_engine.py "$SOCK" & python3 tools/fake_engine.py "$EMPTY" --empty &
: > /tmp/dockyard-dead.sock; sleep 1

rc() { printf '[Applets][4]\nimmutability=1\nplugin=io.dockyard.widget\n\n[Applets][4][Configuration]\ngeometry=4,28,500,800\n\n%b' "$1" > "$RC"; }
shot() { # name  engine-socket  wait-seconds
  DOCKER_HOST="unix://$2" QT_QPA_PLATFORM=xcb plasmawindowed io.dockyard.widget >/dev/null 2>&1 &
  sleep "$3"; local id=""
  for w in $(xprop -root _NET_CLIENT_LIST | grep -o '0x[0-9a-f]*'); do
    xprop -id "$w" WM_CLASS 2>/dev/null | grep -qi plasmawindowed && { id=$w; break; }; done
  [ -n "$id" ] && import -window "$id" "$OUT/$1.png" && echo "saved $OUT/$1.png"
  pkill plasmawindowed || true; sleep 1
}
want() { [ -z "${1:-}" ] || [ "${ONLY:-}" = "$1" ] || [ -z "${ONLY:-}" ]; }
ONLY="${1:-}"

want overview-dark   && { rc ''; shot overview-dark "$SOCK" 55; }
want overview-light  && { rc '[Applets][4][Configuration][Appearance]\ntheme=light\n'; shot overview-light "$SOCK" 45; }
want tab-images      && { rc '[Applets][4][Configuration][Appearance]\ndefaultTab=1\n'; shot tab-images "$SOCK" 10; }
want tab-volumes     && { rc '[Applets][4][Configuration][Appearance]\ndefaultTab=2\n'; shot tab-volumes "$SOCK" 10; }
want tab-networks    && { rc '[Applets][4][Configuration][Appearance]\ndefaultTab=3\n'; shot tab-networks "$SOCK" 10; }
want empty           && { rc ''; shot empty "$EMPTY" 7; }
want error-not-running && { rc '[Applets][4][Configuration][General]\nsocket=/tmp/dockyard-dead.sock\n'; shot error-not-running "$SOCK" 7; }
want error-no-engine && { rc '[Applets][4][Configuration][General]\nsocket=/tmp/dockyard-none.sock\n'; shot error-no-engine "$SOCK" 7; }
echo done
