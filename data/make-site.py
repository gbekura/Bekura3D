# Pull the marked working-area boundary out of the scan .blend.
#
#   blender --background YOUR_SCAN.blend --python data/make-site.py
#
# The scan mesh itself is the biggest object; ANY other mesh or curve in the
# file is taken to be the boundary the trainer drew over it. Its outline is
# flattened to plan, converted to maketi world axes and centred on the same
# square make-scan.py uses, so the ring lands exactly on the terrain it was
# drawn on. Writes data/site-scan.json.
import bpy, json, os
from mathutils import Vector

OUT = os.path.dirname(os.path.abspath(__file__))
meshes = [o for o in bpy.data.objects if o.type in ('MESH', 'CURVE')]
if not meshes:
    raise SystemExit("no objects in the file")

# the scan is whichever mesh has the most faces; the boundary is the other one
def facecount(o):
    return len(o.data.polygons) if o.type == 'MESH' else 0
scan = max(meshes, key=facecount)
others = [o for o in meshes if o is not scan]
if not others:
    raise SystemExit("no boundary object found — the file has only the scan. "
                     "Draw the working area as a separate object and save.")
site = max(others, key=lambda o: len(o.data.vertices) if o.type == 'MESH' else 0)

# same bounding square make-scan.py centres on, taken from the scan
cs = [Vector(c) for c in scan.bound_box]
xs = [c.x for c in cs]; ys = [c.y for c in cs]
cx, cy = (min(xs)+max(xs))/2.0, (min(ys)+max(ys))/2.0

# world-space vertices, flattened to plan
mw = site.matrix_world
if site.type == 'CURVE':
    pts = [mw @ p.co.to_3d() for sp in site.data.splines for p in
           (sp.bezier_points if sp.type == 'BEZIER' else sp.points)]
else:
    pts = [mw @ v.co for v in site.data.vertices]

# order the outline: the drawn shape is a flat ring, so an angular sort about
# its own centroid recovers the polygon without needing edge topology
gx = sum(p.x for p in pts)/len(pts); gy = sum(p.y for p in pts)/len(pts)
import math
pts.sort(key=lambda p: math.atan2(p.y-gy, p.x-gx))

ring = []
for p in pts:
    ring.append([round(p.x - cx, 2), round(-(p.y - cy), 2)])   # Blender Z-up -> maketi Y-up

# drop near-duplicate points so the ribbon does not stutter
clean = []
for p in ring:
    if not clean or math.hypot(p[0]-clean[-1][0], p[1]-clean[-1][1]) > 1.0:
        clean.append(p)

area = 0.0
for i in range(len(clean)):
    a, b = clean[i], clean[(i+1) % len(clean)]
    area += a[0]*b[1] - b[0]*a[1]
area = abs(area)/2.0

with open(os.path.join(OUT, "site-scan.json"), "w") as f:
    json.dump({"ring": clean, "area": round(area, 1)}, f)
print("@@OK@@" + json.dumps({"scan": scan.name, "site": site.name,
                             "points": len(clean), "area_m2": round(area),
                             "area_ha": round(area/10000, 2)}))
