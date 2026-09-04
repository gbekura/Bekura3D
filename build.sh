#!/bin/bash
# Bundles app.html + three.js + the ground textures into one self-contained
# bekura3d.html that students can open by double-clicking. No server needed.
#
#   bash build.sh
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/app.html"
OUT="$HERE/bekura3d.html"
TMP="$HERE/.build.tmp"

rm -rf "$TMP"; mkdir -p "$TMP"

# 1. inline the ground textures as data: URIs.
#    The three towns are JPEG mosaics from data/make-maps.sh. The Lisi entry
#    is different:
#    the scan is a real mesh, so its "ground" texture is the photogrammetry UV
#    atlas, downscaled to 2048 from whatever the survey produced.
{
  printf 'var GROUNDS = {'
  first=1
  for t in akhmeta telavi gurjaani; do
    f="$HERE/ground/$t.jpg"
    [ -f "$f" ] || { echo "missing ground/$t.jpg — run data/make-maps.sh" >&2; exit 1; }
    [ $first -eq 1 ] || printf ','
    first=0
    printf '"%s":"data:image/jpeg;base64,%s"' "$t" "$(base64 -w0 "$f")"
  done
  ATLAS="$HERE/ground/scan-atlas-2048.jpg"
  [ -f "$ATLAS" ] || { echo "missing $ATLAS" >&2; exit 1; }
  printf ',"scan":"data:image/jpeg;base64,%s"' "$(base64 -w0 "$ATLAS")"
  printf '};'
} > "$TMP/grounds.js"

# 1a. inline the aerial photo of each town, produced by data/make-maps.sh
#     on exactly the extent the OSM texture covers. Optional: a build without
#     them still works, and the რუკა/სატელიტი switch simply hides itself.
{
  printf 'var SATS = {'
  first=1
  for t in akhmeta telavi gurjaani; do
    f="$HERE/ground/$t-sat.jpg"
    [ -f "$f" ] || continue
    [ $first -eq 1 ] || printf ','
    first=0
    printf '"%s":"data:image/jpeg;base64,%s"' "$t" "$(base64 -w0 "$f")"
  done
  printf '};'
  [ $first -eq 1 ] && echo "  note: no ground/*-sat.jpg — run data/make-maps.sh" >&2
} > "$TMP/sats.js"

# 1b. inline the Georgian fonts, so the text renders identically on any machine
FONTDIR="$HERE/fonts"
{
  for pair in "400:DejaVuSans.ttf" "700:DejaVuSans-Bold.ttf"; do
    w=${pair%%:*}; f="$FONTDIR/${pair#*:}"
    [ -f "$f" ] || { echo "missing font $f" >&2; exit 1; }
    printf "@font-face{font-family:'Maketi Sans';font-style:normal;font-weight:%s;" "$w"
    printf "src:url(data:font/ttf;base64,%s) format('truetype')}\n" "$(base64 -w0 "$f")"
  done
} > "$TMP/fonts.css"

# 2. inline three.js and the town data (buildings, streets, terrain)
cp "$HERE/lib/three.min.js" "$TMP/three.js"
[ -f "$HERE/data/townsdata.json" ] || { echo "missing data/townsdata.json — run data/make-data.sh" >&2; exit 1; }
# Splice the drone scan in as a fourth "town" at build time, so townsdata.json
# stays exactly what data/make-data.sh produced and the scan stays a separate
# artefact of data/make-scan.py. Re-running either one is enough; there is no
# hand-merge step to forget.
SCANH="$HERE/data/scan-heights.json"
[ -f "$SCANH" ] || { echo "missing data/scan-heights.json — run data/make-scan.py" >&2; exit 1; }
{
  SZ=$(grep -o '"size": *[0-9.]*' "$SCANH" | head -1 | sed 's/.*: *//')
  printf '{"scan":{"size":%s,"b":[],"s":[],"t":' "$SZ"
  grep -o '"t": *\[[^]]*\]' "$SCANH" | sed 's/"t": *//' | tr -d '\n'
  printf '},'
  tail -c +2 "$HERE/data/townsdata.json"
} > "$TMP/buildings.json"
[ -f "$HERE/data/scan-mesh.json" ] || { echo "missing data/scan-mesh.json — run data/make-scan.py" >&2; exit 1; }
cp "$HERE/data/scan-mesh.json" "$TMP/scanmesh.json"
# Optional: the working area drawn over the scan in Blender (data/make-site.py).
# Absent simply means no red boundary on the scan tab.
# Working areas drawn per town, baked in so every copy opens on the right ground.
if [ -f "$HERE/data/sites.json" ]; then cp "$HERE/data/sites.json" "$TMP/sites.json"; else printf "{}" > "$TMP/sites.json"; fi
if [ -f "$HERE/data/site-scan.json" ]; then cp "$HERE/data/site-scan.json" "$TMP/sitering.json"; else printf "null" > "$TMP/sitering.json"; fi

# 2b. The build stamp the განახლება panel shows, so a trainer can tell whether
#     the pull actually landed. Taken from HEAD and never from the clock: the
#     same commit has to rebuild to the same 13 MB file, or every rebuild would
#     be a diff.
BC=$(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || true)
BD=$(git -C "$HERE" log -1 --format=%cs 2>/dev/null || true)
if [ -n "$BC" ]; then
  printf '{"c":"%s","d":"%s"}' "$BC" "$BD" > "$TMP/build.json"
else
  printf 'null' > "$TMP/build.json"          # built outside a checkout
fi

# 3. splice everything into the page. The __DATA__ marker sits on its own
#    line below a bare "{}" placeholder, so replacing that whole line is safe.
awk -v gfile="$TMP/grounds.js" -v tfile="$TMP/three.js" -v bfile="$TMP/buildings.json" \
    -v afile="$TMP/sats.js" -v vfile="$TMP/build.json" \
    -v ffile="$TMP/fonts.css" -v sfile="$TMP/scanmesh.json" -v rfile="$TMP/sitering.json" -v dfile="$TMP/sites.json" '
  /^<script src="lib\/three\.min\.js"><\/script>$/ {
    print "<script>"
    while ((getline line < tfile) > 0) print line
    print "</script>"
    next
  }
  /\/\*__FONTS__\*\// {
    while ((getline line < ffile) > 0) print line
    next
  }
  /\/\*__GROUNDS__\*\// {
    while ((getline line < gfile) > 0) print line
    next
  }
  /\/\*__SATS__\*\// {
    while ((getline line < afile) > 0) print line
    next
  }
  /^\{\}$/ && !seenB { next }                      # drop the empty placeholder
  /\/\*__SITES__\*\// {
    printf "var SITEDEFAULTS = "
    if ((getline line < dfile) > 0) printf "%s", line
    else printf "{}"
    print ";"
    next
  }
  /\/\*__SITERING__\*\// {
    printf "var SITERING = "
    if ((getline line < rfile) > 0) printf "%s", line
    else printf "null"
    print ";"
    next
  }
  /\/\*__BUILD__\*\// {
    printf "var BUILD = "
    if ((getline line < vfile) > 0) printf "%s", line
    else printf "null"
    print ";"
    next
  }
  /\/\*__SCANMESH__\*\// {
    printf "var SCANMESH = "
    while ((getline line < sfile) > 0) printf "%s", line
    print ";"
    next
  }
  /\/\*__DATA__\*\// {
    seenB = 1
    while ((getline line < bfile) > 0) printf "%s", line
    print ""
    print ";"
    next
  }
  { print }
' "$SRC" > "$OUT"

rm -rf "$TMP"

# 4. sanity checks
grep -q "THREE" "$OUT" || { echo "three.js not inlined" >&2; exit 1; }
grep -q "data:image/jpeg;base64" "$OUT" || { echo "grounds not inlined" >&2; exit 1; }
grep -q '"telavi":{' "$OUT" || { echo "town data not inlined" >&2; exit 1; }
grep -q '"s":\[' "$OUT" || { echo "streets not inlined" >&2; exit 1; }
grep -q '"t":\[' "$OUT" || { echo "terrain not inlined" >&2; exit 1; }
grep -q 'src="lib/three.min.js"' "$OUT" && { echo "external script still referenced" >&2; exit 1; }
grep -q 'var SATS = {' "$OUT" || { echo "satellite grounds not inlined" >&2; exit 1; }

awk -v f="$OUT" 'BEGIN{ "stat -c%s \"" f "\"" | getline s; printf "built bekura3d.html  %.1f MB\n", s/1048576 }'
