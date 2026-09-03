# Publishing this repository

Everything local is done. Three steps remain, and each needs your GitHub login,
which I cannot use non-interactively — Git Credential Manager wants a window.

**The order matters.** `gbekura/Bekura3D` is currently the presentations repo, so
that name has to be freed before it can be reused, or a push could land the wrong
content in the wrong place.

### 1. Free the name

<https://github.com/gbekura/Bekura3D/settings> → Repository name → `presentations`
→ Rename.

That repo's local remote is already repointed to `.../presentations.git`, so it
keeps working the moment you do this.

### 2. Create the new repository

<https://github.com/new>

- Owner `gbekura`, name **`Bekura3D`**
- **Public**
- Do **not** add a README, .gitignore or licence — this repository already has
  all three, and an initial commit on GitHub's side would collide with the push.

### 3. Push

```
cd C:\Users\PARALEL\Documents\GitHub\Bekura_3D
git push -u origin main
```

The credential prompt appears on the first push.

---

### What is in the first commit

One commit, a fresh history. It is **not** filtered from the presentations
repository, deliberately: that repository's history contains a tracked Chrome
profile with Cookies and Login Data, and a filtered copy would have carried it.
Nothing of the sort is here — checked before committing.

27 files, 42 MB, of which `bekura3d.html` is 13.3 MB. That bundle is the point:
students double-click it, so it ships built.

Excluded by `.gitignore`: the tile cache (`data/tiles/`, a few hundred megabytes
of somebody else's tiles that `make-maps.sh` refills), the Chrome profile
`make-data.sh` leaves behind, and `bekura3d-data.js`, which is a trainer's own
saved work.

### Afterwards

Rename the local folder to match, from a shell that is not inside it:

```
ren "C:\Users\PARALEL\Documents\GitHub\Bekura3D" presentations
```

And tell the tech park:

```
git clone https://github.com/gbekura/Bekura3D.git
```

then open `bekura3d.html`, and `git pull` for updates. A pull cannot overwrite a
team's work — that lives in browser storage and in `bekura3d-data.js`, which is
gitignored.
