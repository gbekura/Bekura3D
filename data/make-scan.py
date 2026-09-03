# Turn a photogrammetry scan .blend into the two files maketi needs.
# The scan is referenced everywhere as the id "scan", so swapping in a different
# capture is a data change and not a code change: re-run this, downscale the new
# atlas to ground/scan-atlas-2048.jpg, rebuild.
#
#   blender --background YOUR_SCAN.blend --python data/make-scan.py
#
# Writes, next to this script:
#   scan-mesh.json  the triangle mesh (positions, uvs, indices) as base64
#                        typed arrays, already in maketi world axes
#   scan-heights.json       a 129x129 heightfield over the same square, which is
#                        what terrainAt() uses to sit volumes on the ground
#
# Both come out of ONE object in ONE pass on purpose. They share the bounding
# square (cx, cy, size), so the mesh you see and the ground you snap to agree.
# Re-export both together after any decimation, or they drift apart.
#
# The texture is separate: downscale the photogrammetry atlas to
# ground/lisi-atlas-2048.jpg. build.sh inlines it as the "lisi" ground.
import bpy, json, base64, array, os
from mathutils import Vector

GRID = 129                      # must match GRID in app.html
OUT  = os.path.dirname(os.path.abspath(__file__))

meshes = [o for o in bpy.data.objects if o.type == 'MESH']
if not meshes:
    raise SystemExit("no mesh object in the file")
obj = max(meshes, key=lambda o: len(o.data.polygons))

bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True); bpy.context.view_layer.objects.active = obj
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

me = obj.data
me.calc_loop_triangles()

cs = [Vector(c) for c in obj.bound_box]
xs=[c.x for c in cs]; ys=[c.y for c in cs]; zs=[c.z for c in cs]
minx,maxx=min(xs),max(xs); miny,maxy=min(ys),max(ys); minz,maxz=min(zs),max(zs)
cx, cy = (minx+maxx)/2.0, (miny+maxy)/2.0
size = max(maxx-minx, maxy-miny); half = size/2.0

# ---- heightfield ----------------------------------------------------------
# j = 0 is north (+y in Blender), matching the plane in buildTerrain() after
# its -90 deg X rotation. Rays that miss the mesh get the mean height, so the
# ground never spikes outside the scanned footprint.
top = maxz + 10.0
t = []; hits = 0
for j in range(GRID):
    wy = cy + half - (size * j / (GRID - 1))
    for i in range(GRID):
        wx = cx - half + (size * i / (GRID - 1))
        ok, loc, nor, idx = obj.ray_cast(Vector((wx, wy, top)), Vector((0,0,-1)))
        if ok: t.append(round(loc.z, 2)); hits += 1
        else:  t.append(None)
real = [v for v in t if v is not None]
fb = round(sum(real)/len(real), 2) if real else 0.0
t = [fb if v is None else v for v in t]

# ---- mesh -----------------------------------------------------------------
# Split a vertex only where the UVs differ, so seams work and nothing else
# duplicates. Blender is Z-up, maketi is Y-up.
uvl = me.uv_layers.active.data if me.uv_layers.active else None
if uvl is None:
    raise SystemExit("mesh has no UVs — decimation must keep them")

key2new = {}
pos = array.array('f'); uvs = array.array('f'); idxs = []
for tri in me.loop_triangles:
    for li in tri.loops:
        vi = me.loops[li].vertex_index
        u, v = uvl[li].uv
        k = (vi, round(u,6), round(v,6))
        n = key2new.get(k)
        if n is None:
            n = len(key2new); key2new[k] = n
            co = me.vertices[vi].co
            pos.extend((co.x - cx, co.z, -(co.y - cy)))
            uvs.extend((u, v))
        idxs.append(n)

nv = len(key2new)
ind = array.array('I' if nv > 65535 else 'H', idxs)   # Uint16 while it fits

with open(os.path.join(OUT, "scan-mesh.json"), "w") as f:
    json.dump({"verts": nv, "tris": len(idxs)//3, "u32": nv > 65535,
               "pos": base64.b64encode(pos.tobytes()).decode(),
               "uv":  base64.b64encode(uvs.tobytes()).decode(),
               "idx": base64.b64encode(ind.tobytes()).decode()}, f)
with open(os.path.join(OUT, "scan-heights.json"), "w") as f:
    json.dump({"size": round(size,2), "grid": GRID, "t": t}, f)

print("@@OK@@" + json.dumps({
  "object": obj.name, "tris": len(idxs)//3, "verts": nv, "u32": nv > 65535,
  "size": round(size,2), "hitRatio": round(hits/float(GRID*GRID),3)}))
