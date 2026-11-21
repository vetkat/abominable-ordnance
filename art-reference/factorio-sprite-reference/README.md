# Factorio sprite reference (Abominable Ordnance, v3 art)

Vanilla Factorio 2.x sprites (Wube Software), exported as art reference only.
Do not ship or commit these files.

## Layout

- `entities/<mod asset (vanilla source)>/<vanilla entity>/`
  - `*--frame.png`: the first frame of one layer, at in-game high resolution.
  - `*--sheet.png`: the whole sheet, scaled to at most 1600 px. It shows
    the rotations and animation frames.
- `icons/`: item icons at 64 x 64 (the largest mipmap).

## Factorio art conventions

- The camera looks down at a steep angle, in a 3/4 top-down view, not an isometric one.
- The light comes from the upper left. Shadows fall to the lower right and are separate layers.
- High-resolution sprites use 64 px for each tile. A 3x3 machine is about 192 x 192 px,
  plus extra height for parts that stand up.
- Machines are drawn in layers: base, animation, working glow, shadow, pipes for each direction.
- In `entities/monsters nauvis/coloured/`, the biters, spitters and spawners carry the
  game's tint for each size, so they show the real colours. One file per size and
  animation, plus `lineup--*.png` files that show all four sizes at their relative in-game
  scale (0.5, 0.7, 1.0 and 1.2). Use these, not the grey frames in `biter/` and `spitter/`.
- The worm frames in `worm/` lack their size colours. For worm colours, use the icons
  in `icons/` or in-game screenshots.
- The tone is grimy and industrial, with worn metal and muted colours. The creatures look
  organic and fleshy.

Run `python3 -I export_sprites.py <Factorio>/data <out-dir>` to make the set again, then
`python3 -I composite_monsters.py <Factorio>/data "<out-dir>/entities/monsters nauvis/coloured"`.

## Blender render scripts

`blender/` holds scripts that render a Blender model as Factorio sprite sheets:

1. `render_factorio.py` runs inside Blender. It renders the frames of the model and
   of its shadow for each direction.
2. `pack_sheets.py` packs the frames into sheets, `.lua` sidecars for
   `util.sprite_load`, and a draft icon with 4 mipmaps.

Each file starts with its usage. `python3 -m pytest blender` runs the tests of the
layout maths.

Warning: `render_factorio.py` is not yet tested in Blender. The camera pitch (45°)
and the sun direction are guesses, and nobody has compared them with vanilla art.
Before you model much, render a simple box. Put it in the game next to a vanilla
machine. Then change `--pitch` until the two match.
