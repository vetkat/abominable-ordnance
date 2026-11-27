# Abominable Ordnance: graphics for design version 1

Date: 2026-11-26. Status: draft. The maintainer chose every asset in chat
on 2026-11-26. This spec has had no EGM review yet. Run
`/egm:egm-review` on it before superpowers writing-plans turns it into a
plan.

## Purpose

Release 1.0.0 uses tinted vanilla graphics for every building, item and
technology. This spec replaces them with openly licensed art that looks
like Factorio, for the content of design version 1. It ships as release
1.1.0, because new graphics add a feature and break no save.

Goals:

1. The four buildings, the lifecycle items, the larva rockets, the wards
   and the four technologies get their own graphics.
2. A new species or hybrid needs no new icon art for its larva rocket:
   the icon is layers that the mod tints.
3. Every asset has its source, author and licence in `THIRD_PARTY.md`.
4. Everything works the same with and without Space Age.

Non-goals:

- Loaded monsters stay tinted vanilla units until design version 3. The
  maintainer confirmed this on 2026-11-26.
- No sprite tooling. The scripts that made the icons are in `art/` as a
  record, with the full-size renders. They have no tests and do not
  ship. `ROADMAP.md` keeps the tooling, and its tests, under 3.0.0.

## Decisions

The maintainer made these choices on 2026-11-26.

| Thing | Art | Source | Footprint |
| --- | --- | --- | --- |
| Breeding pod | Pathogen lab | Hurricane046 | 5×5 (drawn for 7×7) |
| Incubator | Oxidizer | Hurricane046 | 4×4 (drawn for 4×4) |
| Loading chamber | Simulation chamber | snouz (Panglia) | 4×4 (drawn for 6×6) |
| Larva launcher | Rocket turret, lettering removed | hlittlezero | 3×3 (drawn for 4×4) |

- Machines are at most 5×5. Smaller is better where the art allows it.
- Item icons are Blender renders in a grimy Factorio style: larva (the
  "disgusting" version F), egg (version G, first pass) and loaded larva
  (capsule H). The biter colour is orange.
- The stasis ward is an amber canister. The cryo ward is the same
  canister in frosted blue. It looks related because it does the same
  thing for longer.
- The larva rocket is the D1 design: a gunmetal grey body with a glass
  window, wide bands, and a pointed steel nose.
- The Panglia style is the reference for future buildings and items.

## Assets

All assets are in the repository on the branch `art/v1-graphics`.
`graphics/` ships in the mod zip. `sound/` does not ship yet (see
"The mod zip").

### Buildings

| Folder | Sheet | Frame (px) | Layout | Notes |
| --- | --- | --- | --- | --- |
| `graphics/entity/breeding-pod/` | `pathogen-lab-animation.png` | 500×500 | 8×8, 60 frames | scale 0.5 at 7×7, speed 0.15, shift `util.by_pixel(0, -16)` |
| | `pathogen-lab-emission.png` | 500×500 | 8×8, 60 frames | `draw_as_glow` |
| | `pathogen-lab-shadow.png` | 800×700 | 1 frame | `draw_as_shadow` |
| | `pathogen-lab-frozen.png` | 500×500 | 1 frame | Space Age `frozen_patch` |
| `graphics/entity/incubator/` | `oxidizer-base.png` | 275×313 | 8 columns, 60 frames | scale 0.5, shift (2.5/64, 2.5/64) tiles |
| | `oxidizer-emission.png` | 280×320 | 9 columns, 60 frames | `draw_as_glow` |
| | `oxidizer-shadow.png` | 372×280 | 1 frame | `draw_as_shadow`, shift (51/64, 31/64) tiles |
| `graphics/entity/loading-chamber/` | `simulation-chamber-base.png` | 512×512 | 1 frame | scale 0.5 at 6×6 |
| | `simulation-chamber-shadow.png` | 512×512 | 1 frame | `draw_as_shadow` |
| | `simulation-chamber-glow.png` | 512×512 | 1 frame | `draw_as_glow` |
| | `simulation-chamber-screen-animation.png` | 64×64 | 32 columns, 255 frames | `draw_as_glow`, shift (-2, -1.75) tiles at 6×6 |
| | `simulation-chamber-layer1.png` to `layer4.png` | 512×512 | 1 frame each | the creature in the glass pod, in four growth stages |
| | `simulation-chamber-remnants.png` | 512×512 | 1 frame | corpse |
| `graphics/entity/larva-launcher/` | `rocket-turret-attack.png` | 512×512 | 8×8, 64 directions | scale 0.3 for 3×3 |
| | `rocket-turret-attack-shadow.png` | 512×512 | 8×8, 64 directions | `draw_as_shadow`, shift (2, 0) tiles at 4×4 |

To fit the art to a smaller footprint, multiply the scale by
`footprint / drawn size`, and multiply each shift by the same factor. For
example, the breeding pod is drawn at 0.5 × 5 / 7 ≈ 0.357.

The rocket turret also has a fold animation in its source mod. An
artillery turret has no fold animation, so the branch leaves those sheets
out.

### Icons (64 px)

| File | Use | Tint |
| --- | --- | --- |
| `breeding-pod.png`, `incubator.png`, `loading-chamber.png`, `larva-launcher.png` | building items | none |
| `egg-biter.png`, `egg-spitter.png` | eggs | none |
| `larva-biter.png`, `larva-spitter.png` | larvae | none |
| `loaded-larva-biter.png`, `loaded-larva-spitter.png` | the larva part of a loaded-larva icon | none |
| `stasis-ward.png`, `cryo-ward.png` | wards, and the ward layer of a warded item | none |
| `larva-rocket-base.png` | larva rocket, layer 1 | none |
| `larva-rocket-band-rear.png` | layer 2 | parent A, or the species |
| `larva-rocket-band-front.png` | layer 3 | parent B, or the species |
| `larva-rocket-larva.png` | layer 4, the larva behind the glass | parent A, or the species |

The band and larva layers are pale, so the game's tint gives the colour.
The species tints in the previews were these:

| Species | Tint (r, g, b) |
| --- | --- |
| Biter | 1.00, 0.52, 0.10 |
| Spitter | 0.45, 0.85, 0.20 |
| Worm (version 2) | 0.62, 0.38, 0.95 |
| Pentapod (version 2) | 0.20, 0.80, 0.85 |
| Hatchling (version 3) | 0.95, 0.15, 0.12 |

Put the tints in `core/balance.lua` or next to the species list, not in
the prototype code.

### Technology icons (256 px)

`graphics/technology/monster-husbandry.png`, `ordnance-loading.png`,
`larva-rockets.png` and `stasis-ward.png`.

### Sounds

`sound/loading-chamber/simulation-chamber-working.ogg` and
`simulation-chamber-idle.ogg`, for the loading chamber's
`working_sound`.

## Prototype changes

The prototype code builds these looks today from vanilla prototypes:
`looks()` in `data.lua` passes the centrifuge, assembling machine 3 and
biochamber or chemical plant, and `core/prototypes/launcher.lua` copies
the artillery turret. Replace each with a look table built from the files
above.

- **Machines.** Build a `graphics_set` with `animation` layers (sheet,
  emission, shadow), and `working_visualisations` where the art has them.
  Set `collision_box` and `selection_box` for the new footprints. The
  breeding pod grows from 3×3 to 5×5 and the loading chamber to 4×4.
- **Breeding pod with Space Age.** Today it copies the biochamber with
  Space Age. The new art is the same in both modes. `frozen_patch` uses
  `pathogen-lab-frozen.png`.
- **Larva launcher.** It stays an artillery-turret copy in both modes.
  Put the attack sheet in `cannon_base_pictures` (a RotatedSprite with 64
  directions) and the shadow sheet as a `draw_as_shadow` layer beside it.
  Leave `cannon_barrel_pictures` empty or remove it. Check in the game
  that the base does not appear to turn with the pods. If it does, cut a
  static base for `base_picture`.
- **Icons.** `Common.icon(path, tint)` makes a 64 px icon today. Add a
  helper for layered icons. The larva rocket has four layers. A warded
  item shows the item icon with a small ward icon in a corner.
- **Remnants.** The loading chamber gets `simulation-chamber-remnants.png`.
  The other buildings keep their vanilla remnants for now.

Look up each prototype field with `make api NAME=<name>` before you use it.
On 2026-11-26 the API download failed in the cloud session, so the field
names above come from the online API docs.

## Still to make

These things have no new art yet. They keep tinted vanilla graphics until
they get some:

- The larva rocket casing (`ao-larva-rocket-casing`).
- The larva targeting remote and its flare.
- The launcher speed and range upgrade technologies.
- The payload badges on loaded-larva icons. The previews use stand-in
  badges. Use the vanilla explosive rocket, poison capsule and sulfuric
  acid icons from `__base__`, small in a corner of the loaded-larva icon.

## The mod zip

`tools/package.py` ships `graphics/` but not `sound/`. Add `sound/` to
`OPTIONAL` in `tools/package.py`, test-first, in the same PR that wires
the chamber sound. The graphics add about 26 MB to the zip.

CC BY and MIT need the credits and the licence text in every copy of
the art. The zip does not ship `THIRD_PARTY.md` today. Add
`THIRD_PARTY.md` and `LICENSE-third-party-MIT.txt` to `REQUIRED` in
`tools/package.py`, test-first, before any release that ships the art.

## Credits and licences

`THIRD_PARTY.md` lists each source. In short:

- Pathogen lab and oxidizer: © Hurricane046, CC BY 4.0. Changes: the
  oxidizer sheets come from the Nullius Hurricane Reskins repack.
- Simulation chamber and its sounds: snouz, from the Panglia mods, MIT
  as stated on the mod portal. The download has no licence file, so the
  maintainer takes the portal licence as the grant (2026-11-27). The
  building contains parts of Hurricane046's art, CC BY 4.0.
- Rocket turret: hlittlezero, MIT as stated on the mod portal. The
  download has no licence file, so the maintainer takes the portal
  licence as the grant (2026-11-27). Changes: the "Hlittlezero" lettering is
  removed from every frame.
- Item and technology icons: made for this mod.

## Checks before merge

Nothing from this work merges before you complete every item here.
The maintainer asked for this on 2026-11-26.

- [ ] Replace the stand-in payload badges with the vanilla icons.
- [x] The maintainer confirms the MIT licences of the Panglia and
  hl-Rocket-turret art. On 2026-11-27 the maintainer took the mod portal
  licences as the grant. `LICENSE-third-party-MIT.txt` has the text.
- [ ] The mod zip ships `THIRD_PARTY.md` and
  `LICENSE-third-party-MIT.txt` (see "The mod zip").
- [ ] An EGM review of this spec, then a plan from writing-plans.
- [ ] The wiring follows `superpowers:test-driven-development`.
- [ ] `make check` passes, with and without Space Age.
- [ ] In the game, with and without Space Age: each building lines up
  with its footprint and shadow, animates, and glows at night. The
  launcher aims in all directions. Each icon reads well in the inventory,
  on belts and in the research screen. The larva rocket tints are
  correct for each species.
- [ ] The CLAUDE.md review rounds for the changed paths. They include
  compatibility with other mods and with Space Age.
- [ ] `CHANGELOG.md`, `ROADMAP.md` and `docs/design.md` describe what
  shipped.
