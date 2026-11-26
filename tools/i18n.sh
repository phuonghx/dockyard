#!/usr/bin/env bash
# Translation helper for Dockyard (gettext). Needs: xgettext, msgmerge, msgfmt (package: gettext).
#   tools/i18n.sh extract         refresh po/*.pot from the QML sources
#   tools/i18n.sh merge           merge the new .pot into every po/<lang>.po
#   tools/i18n.sh compile         build the .mo files and package/contents/ui/translations.js
#   tools/i18n.sh new <lang>      start a new language, e.g. new it   (or pt_PT, zh_TW ...)
#   tools/i18n.sh check           fail if a .po has fuzzy, empty or broken entries
#   tools/i18n.sh all             extract + merge + compile
set -euo pipefail
cd "$(dirname "$0")/.."
DOMAIN="plasma_applet_io.dockyard.widget"
POT="po/$DOMAIN.pot"

extract() {
  xgettext -L JavaScript --from-code=UTF-8 --keyword=i18n:1 --keyword=i18nc:1c,2 --keyword=i18np:1,2 --keyword=i18ncp:1c,2,3 \
    --keyword=t:1 --keyword=tc:1c,2 --keyword=tn:1,2 \
    --package-name=dockyard --package-version="$(python3 -c "import json;print(json.load(open('package/metadata.json'))['KPlugin']['Version'])")" \
    --msgid-bugs-address=phuonghx.me@gmail.com --copyright-holder="Xuan-Phuong Hoang" --no-location \
    -o "$POT" package/contents/ui/*.qml package/contents/ui/config/*.qml package/contents/config/config.qml 2>&1 | grep -v vc-mtime || true
  # KDE's %1 placeholders are not JavaScript printf formats; the flag only causes false "fuzzy" matches.
  sed -i '/^#, javascript-format$/d' "$POT"
  echo "extracted $(grep -c '^msgid' "$POT") messages into $POT"
}
merge() { for f in po/*.po; do msgmerge -q --update --backup=none "$f" "$POT"; echo "merged $f"; done; }
compile() {
  for f in po/*.po; do
    lang="$(basename "$f" .po)"; dir="package/contents/locale/$lang/LC_MESSAGES"; mkdir -p "$dir"
    msgfmt --check -o "$dir/$DOMAIN.mo" "$f"; echo "compiled $lang"
  done
  python3 tools/po2js.py   # the widget UI reads this table (see L10n.qml)
}
new() { [ -n "${1:-}" ] || { echo "usage: $0 new <lang>"; exit 1; }
  msginit --no-translator -i "$POT" -l "$1" -o "po/$1.po" && echo "created po/$1.po, translate it, then run: $0 compile"; }
check() { bad=0
  for f in po/*.po; do
    msgfmt --check --statistics -o /dev/null "$f" 2>&1 | sed "s|^|$(basename "$f"): |"
    if grep -q '^#, fuzzy' "$f"; then echo "$f has fuzzy entries"; bad=1; fi
  done; exit $bad; }

case "${1:-all}" in
  extract) extract ;; merge) merge ;; compile) compile ;; new) new "${2:-}" ;; check) check ;;
  all) extract; merge; compile ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac
