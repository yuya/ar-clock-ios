#!/usr/bin/env bash
# Web アプリ（yuya/ar-clock）の指定した版を Web/ に取り込む。
#   scripts/sync-web.sh            … main の最新
#   scripts/sync-web.sh <ref>      … ブランチ名・タグ・コミット
#   WEB_SRC=../ar-clock scripts/sync-web.sh … 手元のフォルダから
set -euo pipefail
cd "$(dirname "$0")/.."
REF="${1:-main}"
rm -rf Web .web-src && mkdir -p Web
if [ -n "${WEB_SRC:-}" ]; then
  SRC="$WEB_SRC"; VER="local"
else
  git clone --quiet --depth 1 --branch "$REF" https://github.com/yuya/ar-clock .web-src 2>/dev/null \
    || { git clone --quiet https://github.com/yuya/ar-clock .web-src && git -C .web-src checkout --quiet "$REF"; }
  SRC=".web-src"; VER="$(git -C .web-src rev-parse --short HEAD)"
fi
cp "$SRC/index.html" Web/
for f in "$SRC"/*.mp4 "$SRC"/*.mp3 "$SRC"/*.png "$SRC"/*.jpg "$SRC"/*.svg "$SRC"/*.js "$SRC"/*.css; do [ -e "$f" ] && cp "$f" Web/; done
echo "$VER" > Web/VERSION
rm -rf .web-src
echo "Web/ <- ar-clock@$VER"; ls -la Web
