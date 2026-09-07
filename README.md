# Bekura3D: a site planner for ArchiTech Park Kakheti

Giorgi Bekurashvili, 2026 © Bekura3D

A browser tool where students place volumes, draw paths and see their masterplan in 3D,
standing among the **real buildings of their own town**, on its **real paved streets**, over its
**real terrain**. Everything but the student's own design comes from open data.

Each site is about **1.8 × 1.8 km**. Telavi falls 219 m across it, Gurjaani 168 m, Akhmeta 70 m,
so the slope is a real design constraint, not decoration.

**Open `bekura3d.html` by double-clicking it.** Nothing to install, no admin rights, no internet.
Everything, the 3D engine and all three town maps, is inside that one file.

Copy it to a USB stick and it works on any machine in Akhmeta, Telavi or Gurjaani.

## Getting the latest version

    git clone https://github.com/gbekura/Bekura3D.git

Then pick one of the two setups.

### A shared laptop, or a room of them — `install.cmd`

Run **`install.cmd`** (or **`დაყენება.cmd`**, the same thing) once per machine. It
copies `bekura3d.html` into `C:\Program Files\Bekura3D` and puts a **Bekura3D**
shortcut on the **Public Desktop** and in the **All Users Start Menu**, so every
account on the laptop — including ones created later — sees the icon and opens the
same copy. A student never has to walk into a trainer's
`Users\<name>\Documents\GitHub` folder to find a file, which is the whole point.

**It asks for administrator rights, and it has to.** The Public Desktop and
Program Files are the two places Windows shares between accounts, and both are
closed to a standard user by design. There is no way to install for all users
quietly. If you would rather not elevate, use `setup.cmd` below instead.

Only `bekura3d.html` is copied — it is one self-contained file, so there is no
install tree to keep in step. **Re-run `install.cmd` after every update**: it
overwrites the shared copy, and `update.cmd` reminds you when that copy has gone
stale. `uninstall.cmd` removes the folder and both shortcuts.

**Saved work is never in the installed folder.** It lives in each Windows
account's own browser storage, so it survives an install, an uninstall and a
reinstall, and each account keeps its own. Two students sharing one Windows login
share one set of work — give them separate logins if that matters.

### One trainer's own laptop — `setup.cmd`

Run **`setup.cmd`** once. It puts two shortcuts on the Desktop — **Bekura3D**
and **განახლება** — and offers to register a `bekura3d://` scheme so the update
button inside the app can start the updater. No admin rights; `remove.cmd` undoes
the scheme, and the shortcuts are deleted by hand.

After that the update is: close the page, double-click **განახლება** on the
Desktop, open **Bekura3D** again. That is the whole update — the repository ships
`bekura3d.html` already built, so there is nothing to compile.

The equivalent by hand:

    git pull

**About the განახლება button.** A page opened by double-click is a `file://`
document with no shell, so it cannot start a process — no browser allows that,
and it is the reason the update is a separate `.cmd` at all. What the button can
do is hand Windows a URL. If `setup.cmd` registered the scheme on that laptop,
Windows answers `bekura3d://update` by running `update.cmd` and the button really
does update; if it did not, nothing happens and the panel still names the file.
Expect the browser to ask permission every time — the remembered "always allow"
is stored per origin and a `file://` page has none.

The registered command runs `bekura3d-update.ps1` with `-File` and **no `%1`**.
Any web page can navigate to `bekura3d://anything`, so nothing from the URL may
reach a shell: with a parameterless `-File` script whatever Windows appends binds
to nothing. Pointing the scheme at a `.cmd`, or switching to `-Command`, hands
that text to `cmd.exe`'s batch parser instead — the BatBadBut class, CVE-2024-24576.
**Before a workshop, test it once:** press the update button (a console should
appear), then put `bekura3d://update"&calc&"` in the address bar and confirm
Calculator does *not* open. If it does, run `remove.cmd` and use the shortcut.

## Where the buttons are

**სურათი, შენახვა, გახსნა, მონაცემები, განახლება** and **გასუფთავება** live behind the
**ფაილი** button at the right of the header. They used to sit in the header itself, which
wanted 1595px on the ქალაქი tab and so wrapped onto a second row on any laptop. Saving and
opening also answer <kbd>Ctrl</kbd>+<kbd>S</kbd> and <kbd>Ctrl</kbd>+<kbd>O</kbd>. Everything
else - the tabs, the town, გეგმა/3D, the projection, the variant and შენობები - is still one
click away in the header.

**A new build cannot overwrite a team's work.** Work lives in the browser's own
storage, which survives replacing the page. For anything that storage cannot survive -
a fresh laptop, a cleared browser, carrying a class to another machine, the
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

`?selftest=1` runs 250 assertions in the page and prints the results over it. Run it
before shipping a build, and run it on `bekura3d.html` rather than on `app.html`:
the bundle is what students open, and three of the assertions need the ground
textures that only the bundle carries inline.

## Four tabs

**საბაზისო**, a clean 3ds Max style studio: gray gradient backdrop, a wide transparent home
grid with red X / blue Z axis lines, nothing else. The same modelling tools as სკოლა, for
practising or building a shape without the site around it.

**სკანი**, a real drone photogrammetry capture of Lisi, imported as an actual triangle mesh:
**24,246 triangles** carrying the survey's own photo texture. Buildings, roads, cut banks and
spoil heaps stand as real geometry, because a photogrammetry capture has vertical faces that a
height grid physically cannot hold. The site is **861 m** square with **47 m** of fall, in true
metres. Same tools as ქალაქი, zones, paths, areas in m², just standing on a surveyed
site instead of an OpenStreetMap one.

**Editing the capture itself (ᲡᲙᲐᲜᲘᲡ ᲠᲔᲓᲐᲥᲢᲘᲠᲔᲑᲐ).** სკანი is the one tab whose ground is
captured rather than drawn, so it is the one place a team has to clear something away — a spoil
heap, a shed, whatever stands where the plan goes. A **წაშლის რეჟიმი** button in the right panel
turns the left button into an eraser: click or drag across the survey and triangles come out.
Dragging keeps cutting, because taking a spoil heap off a capture one triangle per click is not
a thing anyone would finish.

**The original is never touched.** What is stored is a list of which triangles were cut, not a
new mesh — the capture's own index buffer is kept whole and a filtered copy is what gets drawn.
So **საწყისის დაბრუნება** is emptying an array, the panel always says how many are gone, the cut
saves and loads with the document, and <kbd>Ctrl</kbd>+<kbd>Z</kbd> puts back a whole eraser
stroke rather than one triangle (the stroke commits once, when you let go, so a drag across four
hundred triangles does not fill the undo history with itself).

The button is only on სკანი, and it only exists while the mode is on — the eraser takes the
plain left button, so <kbd>Shift</kbd> and <kbd>Ctrl</kbd> are deliberately left alone and the
camera and the selection still work without leaving the mode.

**სკოლა**, the school masterplan studio for Day 2 Block 4. A 150 × 120 m plot
(1.8 ha, a realistic school site) with a 10 m grid, dimensioned edges, the street along the
south edge and trees on the surround, the paper site sheet from Block 3, made
three-dimensional. **Each tab keeps its own separate model**, shapes built in საბაზისო do
not appear in სკოლა and vice versa.

**ქალაქი**, the town-context tool: place zones and paths on the real Akhmeta, Telavi or
Gurjaani, among real buildings, real streets and real terrain.

**Transform works in every tab.** გადატანა / ბრუნვა / მასშტაბი and მიბმა sit at the top of the
city rail as well as in the modelling studio, with the same `W` / `E` / `R` shortcuts. In the
city they are reduced to what a plan can mean: two ground axes plus a free-movement square, one
rotation ring about the vertical, and sizing along those same two axes or both at once. Nothing
pitches or rolls, because every object here is draped on terrain. A mass carries its angle in a
`rot` field; an area or a path keeps the running total in the same field while its points turn
about their own centre, so the angle can be read back and typed even where there is no mesh to
turn. Dragging shows the running figure in the hint bar together with the size it has reached, so
a team sizing a zone reads hectares while they drag rather than after.

**Several objects at once.** <kbd>Ctrl</kbd>+click adds an object to the selection and
<kbd>Ctrl</kbd>+clicking a selected one takes it out again; a plain click still replaces the whole
set. Everything then works on the set: the gizmo moves, turns and sizes all of it, dragging any
member carries the rest, <kbd>Delete</kbd> takes them all and <kbd>Ctrl</kbd>+<kbd>D</kbd>
duplicates them together. The panel says how many are selected.

A group turns and scales about **the centre of the selection**, so each member spins on its own
axis *and* its centre orbits that shared point. That is the only answer that makes a group behave
like one object; turning each about its own centre instead looks like a bug, because five
buildings pirouette and the block never moves.

Under <kbd>Ctrl</kbd> the gizmo stops accepting clicks, deliberately. It stands in the middle of
the selection at a constant size on screen, so it covers the very objects a student is trying to
<kbd>Ctrl</kbd>+click out of the set, and every one of those clicks would otherwise grab a handle.

**Copy between tabs.** <kbd>Ctrl</kbd>+<kbd>C</kbd> and <kbd>Ctrl</kbd>+<kbd>V</kbd> (also **ასლი**
and **ჩასმა** in the ფაილი menu) carry a selection from one tab to another — build a block in
საბაზისო, paste it onto Telavi. Every tab is in real metres, so the geometry crosses unchanged and
only the wrapper is rebuilt, because the two halves describe an object differently:

| | how an object is held |
|---|---|
| studio | `{ kind: "box", pos, V, F, legend, seg, shade, rot }` |
| city | `{ kind: "shape", prim: "box", type: <zone>, pos, V, F, seg, shade, rot }` |

A city mass is a width/depth/height rather than a mesh, so it is baked into a box on the way into
the studio. A zoning area or a path is a ring of ground coordinates with no studio equivalent at
all: those are **refused by name** rather than pasted as something they are not, and the hint bar
says how many did not cross. The paste lands centred on whatever the camera is looking at, keeping
the group's own arrangement — the school plot is 150 m across and a town is 1,800, so the
coordinates it was copied from would drop it off the edge of the world half the time.

**And every transform can be typed.** With something selected, the panel on the right opens with
three rows of numbers — **ადგილი**, **ბრუნვა**, **ზომა** — X, Y and Z in the colours of the
gizmo's own axes. The gizmo answers "drag it until it looks right"; these answer "put it at 12
metres", which is the question a plan asks. Both halves of the app carry the same three rows, so
a student who learns them in სკოლა does not have to find them again in ქალაქი.

The frame is the one the rest of the app shows, **X east, Y north, Z up**, while three.js is Y-up
internally; every read and write goes through `uiFromWorld` / `uiToWorld` and nowhere else,
because getting it wrong in one place sends a typed northing underground. The self-test asserts
the mapping in both directions.

A field the selection cannot use greys out rather than disappearing, so the block keeps its shape
between selections:

| Where | What is locked, and why |
|---|---|
| ქალაქი, ადგილი Z | The terrain gives it. The box shows the ground level at that point. |
| ქალაქი, ბრუნვა X and Y | Nothing pitches or rolls on draped ground, matching the single ring the city gizmo offers. |
| ქალაქი, ზომა Z | On a mass it is live and sets the height; on a city primitive the height rides on the vertices, and on an area there is none. On a path it is the ribbon's width. |
| სკოლა, ბრუნვა and ზომა | Quiet in წახნაგი / წიბო / წვერო: turning one face is not turning the shape. ადგილი stays live, because the object's own position is unambiguous either way. |

In the studio, rotation and size are baked into the vertices — there is no stored matrix to read
back — so a shape carries a `rot` triple recording what it has been turned about each axis, and
typing an absolute angle applies the difference. The gizmo writes to the same record, so dragging
a shape round and then reading the box gives the angle you actually turned it to.

The ground under the plan has two states, switched with **რუკა / სატელიტი** in the panel. რუკა
is the drawn OpenStreetMap sheet: street names, plot lines, the things a map asserts.
სატელიტი is the aerial photograph: what is actually standing on the ground, including
everything the map never recorded. Both cover the identical square to the metre, so a zone
drawn on one sits on the same roofs on the other, and a team can flip between them mid-argument.
The switch appears only on the three towns, the school plot is invented ground, and the drone
scan already carries its own photograph.

### Regenerating the scan

Two commands, and both artefacts must be regenerated **together** after any decimation, they
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

- **Place six primitives**, ყუთი, ცილინდრი, პირამიდა, კონუსი, სფერო, ტორი.
- **Transform gizmos, 3ds Max style.** გადატანა / ბრუნვა / მასშტაბი, or keys `W` `E` `R`.
  **Z is up and blue, X red to the east, Y green to the north**, the Max convention.
  three.js is Y-up internally, so the gizmo carries the world vector each label maps to;
  X × Y = Z still holds, so the frame you see is right-handed.
  - Move: three axis arrows **plus three plane handles** (XY / YZ / XZ) for dragging within
    a plane instead of along one axis.
  - Rotate: three rings.
  - Scale: three axis handles, plus the **yellow centre cube for all-axis scaling**.
  - They stay a constant size on screen at any zoom and draw over the model, so they are
    always grabbable.
  - The gizmo acts on **whatever is selected**, a whole shape in ობიექტი mode, or just the
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
  The **sky follows the sun**, a gradient dome that warms at the horizon and cools overhead
  as the sun drops, with a glow around the sun itself. Two sky modes: **ბუნებრივი** (natural
  daylight colour) and **თეთრი** (a flat white studio backdrop). Dim the sun to 0 and raise
  the sky, and the scene is lit by ambient alone with no shadows. **ქალაქი carries the same
  panel**, driving its own sun and its own dome over the town: turn მზის მხარე and the
  streets tell you which side of them is in shade at four o'clock.
- **Navigation box** faces are **compass-named**, აღმ / დას / ჩრდ / სამხ / ზედ / ქვე -
  because the site has a real north and the brief asks students to reason about sun and noise
  by direction.
- **რულეტი (tape measure).** Click to drop the anchor, move for a live readout, click again
  to fix it. It measures against whatever is under the cursor, ground, plot or a shape, so
  it reads real geometry, not just the ground plane. The label gives the straight-line
  distance, and adds the height difference (↕) when the two points are at different levels.
  `Esc` clears it.
- **Live transform figures.** While you drag a gizmo, a label by the shape shows exactly how
  far it moved (metres per axis), how many degrees it turned, or the scale factor.
- **Or type the figure instead.** ადგილი / ბრუნვა / ზომა at the top of the panel take numbers
  directly, in metres and degrees, on all three axes. See **Transform works in every tab** above.
- **Snapping** lands on the absolute grid, with მიბმა on, a moved shape's coordinate comes to
  rest on whole metres, not just a rounded step from where it started.
- **Right-click a shape for shading**, Blender style: გლუვი (smooth) / ბრტყელი (flat) /
  ავტო-გლუვი (auto, smooth faces, sharp edges). Also on the panel.
- **Segments.** Cones, cylinders, spheres and toruses carry a სეგმენტები slider, change the
  resolution and the shape keeps its size and position.
- **Edit the shape itself.** Four modes: ობიექტი / წახნაგი / წიბო / წვერო. Drag a face and the
  face **moves**; drag an edge or vertex to reshape. The panel also has − / + and ⟲ ⟳ for exact
  steps when a gizmo drag is too fiddly.
- **Extruding is one deliberate gesture: <kbd>Shift</kbd> + drag an axis arrow**, with a face
  selected. It used to happen on its own — a plain face drag grew a new volume the moment the
  pointer passed 40 cm, so a student straightening a wall came away with geometry they never
  asked for and could only find by counting faces. And Shift used to cut the new face on
  *mouse-down*, so Shift plus a click, with no drag at all, added a face and an undo step. Now
  the drag moves the face, Shift only arms the extrude, and the cut happens on the first real
  movement — a quarter of a metre, so a pointer jittering under a heavy click is not the
  difference between a plan and a plan with a stray face in it. ქალაქი always behaved this way;
  the two halves now agree.
- **Several faces at once.** <kbd>Ctrl</kbd>+click adds a face, edge or vertex to the selection
  and <kbd>Ctrl</kbd>+clicking a marked one takes it out again, exactly as it already worked for
  whole objects — in all four tabs, city included. A set never mixes levels: clicking a vertex
  while faces are marked starts a fresh vertex selection, because no operation here could act on
  "one face and one vertex". A set lives inside one shape; the panel says how many are marked.
- **A colour for individual faces (წახნაგის ფერი).** With faces marked, the right panel offers a
  colour that applies to those faces alone, and **ფიგურას** hands them back. The shape's own ფერი
  stays underneath as what every unpainted face falls back to, so the two rows read as what they
  are: one paints the object, the other paints part of it. Painted faces ride in a vertex-colour
  attribute that only appears once a face is actually painted — a shape nobody has painted keeps
  exactly the geometry and the plain material it always had. In ქალაქი **თეთრი მასები** still
  wins over painted faces: it is a study mode, and that is exactly the kind of colour it exists
  to take away for a moment.
- **Inset (ჩაწევა).** With a face selected, ჩაწევა shrinks a smaller face inside it, ringed
  with new side faces, inset then extrude sinks a panel into a wall, the classic move.
- **Boolean subtraction (გამოკლება).** Select a shape, press გამოკლება, then click the shape
  to cut away with, you get the first minus the second (an arch, a notch, a doorway). The
  result is a static mesh (no more segment slider), which you can keep shaping with the poly
  tools. Runs on a small inlined CSG engine (csg.js, MIT); no library download.

  **Every shape has to be a solid wound outward for this to work**, and that is worth knowing
  before anyone touches the primitive builders. csg.js tells inside from outside using each
  polygon's own plane, so a shape whose faces wind inward has every one of those tests reversed
  and გამოკლება returns nonsense rather than failing — no error, just a wrong mesh.

  The primitives are all built inward and put right afterwards by `orientFaces`, which points
  each face away from the shape's centroid. That is a convexity assumption, and **the torus
  breaks it**: its centroid sits in the hole, where the inner faces of the ring correctly point
  *towards* it. So the torus is skipped, and until this was found it was the one primitive left
  inverted — which is why `torus − box` quietly produced rubbish. It is now born with the right
  winding instead, and `shapeToCSG` checks the signed volume and turns any inward solid round on
  the way in, so a torus already saved in a student's browser by an older build still cuts
  correctly. `?selftest=1` asserts that every primitive is a solid wound outward and that each
  one actually loses material when it is cut.
- **Undo / redo, on buttons as well as keys.** The **⟲ ⟳** pair sits beside **ფაილი** in the
  header and greys out when there is nothing left on that side of the stack — which the
  shortcut can never tell you. They also work where the shortcut does not: `Ctrl+Z` reaches
  the page only while the focus is outside a text field, and after typing a plan name or a
  transform figure it is inside one.
- **Undo / redo.** `Ctrl+Z` undoes, `Ctrl+Y` (or `Ctrl+Shift+Z`) redoes, up to 80 steps,
  across all three tabs.
- **Colour by legend, and name the colour.** The six swatches carry the exact colours from the
  Block 3 legend slide, and their names start **blank**, naming them *is* the Block 3
  exercise, so the tool must not do it for the team. What the Block 4 brief requires
  (შენობა, სპორტი, შესასვლელი, მწვანე, ბილიკი, შეკრების სივრცე) shows through as the input
  placeholder, so a team can see what is expected without being handed the words. The
  programme checklist below reads the brief, not the team's names, so it still catches a
  missing sports field even before anything is named. შეღებვა paints a shape; ფერის აღება is
  an eyedropper that lifts the colour off another shape.
- **ფერი — a colour of your own.** Every selected object has a **ფერი** row in the right
  panel with a native RGB picker, on all four tabs: shapes and zone outlines and paths in the
  studio, and masses, ფიგურა, zone polygons and roads in ქალაქი. The picker starts on the
  colour the object is already showing, so the first drag is a change from where the student
  is. **ლეგენდას** (studio) and **ზონას** / **ბილიკს** (city) hand it back, and stay greyed
  out until there is something to hand back. With several objects selected the picker changes
  all of them at once, like დუბლიკატი and წაშლა.
  The override is presentation only — **the legend still decides what an object *is***. The
  swatch counts and the ᲞᲠᲝᲒᲠᲐᲛᲐ checklist key on the legend entry and never on the colour, so
  a recoloured shape still ticks its programme item, and the city's m², shares and სიმჭიდროვე
  still bucket by ზონა. Both halves say how many objects have stepped away from the key:
  `N ობიექტი საკუთარი ფერითაა` under the studio legend, `N ფერშეცვლილი` in the city totals.
  Changing an object's ზონა or ლეგენდა drops its override, so a block moved to another
  category cannot keep a colour that now misreports it. **თეთრი მასები** still wins over a
  picked colour — it is a whole-view study mode and it hides the colour rather than losing
  it; the panel says so while it is on. The paint bucket and the eyedropper stay საბაზისო
  only: painting by hand is how a team would skip the legend altogether.
- **დუბლიკატი (Ctrl+D).** Copies the selected shape two metres off and selects the copy, so
  pressing it four times gives a row. The city tab has the same shortcut on masses, zone
  polygons and paths, offset 15 m instead of 2. Day 3 Block 2 needs rows of small masses
  inside a ten minute challenge; placing each by hand is not viable. Note Shift is camera
  pan here, so cloning is **not** Shift+drag.
- **Name every shape**, which becomes its label in გეგმა view.
- **Name the plan**, as Block 4 requires.
- **Programme checklist**, the six required items tick off as they appear. Block 4 says
  forgetting one is the commonest beginner mistake, so the list is the safeguard.
- **ვარიანტი A / B**, for the two-variant exercise, then სურათი to export for the AI render.

## What it covers

| Agenda block | What the tool does |
|---|---|
| Day 2, რუკა ენაა / მასტერპლანის ვორქშოპი | **გეგმა** view: zones, paths, an automatic legend with real areas in m². The digital version of the paper masterplan. |
| Block 2, დიდი მასშტაბის სივრცის 3D მოდელირება | **3D** view: მოცულობები, ბილიკები, დიდი მასები, exactly the three things the block names. |
| Block 4, AI ვიზუალიზაცია | **სურათი** exports a PNG of the current view, ready to feed the AI image tool. |

**სურათი names the file after what is in the picture** — `bekura3d-telavi-B.png` from ქალაქი,
`bekura3d-ჩვენი-სკოლა-A.png` from a named plan in the studio. Most browsers save it straight to
the downloads folder without asking; the hint bar names the file so a team knows what to look
for. All three exports (**სურათი**, **შენახვა**, **მონაცემები**) go out through one
`downloadBlob` helper, and the two rules it exists to enforce are worth knowing before anyone
"simplifies" it: the anchor must be **in the document** when it is clicked, and the payload must
be a **blob**, not a `data:` URL. A detached anchor holding a large `data:` URL is dropped by
Chrome without an error — which is exactly how სურათი once produced no file at all while the two
JSON exports beside it worked.

## What students do

1. Pick a colour on the right and give it a name, that is your legend.
2. Drag a rectangle on the map. That is a volume.
3. Select it and set how many floors it has.
4. Draw ბილიკი paths to connect the volumes.
5. Switch გეგმა ⇄ 3D to check the plan reads both ways.
6. Do it again in **ვარიანტი B**, then compare A and B and argue for one.
7. Press **სურათი** and hand the PNG to the AI render step.

The legend and the area totals build themselves, so a team always knows how much of the
site they have used, the number that makes them argue about density instead of guessing.

## Controls

The **i** button in the header (or <kbd>F1</kbd>, or <kbd>?</kbd>) opens the full
sheet inside the app: 39 gestures in six groups, with a drawn mouse showing which
button each one means. It opens by itself the first time a browser ever runs the
app, and never again. The short version:

| Action | Mouse |
|---|---|
| Draw / select | left button |
| Orbit | right button drag |
| Pan | middle drag, or Shift + drag |
| Zoom | wheel |
| Finish a path | `Enter`, or double-click |
| Add to / remove from the selection | `Ctrl` + click |
| Delete selected | `Delete` (takes the whole selection) |
| Copy / paste, across tabs | `Ctrl+C` / `Ctrl+V`, or ასლი / ჩასმა in ფაილი |
| Undo / redo | `Ctrl+Z` / `Ctrl+Y`, or the **⟲ ⟳** buttons beside ფაილი |
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
| `bekura3d.html?demo=1` | loads a worked example, use it to show the class what "finished" looks like |
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
checks nothing external is left referenced. Run `bekura3d.html?selftest=1` afterwards, open it in
a normal browser, or headless:

```bash
chrome --headless=new --enable-unsafe-swiftshader --use-gl=angle --use-angle=swiftshader --window-size=640,400 --virtual-time-budget=4000 --dump-dom "file:///…/bekura3d.html?selftest=1"
```

Keep the **virtual-time budget small (~4 s) and the window small**. The assertions run
synchronously at start-up, so they need almost no budget; a large one just lets the render loop
spin under software WebGL until the run times out and reports nothing. Results are printed as
each check happens, so a throw still shows everything up to the failure plus an `ERR` line.

**Give it a fresh `--user-data-dir`.** The app restores the camera from `localStorage` on
startup, so a profile that has had the app driven in it before will fail the pan assertions —
they check a camera that a previous session already moved. A clean profile per run, and they
are green.

To change which part of a town is shown, regenerate the ground textures, they are OSM tiles
at zoom 16, 1024×1024, about 1820 m across, roughly 1.78 m per pixel.

### The site data

`data/townsdata.json` holds everything real, in metres relative to each town centre and in the
same projection as the ground textures:

| | source | Akhmeta | Telavi | Gurjaani |
|---|---|---|---|---|
| building footprints | OSM vector tiles | 167 | 3,742 | 324 |
| street centrelines | OSM vector tiles | 330 | 640 | 342 |
| terrain, 129×129 grid | SRTM | 535-605 m | 626-845 m | 354-522 m |

Buildings and streets come from **OpenStreetMap's own vector tiles**
(`vector.openstreetmap.org`, shortbread v1, zoom 14, that endpoint serves nothing deeper).
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

Ground textures are separate, `bash data/make-maps.sh` builds both, the drawn OSM map and
the aerial photo under it, at 2048 px per town. Both extents come from the same tile
arithmetic, so the two register by construction rather than by eye and a zone drawn on one
sits on the same roofs on the other. `make-maps.sh map` or `make-maps.sh sat telavi` narrows
it. The satellite pass is optional: without `ground/*-sat.jpg` the app hides the სატელიტი
button and leaves რუკა on its own. **თეთრი ფონი** is a separate switch, not a third
map: it blanks the map **inside the red working-area boundary and nowhere else**, so the map
outside the line is untouched and the site becomes a clean surface to plan on. Switch it off
and the map inside comes back.

It works by painting the ground white in the ground's own shader, testing each fragment
against the working-area ring, rather than by laying a white surface over the ground. That is
not a detail: a street ribbon is flat across its own width, so where the terrain ridges under
one the road clears the ground by about a centimetre. Anything slipped into that gap comes
back through the street in fragments whatever height it is given. Painting the ground has
nothing to compete with.

**The streets and the existing buildings go too**, which whiting the ground alone did not do:
both are their own geometry standing above it, so the sheet went white and the town stayed
drawn straight across it — the map was still readable through the thing meant to hide it.
They are removed two different ways, because they are two different kinds of thing:

- **Streets** are cut in the *street* shader, by the same ring test the ground runs, sharing
  the same uniforms so the two can never disagree about where the edge is. The cut lands
  exactly on the red line. Dropping whole streets instead would erase them far outside the
  area as well, since one street is a single polyline that merely happens to cross it, and
  splitting each one at the boundary would be a lot of code for the same picture. Nothing is
  destroyed: the geometry is untouched and the switch is a uniform, so it comes back in a frame.
- **Existing buildings** are dropped from the geometry instead, and the test tightens from
  "centroid inside" to **any corner inside**, so one straddling the line goes as well. Whole,
  not cut: a wall sliced off in mid-air on the boundary would look worse than the building
  being gone. Removing the footprint also takes its shadow, which a shader cut could not —
  the shadow map is drawn with three.js's own depth material and would not carry the cut,
  leaving a shadow lying on the sheet with nothing above it to cast one.

What survives inside the line is the red boundary itself and the students' own work. The
terrain still shades, so the slope of the site is still readable — the sheet is white paper
laid over the hill, not a flat plane.

## Keeping work when you ship a new build

Work lives in `localStorage`, which on a `file://` page survives overwriting
`bekura3d.html`, so shipping a new build in the tech park does not erase a
team's plan. That covers the common case, but not a fresh laptop, a cleared
browser, or carrying a class's work to another machine.

For those, the **მონაცემები** button writes `bekura3d-data.js`: everything the
app holds, in one file, every town, both variants, the working areas, all
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

### The save format, and how to add a feature without breaking old plans

Every payload the app writes, in `localStorage` and in a `.bekura3d.json` file,
carries its format version as `v`. One constant near the top of the script,
`SCHEMA`, is the version this build writes. A payload with no `v` at all is read
as version 1, which is what every plan saved before this existed looks like.

Three routes bring data in: `localStorage`, an opened file, and the
`bekura3d-data.js` seed. All three go through `readPayload` / `migratePayload`,
so a rule written once applies to all of them and cannot drift between them.
Two directions have to work, because the machines in a workshop are updated at
different moments:

| what arrives | what happens |
|---|---|
| **older data, newer app** | `MIGRATIONS` walks it forward one version at a time. The text as it stood before migration is copied to `<key>-v<n>` first, so a wrong migration is recoverable. |
| **newer data, older app** | It opens. Fields this build has never heard of are kept and written back untouched, and the higher `v` is kept too, so the build that understands them still recognises them. |

**Adding a field needs no migration.** Every reader already guards each field it
takes, and a field this build does not know is carried through by the rule
above. Add it to the object `save()` builds, read it back with the same
`if (typeof o.x === ...)` guard the fields around it use, and you are done.

**Bump `SCHEMA` and write a migration step only when the shape or the meaning of
data that already exists has to change**: a renamed zone id, a field that
changes units, a list that becomes a map. Then add the step to `MIGRATIONS`,
keyed by the version it upgrades *from*, and never delete it afterwards: a
laptop can arrive from any age.

```js
var SCHEMA = 2;
var MIGRATIONS = {
  1: function (o) {          // 1 -> 2
    // ...change the data...
    return o;
  }
};
```

`?selftest=1` asserts all of this: that an unversioned payload reads as
version 1, that an unknown field survives a round trip, that an older build does
not downgrade a newer plan, that corrupt storage is kept for rescue rather than
thrown away, and that the migration chain has no gap in it.

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

MIT. See [LICENSE](LICENSE). Use it, change it, teach with it.

What it bundles is not all MIT: the map data is ODbL, the aerial imagery is Esri's, and
the attribution shown inside the app has to stay there. [NOTICE](NOTICE) sets out each
one.

## Known limits

- **The existing buildings are all one height.** OpenStreetMap carries no height or
  `building:levels` for these towns, so the app extrudes them to a single figure you can change
  with the სიმაღლე slider (default 6 m). The footprints are real; the heights are not claimed
  to be. The app says so on screen.
- **Akhmeta has only 167 buildings** against Telavi's 3,742, that is the state of OSM there, not
  a bug. It matters less here than on a printed map, because students are adding their own masses.
- **Terrain is SRTM at ~14 m per sample**, so it carries the shape of the valley and the slope of
  the town, but not individual terraces or embankments.
- Roads are flat ribbons draped on the terrain, not kerbed or cambered.
- In the **ქალაქი** tab volumes are rectangles only, deliberate for a 60-minute block. The
  **სკოლა** tab is where free-form shaping lives.

## Games inside the planner — ფაილი ▸ თამაში

**ფაილი ▸ თამაში opens a list of all five**, so a student picks a game rather
than landing in whichever was played last.

The games live behind **ფაილი ▸ თამაში**, and they open a **separate world**:
their own document, their own shapes, their own legend. Nothing built in a game
can appear on a plan and no plan can appear in a game — the four architectural
tabs are never touched, and the game is not one of them (no tab lights up while
you are in it). **თამაშის დასრულება** puts you back on the tab you came from,
with your work exactly as you left it. It is deliberately not remembered across
a reload either: a game is a place you go, not a tab you were left on.

The game world has **no sky** — flat slate, no horizon. A horizon tells the eye
it is standing somewhere, which is the wrong idea when the whole point is that
this place has nothing to do with the four sites. The grid is turned up with it
(minor 0.22 to 0.55, major 0.42 to 0.90): the faint lines that read correctly as
a studio floor under a bright sky vanish against grey, and a board with an
invisible grid is no board.

While a game is on, the planner's furniture goes away: the four tabs, the
variants, the zoning and path tools, the figure for scale, the paint bucket, and
save / open / clear. What is left is the modelling rail, the view controls, undo
and the game itself. It is one class on the body rather than a dozen elements
toggled from JS, so leaving a game cannot half-restore the interface.

**Every game is played inside a marked plot** — a cyan line on the ground, sized
per game: 90 x 90 m for the telephone and the shadow plan, 80 x 80 for the duel,
one pedestal for the decoy, and the whole board for the sun duel, where the cyan
cage *is* the rule — eighty metres square and six storeys tall.
Without a boundary the board is an infinite plane, which breaks the games twice
over: there is no brief to build against, and a model put down three hundred
metres away still scores, because the comparison normalises position. Placing and
dragging are clamped to the line; the gizmo can still push a shape past it, so the
plot is checked once more before anything is handed over — and the stray shape is
selected for you rather than merely complained about.

In four of the five there is no game board and no block grid: you build with the
primitives, the gizmo, face and edge editing and the booleans, exactly as you
would on a plan. The game only decides **what the other player is allowed to
see**, and how the two models are compared.

- **გეგმის ტელეფონი** — they get a rendered plan AND a south elevation. Both
  carry a scale bar, and the plan carries a north point, so a copy that is right
  in every proportion but wrong in size is the player's mistake rather than the
  drawing's.
- **ჩრდილების გეგმა** — the top view only, with shadows. No elevation. Height
  has to be read off the shadow.
- **მოდელირების დუელი** — they see the model itself, in 3D, for fifteen seconds;
  then it disappears and they rebuild it from memory. During those fifteen
  seconds the model cannot be touched: the camera works in full, and nothing
  else does. The point of the phase is to walk round it and look.
- **თაროზე ნაკლული** — four sculptures the program built and one a person built
  stand on a shelf; the other player says which hand was human. Guess right and
  the guesser scores, guess wrong and the builder does, so it is worth building
  something that does not look built. The four are drawn from **nine families**
  without replacement, so they are always four different kinds of thing, and they
  are the same four the student was shown while filling the gap — you are judged
  against the company you were told to imitate. Each is generated from the same
  primitives a student has, put together by the same moves — scale one, stack
  two, sink a hole through it — because a pile of random boxes would be spotted
  at a glance.
  **The shelf also remembers.** Every finished piece is kept on that laptop, and
  later rounds stand up to two of them out as the program's own — so a class
  playing all afternoon ends up competing against itself, and the best decoy the
  generator ever gets is one a child actually made. The question does not change:
  it is still "which of these did the other player build just now", and the panel
  says that older work may be on the shelf. Only a finished piece is kept, never
  an empty pedestal, and only its geometry: a name, a legend or a painted face
  would be a tell, and would leak one student's plan into another's game.

The three that are scored on a rebuild — the telephone, the shadow plan and the
duel — are won at **60% overlap or better**. That number is measured, not
chosen: the comparison samples on an eighteen-cube lattice, so it resolves in
steps of about eleven points, and 60 sits in the gap between two of them. A mass
rebuilt a fifth too narrow scores 78 and wins; four blocks with one missing
scores 67 and wins; the same model with its tower mirrored to the far end scores
53 and loses, which is right, because a mirrored building is exactly the mistake
a plan and an elevation exist to catch.

**მზის დუელი** is the exception, and is played on a board rather than modelled:

- Ten cells by ten, eight metres each. **Three towers each**, one to six storeys,
  placed alternately, and the panel says whose turn it is. You may not build in
  either garden.
- The sun **walks the whole day** on a twelve-second loop while you play — a
  winter sun, about forty degrees at noon, because daylight rights are argued on
  the worst day of the year. Watching the shade sweep across the board is the
  lesson, and it needs no explaining.
- The score is the percentage of **garden-cell-hours** still in sun, sampled at
  five hours of the day. It is a day, not an instant, which is what a
  right-to-light argument actually measures. Whoever keeps more sun wins.
- The board is symmetric by construction, so whatever one player can do to the
  other, the other can do back. The version that briefly replaced this one was
  not: its gardens sat outside the buildable strip, so at any sun angle one of
  them could not be shaded at all — and the player pressing the score button also
  owned the slider that decided which.
- The board has its own ground and its own eight-metre cells, so the shadows are
  visible across the whole site rather than only where they happen to cross a
  garden — which is the thing the game is about.
- There is nothing to model, so the modelling rail goes with it. A cell, a
  storey slider and two scores are the whole interface.

### Two ways to play

**Hot seat.** One builds, presses **გადაეცი მეორეს**, the board clears, and the
second player takes the mouse. **ორიგინალის ჩვენება** puts the original back
afterwards so the two can be compared by eye as well as by number. Always works,
needs nothing.

**Two laptops.** Pick a game, then **ოთახის გახსნა**: type a name and wait. On
the other laptop, **სხვას შემოუერთდი** shows every open room by its host's name
and which game it is running; knocking asks, and the host says yes or no. Nobody
is dropped into a game with a stranger without the host agreeing, and no child
has to read a room number aloud across a classroom.

The carrier is the same classroom server the standalone page uses — run
`თამაშის-სერვერი.cmd` on the trainer's laptop. From there, either:

- **open the planner from the server** — `http://<the trainer's address>:8830/bekura3d.html`
  — and there is nothing at all to configure, because the page's own origin is
  the server; or
- **keep using the copy on the Desktop** and type the server's address once when
  the lobby asks. It is remembered. The server sends the header that makes a
  `file://` page allowed to ask.

Each game hands over what it should and nothing more: the telephone and the
shadow plan send the drawings, the duel sends the model for its fifteen seconds,
the shelf sends the five works, and the sun duel sends one tower at a time. The
panel always says whose turn it is, and the side that is not acting is told to
wait rather than left with buttons that would break the round.

Scoring is volume overlap, not a field-by-field diff: a torus and the same ring
cut out of a box are the same object to anyone looking, and only overlap says so.
Position is deliberately ignored — rebuilding it a few metres to the left is not
a mistake worth marking — but size is not.

## One mini game — `თამაში.html`

A separate page, built by `bash build-game.sh` from `game.html`, opened by
double-clicking exactly like the planner. **Deliberately not part of
`bekura3d.html`**: that file is 13.5 MB and holds a team's work, and a game has
no business being able to break it. The games share nothing with it but three.js.

The three block-grid games that were once also on this page — ტელეფონი, დუელი and
თაროზე ნაკლული — have been **removed** from it and rebuilt inside the planner so
they use the real modelling tools. They are not kept in both places: two games
with the same name in two different files is exactly how somebody opens the old
one and reasonably concludes nothing was ever done. The page now points at the
planner where they went.

მზის დუელი now exists in **both** places, and on purpose. The grid is genuinely
the right vocabulary for it — it is about massing and shadows, not about
modelling — so the planner's copy is the same board with the same rules, reached
through ფაილი ▸ თამაში like the other four. The lobby has moved across with it:
all five of the planner's games can now be played host-and-join over the same
server, so this page is no longer the only way to play across a room. It is kept
because it is small — a few hundred kilobytes against fourteen megabytes — and
because a game has no business being able to break a file that holds a team's
work.

- **მზის დუელი.** Each side owns a garden. You place towers to take the other
  garden's sun without shading your own, and the panel scores the daylight each
  garden keeps across five hours. It is the right-to-light argument — the thing
  that makes tall buildings political — played in four minutes. The sun is a
  **winter** one, about 41° at noon and 23° morning and evening: daylight rights
  are always argued on the worst day of the year, and a summer sun overhead casts
  stubs that make a dull duel. Whether a garden cell is lit is answered by walking
  a ray toward the sun and asking what is in the way, so the score is exact rather
  than sampled off the shadow map.
- **ჩრდილების გეგმა (the shadow-plan variant).** The same game with one thing
  taken away and one thing added: **no elevation at all**, just the top view —
  but the sun is on. A plan cannot tell you how tall anything is; three towers
  of 30 m, 14 m and 6 m are three identical squares. With shadows they are three
  very different drawings. The sun is fixed at **35 degrees**, so a shadow is
  **1.43 times** the height that cast it, and the drawing carries a 10 m grid to
  count against — the rule is learnable once and then applies to every drawing.
  It is also how heights are read off an aerial photograph, which surveyors
  actually do. Outlines are dropped from this one on purpose: an edge round
  every hidden face would give away the massing the shadow is there to hide.
- **გეგმის ტელეფონი.** One player builds a massing. The other is handed only what
  a drawing carries — the footprint from above and the silhouette from the south —
  and has to put the volume back. The score is the difference in storeys. What the
  drawing *drops* is the whole lesson, and losing marks to it is more convincing
  than being told.

- **მოდელირების დუელი.** Trading licks, in blocks. One player has a minute to
  build something awkward; the other studies it in full 3D for fifteen seconds,
  then it **disappears** and they rebuild it from memory against a clock. Then
  they swap, and the two accuracy scores are the match. It is spatial memory
  rather than drawing convention, which is why it is its own game and not a
  harder setting of the telephone.
- **თაროზე ნაკლული.** A Turing test with blocks. Four sculptures the program made
  and one a person made stand on a shelf; the other player has to say which hand
  was human. Guess right and the guesser scores, guess wrong and the builder
  does — so it is worth building something that does not look built. It works
  only because the generator has six real families with real rules (setback
  tower, L and U plans, ziggurat, twin towers with a link, courtyard block, a
  short walk that leaves a spine); a pile of random cubes would be spotted at a
  glance and the game would be over in one look.

### Playing between laptops, with no internet

Three ways, and the games do not know which is in use:

- **ადგილობრივი** — one laptop, pass the mouse. Always works, needs nothing.
- **კოდი** — each move becomes a short string students read out or paste to each
  other. No network at all. Turn-based, and fine for the telephone game.
### The room, and who is in it

A network game is **named, and the host decides**. The host types a name and
opens a room; joiners see a live list of open rooms with the host name and which
game is running, and pick one. Knocking sends a request the host sees by name —
**გიორგი ითხოვს შემოერთებას** — with დაშვება and უარი. Nobody is dropped into a
game with a stranger without the host agreeing, and there is no room number for a
classroom to get wrong on both sides. A host that goes quiet drops off the list
after twenty-five seconds, so a laptop closed mid-game does not sit there all
afternoon.

- **ქსელი** — the trainer runs **`თამაშის-სერვერი.cmd`** and the room joins by the
  address it prints. That server is PowerShell's own `HttpListener` in about a
  hundred lines: **no Node, no Python, no install, no admin** for the common case.
  It keeps one append-only message log per room in memory and clients poll it —
  short polling rather than sockets on purpose, since these games move once per
  turn and a socket server in PowerShell is a great deal of code for no gain.

Nothing is written to disk and no room survives closing the window. A room is a
lobby, not a save file.

**If it says only this laptop can reach it**, Windows would not let a non-admin
process listen for the whole network. Either run the `.cmd` as administrator, or
grant it once from an admin console:

    netsh http add urlacl url=http://+:8830/ user=Everyone

Expect a one-time Windows Firewall prompt; say yes for a private network. A page
served this way has a different browser origin from the double-clicked planner,
so a game cannot see students' saved plans — which is fine, because it has no
business seeing them.

`game.html?selftest=1` runs 4 assertions over the parts with no pixels in them:
where shade falls, what a drawing keeps and drops, and whether a code survives
Georgian and comes back the same.
