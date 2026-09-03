#!/bin/bash
# Both ground textures for the three towns, at twice the resolution the app
# shipped with, from one script.
#
# The extent is the thing that must not drift: the drawn map and the aerial
# photo have to cover exactly the same square or a zone drawn on one sits on the
# wrong roofs on the other. Both are therefore derived the same way — 2048 px at
# zoom 16, which is by construction the same ground as the original 1024 px at
# zoom 15, one zoom level being twice the pixels for the same earth.
#
# Output is JPEG for both. The map used to be PNG, which at 2048 px would be
# several megabytes a town inside a file students copy on a memory stick; at
# q90 the labels stay sharp and the file is a quarter of that.
#
#   bash make-maps.sh              # both sources, three towns
#   bash make-maps.sh map          # just the drawn maps
#   bash make-maps.sh sat telavi   # one source, one town
set -u
UA="Bekura3D-presentation-map/1.0 (archfixsaas@gmail.com)"
Z=16; N=8; PX=$((N*256))          # 2048 px == the old z15/1024 px extent
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/../ground"
PS="$(cygpath -w "$HERE/mosaic.ps1")"
mkdir -p "$OUT"

# Esri path order is /z/ROW/COL, OSM is /z/X/Y. Swapping them returns a valid
# tile of the wrong place rather than an error, so they are kept apart here.
SAT_URL="https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile"
MAP_URL="https://tile.openstreetmap.org"

fetch_and_mosaic () {
  SRC=$1; ID=$2; LAT=$3; LON=$4
  case "$SRC" in
    sat) EXT=jpg; Q=76; SUF="-sat"; DIR="$HERE/tiles/sat-$ID" ;;
    map) EXT=png; Q=90; SUF="";     DIR="$HERE/tiles/map-$ID" ;;
    *) echo "unknown source $SRC" >&2; return 1 ;;
  esac

  read IX0 IY0 OX OY MPP <<< $(awk -v lat="$LAT" -v lon="$LON" -v z="$Z" -v px="$PX" 'BEGIN{
    pi=atan2(0,-1); n=2^z;
    fx=(lon+180)/360*n;
    r=lat*pi/180; fy=(1-log((sin(r)/cos(r))+(1/cos(r)))/pi)/2*n;
    wx=fx*256-px/2; wy=fy*256-px/2;
    ix0=int(wx/256); iy0=int(wy/256);
    printf "%d %d %.3f %.3f %.5f", ix0, iy0, wx-ix0*256, wy-iy0*256, 156543.03392*cos(r)/n }')

  mkdir -p "$DIR"
  ok=0; got=0
  for ((i=0;i<=N;i++)); do for ((j=0;j<=N;j++)); do
    f="$DIR/${i}_${j}.$EXT"
    if [ ! -s "$f" ]; then
      if [ "$SRC" = "sat" ]; then U="$SAT_URL/$Z/$((IY0+j))/$((IX0+i))"
      else                        U="$MAP_URL/$Z/$((IX0+i))/$((IY0+j)).png"; fi
      code=$(curl -s -m 40 -A "$UA" -o "$f" -w "%{http_code}" "$U")
      [ "$code" = "200" ] || rm -f "$f"
      got=$((got+1))
      # OSM asks bulk consumers to go easy; the cache means this is paid once
      [ "$SRC" = "map" ] && sleep 0.12
    fi
    [ -s "$f" ] && ok=$((ok+1))
  done; done

  TOTAL=$(( (N+1)*(N+1) ))
  [ "$ok" -lt "$TOTAL" ] && echo "  $SRC/$ID: only $ok/$TOTAL tiles — re-run to fill the gaps" >&2
  printf "%-4s %-9s tiles=%s/%s (fetched %s)  %.3f m/px  ground=%.1f m\n" \
    "$SRC" "$ID" "$ok" "$TOTAL" "$got" "$MPP" "$(awk -v m="$MPP" -v p="$PX" 'BEGIN{print m*p}')"

  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS" \
    -TileDir "$(cygpath -w "$DIR")" -N "$N" -OX "$OX" -OY "$OY" \
    -Px "$PX" -OutPx "$PX" -Quality "$Q" -Ext "$EXT" \
    -Out "$(cygpath -w "$OUT/$ID$SUF.jpg")"
}

TOWNS_LAT=(42.0341864 41.9197221 41.7445000)
TOWNS_LON=(45.2108579 45.4703169 45.7990000)
TOWNS_ID=(akhmeta telavi gurjaani)

SOURCES="${1:-map sat}"
ONLY="${2:-}"
for src in $SOURCES; do
  for k in 0 1 2; do
    [ -n "$ONLY" ] && [ "$ONLY" != "${TOWNS_ID[$k]}" ] && continue
    fetch_and_mosaic "$src" "${TOWNS_ID[$k]}" "${TOWNS_LAT[$k]}" "${TOWNS_LON[$k]}"
  done
done

echo
echo "Map data © OpenStreetMap contributors (ODbL)."
echo "Imagery: Esri World Imagery (Esri, Maxar, Earthstar Geographics)."
echo "Now run: bash ../build.sh"
