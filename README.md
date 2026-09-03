# Bekura3D — site planner for ArchiTech Park Kakheti

Giorgi Bekurashvili, 2026 © Bekura3D

A browser tool where students place volumes, draw paths and see their masterplan in 3D —
standing among the **real buildings of their own town**, on its **real paved streets**, over its
**real terrain**. Everything but the student's own design comes from open data.

Each site is about **1.8 × 1.8 km**. Telavi falls 219 m across it, Gurjaani 168 m, Akhmeta 70 m,
so the slope is a real design constraint, not decoration.

**Open `bekura3d.html` by double-clicking it.** Nothing to install, no admin rights, no internet.
Everything — the 3D engine and all three town maps — is inside that one file.

Copy it to a USB stick and it works on any machine in Akhmeta, Telavi or Gurjaani.

## Getting the latest version

    git clone https://github.com/gbekura/Bekura3D.git

Then open `bekura3d.html`. To pick up a newer build later:

    git pull

**A new build cannot overwrite a team's work.** Work lives in the browser's own
storage, which survives replacing the page. For anything that storage cannot survive —
a fresh laptop, a cleared browser, carrying a class to another machine — the
**მონაცემები** button writes `bekura3d-data.js`: every town, both variants, the working
areas, all school documents and the settings, in one file. Put it next to
`bekura3d.html` and the app reads it on startup. It is gitignored, so `git pull` never
touches it.

## Building it yourself

`app.html` is the source; `bekura3d.html` is the single-file bundle students open.

    bash build.sh

That inlines three.js, the fonts, the town data and the ground textures as data URIs.
The textures are inlined rather than loaded from files for a reason worth knowing before
anyone "fixes" it: on a `file://` page an external image taints the WebGL canvas, and a
tainted canvas cannot produce the სურათი export.

To rebuild the ground textures from source (needs internet):

    bash data/make-maps.sh

`?selftest=1` runs 83 assertions in the page and prints the results over it. Run it
before shipping a build.

## Four tabs

**საბაზისო** — a clean 3ds Max style studio: gray gradient backdrop, a wide transparent home
grid with red X / blue Z axis lines, nothing else. The same modelling tools as სკოლა, for
practising or building a shape without the site around it.

**სკანი** — a real drone photogrammetry capture of Lisi, imported as an actual triangle mesh:
**34,110 triangles** carrying the survey's own photo texture. Buildings, roads, cut banks and
spoil heaps stand as real geometry, because a photogrammetry capture has vertical faces that a
height grid physically cannot hold. The site is **861 m** square with **47 m** of fall, in true
metres. Same tools as ქალაქი — zones, paths, areas in m² — just standing on a surveyed
site instead of an OpenStreetMap one.

**სკოლა** — the school masterplan studio for Day 2 Block 4. A 150 × 120 m plot
(1.8 ha, a realistic school site) with a 10 m grid, dimensioned edges, the street along the
south edge and trees on the surround — the paper site sheet from Block 3, made
three-dimensional. **Each tab keeps its own separate model** — shapes built in საბაზისო do
not appear in სკოლა and vice versa.

**ქალაქი** — the town-context tool: place zones and paths on the real Akhmeta, Telavi or
Gurjaani, among real buildings, real streets and real terrain.

**Transform works in every tab.** გადატანა / ბრუნვა / მასშტაბი and მიბმა sit at the top of the
city rail as well as in the modelling studio, with the same `W` / `E` / `R` shortcuts. In the
city they are reduced to what a plan can mean: two ground axes plus a free-movement square, one
rotation ring about the vertical, and sizing along those same two axes or both at once. Nothing
pitches or rolls, because every object here is draped on terrain. A mass carries its angle in a
`rot` field; an area or a path has nowhere to put one, so its points turn about their own centre
instead — same gesture, same result. Dragging shows the running figure in the hint bar together
with the size it has reached, so a team sizing a zone reads hectares while they drag rather than
after.

The ground under the plan has two states, switched with **რუკა / სატელიტი** in the panel. რუკა
is the drawn OpenStreetMap sheet: street names, plot lines, the things a map asserts.
სატელიტი is the aerial photograph: what is actually standing on the ground, including
everything the map never recorded. Both cover the identical square to the metre, so a zone
drawn on one sits on the same roofs on the other, and a team can flip between them mid-argument.
The switch appears only on the three towns — the school plot is invented ground, and the drone
scan already carries its own photograph.

### Regenerating the scan

Two commands, and both artefacts must be regenerated **together** after any decimation — they
share the bounding square, so re-running only one makes the visible mesh and the ground you
snap to drift apart.

```bash
blender --background SCAN_IMPORT_DECIMATED.blend --python data/make-scan.py
bash build.sh
```

`data/make-scan.py` writes `data/scan-lisi-mesh.json` (the mesh) and `data/scan-lisi.json` (a
129×129 heightfield that `terrainAt()` uses to sit volumes on the ground). `build.sh` splices
the heightfield in as a fourth town at build time, so `data/townsdata.json` stays exactly what
`data/make-data.sh` produced and there is no hand-merge step to forget.

The texture is separate: downscale the photogrammetry atlas to `ground/lisi-atlas-2048.jpg`.
At 2048 the whole page is 8.3 MB; 4096 looks sharper and costs about 2.5 MB more, which is the
trade to revisit if the classroom machines turn out to have room for it.

### What students can do in the school tab

- **Place six primitives** — ყუთი, ცილინდრი, პირამიდა, კონუსი, სფერო, ტორი.
- **Transform gizmos, 3ds Max style.** გადატანა / ბრუნვა / მასშტაბი, or keys `W` `E` `R`.
  **Z is up and blue, X red to the east, Y green to the north** — the Max convention.
  three.js is Y-up internally, so the gizmo carries the world vector each label maps to;
  X × Y = Z still holds, so the frame you see is right-handed.
  - Move: three axis arrows **plus three plane handles** (XY / YZ / XZ) for dragging within
    a plane instead of along one axis.
  - Rotate: three rings.
  - Scale: three axis handles, plus the **yellow centre cube for all-axis scaling**.
  - They stay a constant size on screen at any zoom and draw over the model, so they are
    always grabbable.
  - The gizmo acts on **whatever is selected** — a whole shape in ობიექტი mode, or just the
    selected face, edge or vertex in the other modes.
- **მიბმა (snap)** toggles snapping for all three: 1 m on move, 15° on rotate, 0.05 on scale.
  The city tabs have their own მიბმა with the same three numbers, kept separate because the two
  halves work at different scales.
  It re-derives the wanted total from the raw drag each frame, so repeated rounding cannot
  make the object drift.
- **Navigation box** in the top-right corner, like Max's ViewCube. Click a face to snap the
  view; a small axis tripod on it shows the Z-up frame at a glance. Faces are compass-named
  (see below).
- **პერსპ. / ორთო** switches the 3D view between perspective and parallel projection, and
  **ხედვის კუთხე** sets the perspective FOV from 18° to 85°.
- **The plot is dimensioned.** Survey-style run lines with end ticks sit just outside two
  edges, labelled 150 მ and 120 მ. The figures are HTML overlays so they stay upright and
  legible from any camera angle, and they show in both 3D and plan.
- **Sun and sky (განათება).** Sliders for the sun's compass მხარე and სიმაღლე, its
  brightness (**მზე**, down to 0 to switch it off entirely), and the ambient **ცის შუქი**.
  The **sky follows the sun** — a gradient dome that warms at the horizon and cools overhead
  as the sun drops, with a glow around the sun itself. Two sky modes: **ბუნებრივი** (natural
  daylight colour) and **თეთრი** (a flat white studio backdrop). Dim the sun to 0 and raise
  the sky, and the scene is lit by ambient alone with no shadows.
- **Navigation box** faces are **compass-named** — აღმ / დას / ჩრდ / სამხ / ზედ / ქვე —
  because the site has a real north and the brief asks students to reason about sun and noise
  by direction.
- **რულეტი (tape measure).** Click to drop the anchor, move for a live readout, click again
  to fix it. It measures against whatever is under the cursor — ground, plot or a shape — so
  it reads real geometry, not just the ground plane. The label gives the straight-line
  distance, and adds the height difference (↕) when the two points are at different levels.
  `Esc` clears it.
- **Live transform figures.** While you drag a gizmo, a label by the shape shows exactly how
  far it moved (metres per axis), how many degrees it turned, or the scale factor.
- **Snapping** lands on the absolute grid — with მიბმა on, a moved shape's coordinate comes to
  rest on whole metres, not just a rounded step from where it started.
- **Right-click a shape for shading**, Blender style: გლუვი (smooth) / ბრტყელი (flat) /
  ავტო-გლუვი (auto — smooth faces, sharp edges). Also on the panel.
- **Segments.** Cones, cylinders, spheres and toruses carry a სეგმენტები slider — change the
  resolution and the shape keeps its size and position.
- **Edit the shape itself.** Four modes: ობიექტი / წახნაგი / წიბო / წვერო. Drag a face and it
  **extrudes like SketchUp's push/pull**; drag an edge or vertex to reshape. The panel also has
  − / + and ⟲ ⟳ for exact steps when a gizmo drag is too fiddly.
- **Inset (ჩაწევა).** With a face selected, ჩაწევა shrinks a smaller face inside it, ringed
  with new side faces — inset then extrude sinks a panel into a wall, the classic move.
- **Boolean subtraction (გამოკლება).** Select a shape, press გამოკლება, then click the shape
  to cut away with — you get the first minus the second (an arch, a notch, a doorway). The
  result is a static mesh (no more segment slider), which you can keep shaping with the poly
  tools. Runs on a small inlined CSG engine (csg.js, MIT); no library download.
- **Undo / redo.** `Ctrl+Z` undoes, `Ctrl+Y` (or `Ctrl+Shift+Z`) redoes, up to 80 steps,
  across all three tabs.
- **Colour by legend, and name the colour.** The six swatches carry the exact colours from the
  Block 3 legend slide, and their names start **blank** — naming them *is* the Block 3
  exercise, so the tool must not do it for the team. What the Block 4 brief requires
  (შენობა, სპორტი, შესასვლელი, მწვანე, ბილიკი, შეკრების სივრცე) shows through as the input
  placeholder, so a team can see what is expected without being handed the words. The
  programme checklist below reads the brief, not the team's names, so it still catches a
  missing sports field even before anything is named. შეღებვა paints a shape; ფერის აღება is
  an eyedropper that lifts the colour off another shape.
- **დუბლიკატი (Ctrl+D).** Copies the selected shape two metres off and selects the copy, so
  pressing it four times gives a row. The city tab has the same shortcut on masses, zone
  polygons and paths, offset 15 m instead of 2. Day 3 Block 2 needs rows of small masses
  inside a ten minute challenge; placing each by hand is not viable. Note Shift is camera
  pan here, so cloning is **not** Shift+drag.
- **Name every shape**, which becomes its label in გეგმა view.
- **Name the plan**, as Block 4 requires.
- **Programme checklist** — the six required items tick off as they appear. Block 4 says
  forgetting one is the commonest beginner mistake, so the list is the safeguard.
- **ვარიანტი A / B**, for the two-variant exercise, then სურათი to export for the AI render.

## What it covers

| Agenda block | What the tool does |
|---|---|
| Day 2 — რუკა ენაა / მასტერპლანის ვორქშოპი | **გეგმა** view: zones, paths, an automatic legend with real areas in m². The digital version of the paper masterplan. |
| Block 2 — დიდი მასშტაბის სივრცის 3D მოდელირება | **3D** view: მოცულობები, ბილიკები, დიდი მასები — exactly the three things the block names. |
| Block 4 — AI ვიზუალიზაცია | **სურათი** exports a PNG of the current view, ready to feed the AI image tool. |

## What students do

1. Pick a colour on the right and give it a name — that is your legend.
2. Drag a rectangle on the map. That is a volume.
3. Select it and set how many floors it has.
4. Draw ბილიკი paths to connect the volumes.
5. Switch გეგმა ⇄ 3D to check the plan reads both ways.
6. Do it again in **ვარიანტი B**, then compare A and B and argue for one.
7. Press **სურათი** and hand the PNG to the AI render step.

The legend and the area totals build themselves, so a team always knows how much of the
site they have used — the number that makes them argue about density instead of guessing.

## Controls

| Action | Mouse |
|---|---|
| Draw / select | left button |
| Orbit | right button drag |
| Pan | middle drag, or Shift + drag |
| Zoom | wheel |
| Finish a path | `Enter`, or double-click |
| Delete selected | `Delete` |
| Undo / redo | `Ctrl+Z` / `Ctrl+Y` |
| Shade menu | right-click a shape (no drag) |
| Move / rotate / scale gizmo | `W` / `E` / `R` (school tab) |

## URL options

| URL | Effect |
|---|---|
| `bekura3d.html?tab=basic` | opens the studio tab (also `school`, `city`) |
| `bekura3d.html?giz=rotate` | starts on a given gizmo (`move`, `rotate`, `scale`) |
| `bekura3d.html?light=135,55,0.85,0.7,natural` | presets sun az,el,brightness, sky, mode |
| `bekura3d.html?town=akhmeta` | opens on that town (`akhmeta`, `telavi`, `gurjaani`) |
| `bekura3d.html?view=plan` | opens in plan view |
| `bekura3d.html?demo=1` | loads a worked example — use it to show the class what "finished" looks like |
| `bekura3d.html?selftest=1` | runs the pan/camera assertions and prints PASS/FAIL |
| `bekura3d.html?debug=1` | exposes `window.__bekura3d` for poking at state from the console |

The app also remembers which tab (ქალაქი / სკოლა) you were last on and reopens there.

Work is saved in the browser automatically, so a closed tab or a power cut does not lose it.
`?demo=1` does **not** overwrite a student's saved work.

## Rebuilding

Edit `app.html` (it loads `lib/` and `ground/` normally, so use a local server or Chrome's
`--allow-file-access-from-files` while developing), then:

```bash
bash build.sh
```

That inlines three.js, the three town maps and the building footprints into `bekura3d.html`, then
checks nothing external is left referenced. Run `bekura3d.html?selftest=1` afterwards — open it in
a normal browser, or headless:

```bash
chrome --headless=new --enable-unsafe-swiftshader --use-gl=angle --use-angle=swiftshader --window-size=640,400 --virtual-time-budget=4000 --dump-dom "file:///…/bekura3d.html?selftest=1"
```

Keep the **virtual-time budget small (~4 s) and the window small**. The assertions run
synchronously at start-up, so they need almost no budget; a large one just lets the render loop
spin under software WebGL until the run times out and reports nothing. Results are printed as
each check happens, so a throw still shows everything up to the failure plus an `ERR` line.

To change which part of a town is shown, regenerate the ground textures — they are OSM tiles
at zoom 16, 1024×1024, about 1820 m across, roughly 1.78 m per pixel.

### The site data

`data/townsdata.json` holds everything real, in metres relative to each town centre and in the
same projection as the ground textures:

| | source | Akhmeta | Telavi | Gurjaani |
|---|---|---|---|---|
| building footprints | OSM vector tiles | 167 | 3,742 | 324 |
| street centrelines | OSM vector tiles | 330 | 640 | 342 |
| terrain, 129×129 grid | SRTM | 535–605 m | 626–845 m | 354–522 m |

Buildings and streets come from **OpenStreetMap's own vector tiles**
(`vector.openstreetmap.org`, shortbread v1, zoom 14 — that endpoint serves nothing deeper).
Terrain comes from **AWS terrarium SRTM tiles** at zoom 13, about 14 m per sample. Neither needs
an API key. Overpass is deliberately not used: it was unreliable when this was built.

Regenerate everything with:

```bash
bash data/make-data.sh
```

That fetches both tile sets, decodes the vector tiles with `data/mvt.js` (a small
dependency-free MVT reader) and the elevation PNGs via canvas, all inside headless Chrome, then
rewrites `data/townsdata.json`. Street width comes from the OSM `kind` tag. Streets are clipped
to the site, otherwise their ribbons hang off the edge of the terrain.

Ground textures are separate — `bash data/make-maps.sh` builds both, the drawn OSM map and
the aerial photo under it, at 2048 px per town. Both extents come from the same tile
arithmetic, so the two register by construction rather than by eye and a zone drawn on one
sits on the same roofs on the other. `make-maps.sh map` or `make-maps.sh sat telavi` narrows
it. The satellite pass is optional: without `ground/*-sat.jpg` the app hides the სატელიტი
button and keeps რუკა and თეთრი.

## Keeping work when you ship a new build

Work lives in `localStorage`, which on a `file://` page survives overwriting
`bekura3d.html` — so shipping a new build in the tech park does not erase a
team's plan. That covers the common case, but not a fresh laptop, a cleared
browser, or carrying a class's work to another machine.

For those, the **მონაცემები** button writes `bekura3d-data.js`: everything the
app holds, in one file — every town, both variants, the working areas, all
school documents and the settings. Put it next to `bekura3d.html` and the app
reads it on startup.

It is a `.js` file rather than `.json` for a reason worth knowing before anyone
"fixes" it. A page opened by double-click is a `file://` document, and Chrome
gives every such document its own opaque origin, so it may not `fetch` a file
sitting beside it. It may load a *script* beside it. Writing the data as
`window.BEKURA3D_DATA = {...}` and pulling it in with a plain `<script src>` is
therefore the one way to read a companion file with no server, no permission
prompt and no File System Access API, which Chrome does not offer on `file://`
anyway. `build.sh` deliberately leaves that one tag external while inlining
everything else.

The seed only speaks when the live store is silent: work already on the machine
is the newer copy and always wins. On adoption the seed is written straight into
`localStorage`, so a later edit to one half cannot drop the other.

## Credits

- Map data © OpenStreetMap contributors, licensed under the **ODbL**. Tiles from the OSM
  standard style. This credit is shown in the app and must stay there.
- Aerial imagery: **Esri World Imagery** (Esri, Maxar, Earthstar Geographics and the GIS user
  community). Also credited in the app, and also must stay there.
- 3D engine: **three.js** r149, MIT licence, bundled in `lib/three.min.js`.
- Boolean geometry: **csg.js** (Evan Wallace), MIT licence, a trimmed copy inlined in the page.
- Georgian text: **DejaVu Sans** (in `fonts/`), a free Bitstream Vera
  derivative, embedded in the bundle so the same letters render on any machine.

## Licence

MIT — see [LICENSE](LICENSE). Use it, change it, teach with it.

The map data, the aerial imagery and the drone survey have their own terms; the Credits
above are not decoration, and the attribution shown in the app has to stay there.

## Known limits

- **The existing buildings are all one height.** OpenStreetMap carries no height or
  `building:levels` for these towns, so the app extrudes them to a single figure you can change
  with the სიმაღლე slider (default 6 m). The footprints are real; the heights are not claimed
  to be. The app says so on screen.
- **Akhmeta has only 167 buildings** against Telavi's 3,742 — that is the state of OSM there, not
  a bug. It matters less here than on a printed map, because students are adding their own masses.
- **Terrain is SRTM at ~14 m per sample**, so it carries the shape of the valley and the slope of
  the town, but not individual terraces or embankments.
- Roads are flat ribbons draped on the terrain, not kerbed or cambered.
- In the **ქალაქი** tab volumes are rectangles only — deliberate for a 60-minute block. The
  **სკოლა** tab is where free-form shaping lives.
