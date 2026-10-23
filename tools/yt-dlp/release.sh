#!/bin/sh
# release.sh [YT_DLP_FILE] : the tool yt-dlp of Jcmp-Tools = the launcher of the tool python (called yt-dlp, it runs yt-dlp.pyz) and
#   yt-dlp-files.tar (yt-dlp.pyz, the one-file program of yt-dlp, Unlicense). Needs the tool python (python-android) next to it.
#   dist/yt-dlp, dist/yt-dlp-files.tar, dist/SHA256SUMS ; VERSION = the version of yt-dlp.
set -eu
cd "$(dirname "$0")"
PYDIST=../python/dist
[ -f "$PYDIST/python" ] || { echo "release: build the tool python first (tools/python/release.sh)"; exit 1; }
rm -rf dist _work; mkdir dist _work
if [ -n "${1:-}" ]; then cp "$1" _work/yt-dlp.pyz; else curl -fsSL -o _work/yt-dlp.pyz https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp; fi
cp "$PYDIST/python" dist/yt-dlp
VER="$(python3 - <<'PY'
import zipfile,re
z=zipfile.ZipFile('_work/yt-dlp.pyz'); print(re.search(r"__version__ = '([^']+)'", z.read('yt_dlp/version.py').decode()).group(1))
PY
)"
echo "$VER" > VERSION; echo "$VER" > LATEST
tar cf dist/yt-dlp-files.tar -C _work yt-dlp.pyz
rm -rf _work
( cd dist && sha256sum yt-dlp yt-dlp-files.tar > SHA256SUMS && ls -l )
echo "yt-dlp $VER"
