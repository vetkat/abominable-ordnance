# Abominable Ordnance art sources

These files made the v1 graphics in `graphics/`. They come from a
claude.ai cloud session, so the scripts use paths under `/home/claude/`.
Change those paths before you run them.

The scripts record how we made the art. They have no tests. They get
tests when we rebuild the sprite tooling (see the 3.0.0 section of
`ROADMAP.md`). The mod zip does not ship this
folder.

## Scripts

- `scripts/icons/blender_icons.py`: the larva, egg and loaded larva
  (capsule) icons. The `COL` table has the colour per species, and it
  includes `neutral`.
- `scripts/icons/blender_items2.py`: the wards and the larva rocket.
  `rocket-tint` renders the tint layers one at a time. Set `PART` (for
  example `larva`, `band_rear`, `band_front`), `BODY=grey` and
  `BANDW=0.24`. Without `PART` it renders the base layer.
  Example:

  ```sh
  PART=larva BODY=grey BANDW=0.24 PYTHONPATH=. \
    python blender_items2.py rocket-tint neutral out.png
  ```

- `scripts/icons/tint_preview.py`: the species tint palette and the tint
  previews.
- `scripts/icons/*_sheet.py`, `combined.py`, `body_compare.py`: contact
  sheets for the comparisons.
- `scripts/tech/tech.py`: the four 256 px technology icons, built from
  the renders and the building sheets.
- `scripts/detext/detext.py`: removes the "Hlittlezero" lettering from the
  rocket turret frames. It finds the letters with an OpenCV black-hat
  filter and paints over them with OpenCV.
- `scripts/workbench/pack.py`: packs sprite sheets into small WebP files
  for the workbench.

## Requirements

- Python 3.11 or later, with `pip install bpy==5.2.4 pillow numpy`.
  The Blender module (bpy) renders headless with Cycles.
- `opencv-python-headless` for `detext.py`.
- Run the scripts with `PYTHONPATH=.` from their folder, because they
  import each other.

## Renders

The full-size renders. The repository icons are these renders at 64 px:

- `renders/icons/bl/`: larva, egg and capsule for biter and spitter.
- `renders/icons/bl3/`: the stasis ward and cryo ward canisters.
- `renders/icons/bl4/`: the D1 rocket designs.
- `renders/icons/bl7/`: the fixed larva tint layer.
- `renders/final/rocket/`: the four rocket tint layers at 640 px.
- `renders/tech/`: the technology icon options. `final/` has the chosen
  ones.

## Workbench

`workbench-site/` is the source of the "Abominable Ordnance Machines"
workbench page: open `index.html` from a local web server, for example
`python3 -m http.server`.

## Licences

The scripts and own renders have the same licence as the mod. The
workbench assets come from the third-party art in `THIRD_PARTY.md`, with
the same credits and licences.
