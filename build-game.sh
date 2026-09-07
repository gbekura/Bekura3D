#!/bin/bash
# Bundles game.html + three.js into one self-contained თამაში.html that a
# student can open by double-clicking, exactly like bekura3d.html.
#
#   bash build-game.sh
#
# Separate from build.sh on purpose: the games must never be able to break the
# planner's build, and they need none of its textures, fonts or town data.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/game.html"
OUT="$HERE/თამაში.html"
LIB="$HERE/lib/three.min.js"

[ -f "$SRC" ] || { echo "missing game.html" >&2; exit 1; }
[ -f "$LIB" ] || { echo "missing lib/three.min.js" >&2; exit 1; }

awk -v tfile="$LIB" '
  /^<script src="lib\/three\.min\.js"><\/script>$/ {
    print "<script>"
    while ((getline line < tfile) > 0) print line
    print "</script>"
    next
  }
  { print }
' "$SRC" > "$OUT"

grep -q '__THREE_NOT_INLINED__' "$OUT" && { echo "marker left behind" >&2; exit 1; }
grep -q 'lib/three.min.js' "$OUT" && { echo "three.js was not inlined" >&2; exit 1; }

SZ=$(du -h "$OUT" | cut -f1)
echo "built თამაში.html  $SZ"
