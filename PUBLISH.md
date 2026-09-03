# Publishing this repository

Everything local is done and verified. One step is left, and it needs your GitHub
login, which Git Credential Manager will not hand over non-interactively.

### Create the repository

<https://github.com/new>

- Owner `gbekura`, name **`Bekura3D`**
- **Public**
- Add **no** README, .gitignore or licence. This repository already has all
  three, and an initial commit on GitHub's side would collide with the push.

Then say the word and I will run:

```
git push -u origin main
```

The credential window appears on that first push; approve it once and the repo
is live.

---

### A note on the remotes, because they were crossed

After the folder renames, this repository's `origin` pointed at
`gita_architech_presentations.git` and the decks repository's pointed at
`presentations.git`, a name that no longer exists. A push at that moment would
have put the software into the decks repository. Both are now corrected:

| repository | remote |
|---|---|
| `GitHub/Bekura3D` | `github.com/gbekura/Bekura3D.git` |
| `GitHub/gita_architech_presentations` | `github.com/gbekura/gita_architech_presentations.git` |

Worth a glance before any push: `git remote -v`.

### What is in the first commit

Two commits, a fresh history. It is **not** filtered from the decks repository,
deliberately: that history contains a tracked Chrome profile with Cookies and
Login Data, and a filtered copy would have carried it. Nothing of the sort is
here, checked before committing.

28 files, 42 MB, of which `bekura3d.html` is 13.3 MB. That bundle is the point —
students double-click it, so it ships built. `?selftest=1` runs 83 assertions in
the page and all 83 pass on this commit, rebuilt after the folder rename.

Gitignored: the tile cache (`data/tiles/`, a few hundred megabytes of somebody
else's tiles that `make-maps.sh` refills), the Chrome profile `make-data.sh`
leaves behind, and `bekura3d-data.js`, which is a trainer's own saved work.

### Telling the tech park

```
git clone https://github.com/gbekura/Bekura3D.git
```

Open `bekura3d.html`; `git pull` for updates. A pull cannot overwrite a team's
work — that lives in browser storage and in `bekura3d-data.js`, which is
gitignored.
