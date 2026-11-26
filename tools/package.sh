#!/usr/bin/env bash
# Build dist/dockyard-<version>.plasmoid: the archive the KDE Store and "Install Widget From Local File" use.
#   tools/package.sh
set -euo pipefail
cd "$(dirname "$0")/.."
# refresh the compiled translations when gettext is available; otherwise trust the committed ones
if command -v msgfmt >/dev/null 2>&1; then tools/i18n.sh compile >/dev/null 2>&1 || true; fi
python3 tools/po2js.py --check >/dev/null || { echo "translations.js is out of date: run tools/i18n.sh compile" >&2; exit 1; }
VER="$(python3 -c "import json;print(json.load(open('package/metadata.json'))['KPlugin']['Version'])")"
OUT="dist/dockyard-$VER.plasmoid"; mkdir -p dist
python3 - "$OUT" <<'PY'
import os, sys, zipfile
out = sys.argv[1]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk("package"):
        dirs[:] = sorted(d for d in dirs if d != "__pycache__")
        for f in sorted(files):
            p = os.path.join(root, f)
            z.write(p, os.path.relpath(p, "package"))   # metadata.json and contents/ at the archive root
print("built", out, os.path.getsize(out) // 1024, "KB")
PY
sha256sum "$OUT"
