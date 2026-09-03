#!/bin/bash
# Builds data/townsdata.json: real building footprints, real street centrelines and
# a terrain heightfield for each town, all in metres local to the town centre and
# in the same projection as the ground textures.
#
#   buildings + streets : OpenStreetMap vector tiles (shortbread v1, zoom 14)
#   terrain             : AWS terrarium SRTM tiles (zoom 13, ~14 m/sample)
#
# Neither needs an API key. Overpass is deliberately not used.
set -eu
UA="Bekura3D-workshop/1.0 (archfixsaas@gmail.com)"
ZV=14          # vector tiles
ZT=13          # elevation tiles
HERE="$(cd "$(dirname "$0")" && pwd)"
WINHERE="$(cygpath -m "$HERE")"
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
mkdir -p "$HERE/mvt" "$HERE/dem"

# id lat lon half-extent-metres (half of the ground square, see make-ground.sh)
TOWNS="akhmeta:42.0341864:45.2108579:1816.6
telavi:41.9197221:45.4703169:1820.0
gurjaani:41.7445000:45.7990000:1825.0"

# tile range covering the square at a given zoom
range () {
  awk -v lat="$1" -v lon="$2" -v half="$3" -v z="$4" 'BEGIN{
    pi=atan2(0,-1); R=6378137; n=2^z; k=cos(lat*pi/180);
    mx=R*lon*pi/180; my=R*log((sin(lat*pi/180)/cos(lat*pi/180))+(1/cos(lat*pi/180)));
    hm=half/k;
    for(i=0;i<2;i++) for(j=0;j<2;j++){
      ex=mx+(i==0?-hm:hm); ey=my+(j==0?-hm:hm);
      lo=ex/R*180/pi; la=(2*atan2(exp(ey/R),1)-pi/2)*180/pi;
      tx=int((lo+180)/360*n);
      r=la*pi/180; ty=int((1-log((sin(r)/cos(r))+(1/cos(r)))/pi)/2*n);
      if(i==0&&j==0){x0=tx;x1=tx;y0=ty;y1=ty}
      if(tx<x0)x0=tx; if(tx>x1)x1=tx; if(ty<y0)y0=ty; if(ty>y1)y1=ty;
    }
    printf "%d %d %d %d", x0, x1, y0, y1 }'
}

grab () {   # url cachefile
  [ -s "$2" ] || curl -s -m 60 -A "$UA" "$1" -o "$2" || true
  [ -s "$2" ]
}

JSON="{"
firstTown=1
for row in $TOWNS; do
  ID=${row%%:*}; rest=${row#*:}
  LAT=${rest%%:*}; rest=${rest#*:}
  LON=${rest%%:*}; HALF=${rest#*:}
  SIZE=$(awk -v h="$HALF" 'BEGIN{printf "%.1f", h*2}')

  read VX0 VX1 VY0 VY1 <<< $(range "$LAT" "$LON" "$HALF" "$ZV")
  VT=""; f1=1; nv=0
  for ((x=VX0; x<=VX1; x++)); do for ((y=VY0; y<=VY1; y++)); do
    f="$HERE/mvt/${ZV}_${x}_${y}.mvt"
    grab "https://vector.openstreetmap.org/shortbread_v1/$ZV/$x/$y.mvt" "$f" || continue
    [ $f1 -eq 1 ] || VT="$VT,"; f1=0
    VT="$VT{\"x\":$x,\"y\":$y,\"b64\":\"$(base64 -w0 "$f")\"}"
    nv=$((nv+1))
  done; done

  read DX0 DX1 DY0 DY1 <<< $(range "$LAT" "$LON" "$HALF" "$ZT")
  DEM=""; f2=1; nd=0
  for ((x=DX0; x<=DX1; x++)); do for ((y=DY0; y<=DY1; y++)); do
    f="$HERE/dem/${ZT}_${x}_${y}.png"
    grab "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/$ZT/$x/$y.png" "$f" || continue
    [ $f2 -eq 1 ] || DEM="$DEM,"; f2=0
    DEM="$DEM{\"x\":$x,\"y\":$y,\"b64\":\"$(base64 -w0 "$f")\"}"
    nd=$((nd+1))
  done; done

  echo "$ID: $nv vector tiles, $nd elevation tiles" >&2
  [ $firstTown -eq 1 ] || JSON="$JSON,"; firstTown=0
  JSON="$JSON\"$ID\":{\"lat\":$LAT,\"lon\":$LON,\"half\":$HALF,\"size\":$SIZE,\"vt\":[$VT],\"dem\":[$DEM]}"
done
JSON="$JSON}"

printf '%s' "$JSON" > "$HERE/.towns-tiles.json"
awk -v tf="$HERE/.towns-tiles.json" '
  /__TOWNS__/ { while ((getline l < tf) > 0) printf "%s", l; print ""; next }
  { print }
' "$HERE/extract-tpl.html" > "$HERE/.extract-run.html"

"$CHROME" --headless=new --disable-gpu --allow-file-access-from-files \
  --virtual-time-budget=60000 --user-data-dir="$HERE/cprof" \
  --dump-dom "file:///${WINHERE}/.extract-run.html" 2>/dev/null \
  | awk '/===BEGIN===/,/===END===/' > "$HERE/.extract-out.txt"

sed -n '/===BEGIN===/,/===JSON===/p' "$HERE/.extract-out.txt" | sed 's/<[^>]*>//g' | grep -v "===" >&2
sed -n '/===JSON===/,/===END===/p' "$HERE/.extract-out.txt" | sed 's/<[^>]*>//g' | grep -v "===" > "$HERE/townsdata.json"
rm -f "$HERE/.towns-tiles.json" "$HERE/.extract-run.html" "$HERE/.extract-out.txt"

grep -q '"telavi"' "$HERE/townsdata.json" || { echo "extraction failed" >&2; exit 1; }
awk -v f="$HERE/townsdata.json" 'BEGIN{ "stat -c%s \"" f "\"" | getline s; printf "townsdata.json %.0f KB\n", s/1024 }'
