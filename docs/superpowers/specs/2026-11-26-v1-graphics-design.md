# Abominable Ordnance: graphics for design version 1

Date: 2026-11-26, revised on 2026-11-27 in four EGM rounds. Status:
reviewed, ready for a plan.
The maintainer chose the art on 2026-11-26. The reviews are in
`docs/superpowers/reviews/2026-11-27-v1-graphics-review-report.md`.

## Purpose

Version 0.9.0 uses tinted copies of vanilla graphics for every building,
item and technology of the mod. This spec replaces most of them with
openly licensed art for the content of design version 1. It ships in
release 1.0.0, because each major release ships with its own graphics. The
maintainer withdrew the first 1.0.0, without the art, on 2026-11-27. Three
machines get bigger, so the release can break old saves and blueprints
(see Risks). The mod description warns about this until 3.0.0.

A design version is a set of game content from `docs/design.md`. Release
1.0.0 shipped design version 1. Releases 2.0.0 and 3.0.0 ship design
versions 2 and 3. `ROADMAP.md` says that each major release ships with
graphics for its new content.

Goals:

1. The four buildings, the eggs, the larvae, the loaded larvae, the wards
   and four technologies get their own graphics.
2. The loaded-larva icon is layers that the mod tints per species. A new
   species, or a hybrid of two species in design version 2, needs no new
   art for it. Eggs and larvae have one coloured icon per species.
3. The mod zip carries the credits and the licence text for every piece
   of third-party art that it ships.
4. Everything works the same with and without Space Age.

Non-goals:

- Loaded monsters stay vanilla units until design version 3.
- No sprite tooling. The scripts that made the icons are in `art/` as a
  record, with the full-size renders. They have no tests and do not ship.
  `ROADMAP.md` keeps the tooling, and its tests, under 3.0.0.
- No changes to recipes, costs or crafting numbers.

## Terms

- **Egg, larva.** Items of the lifecycle. An egg hatches into a wild
  monster when it spoils. The incubator turns eggs into a larva.
- **Loaded larva.** A larva packed with one payload (explosive rocket,
  poison capsule or sulfuric acid) in a larva rocket casing, in the
  loading chamber. In the code it is one ammo item per species and
  payload (`rocket()` in `core/prototypes/ordnance.lua`). The larva
  launcher fires it. In this spec, "loaded larva" and "larva rocket" name
  that one item.
- **Larva rocket casing.** The empty rocket. It is an ingredient of the
  loaded larva, and a separate item.
- **Payload badge.** The vanilla icon of the payload, small in a corner of
  the loaded-larva icon. The code has it today.
- **Ward.** The stasis ward and the cryo ward slow the spoil timer of the
  item they wrap. A warded item shows a small ward icon in a corner.
- **Drawn for N×N.** The footprint in tiles that the artist drew the
  building for. The art then fills an N×N area at its source scale.

## Decisions

| Thing | Art | Source | Drawn for | Ships at |
| --- | --- | --- | --- | --- |
| Breeding pod | Pathogen lab | Hurricane046 | 7×7 | 5×5 |
| Incubator | Oxidizer | Hurricane046 | 4×4 | 4×4 |
| Loading chamber | Simulation chamber | snouz (Panglia) | 6×6 | 4×4 |
| Larva launcher | Rocket turret, lettering removed | hlittlezero | 4×4 | 3×3 |

The maintainer decided:

- Machines are at most 5×5. Smaller is better where the art allows it.
- The Panglia style is the reference for later buildings and items.
- The biter has an orange colour and the spitter a green one.
- The stasis ward icon is an amber canister. The cryo ward icon is the same
  canister in frosted blue.
- The loaded larva is a gunmetal grey rocket with a glass window, two
  bands and a steel nose. The mod tints the bands and the larva.
- The launcher stays a copy of the vanilla artillery turret, with and
  without Space Age.
- Art from other mods is fine, edited or not, when its licence allows it
  (2026-11-27). For the two MIT sources without a licence file, the
  licence on the mod portal is the grant (2026-11-27).

The author of this revision decided these, and the maintainer can
reverse each one:

- **The loaded larva uses the rocket icon.** The capsule renders
  (`loaded-larva-*.png`) wait in `art/waiting/` for a separate
  loaded-larva item, for example the artillery shells of design
  version 2. Reason: the
  loading chamber makes the loaded larva with a rocket casing, and the
  launcher fires it.
- **The casing uses the rocket's base layer alone.** It shows the empty
  grey rocket, so the casing no longer needs new art.
- **The chamber shows one creature layer.** Layer 4, the full creature,
  shows while the chamber works. Layers 1 to 3 need recipe tints that the
  mod's recipes do not have, so they wait in `art/waiting/`. In the source
  mod, `apply_recipe_tint` colours each layer with a colour of the recipe in
  progress. Without recipe colours, the layers would show white.
- **No frozen patch.** The breeding pod has no `heating_energy`, so it
  never freezes on Aquilo. `pathogen-lab-frozen.png` waits in
  `art/waiting/`.

## Assets

`graphics/` holds every file that ships. `sound/` holds the chamber
sounds, which ship from this release on. `art/` holds the scripts, the
full-size renders and the workbench page. `art/waiting/` holds the
source files that wait for later use: `pathogen-lab-frozen.png`,
`simulation-chamber-layer1.png` to `layer3.png`, and
`loaded-larva-biter.png` and `loaded-larva-spitter.png`. `art/` never
ships.

### Buildings

Source values are for the drawn size, as the source mods use them. A
shift is in tiles.

| Sheet | Frame (px) | Frames | Line length | Speed | Source scale | Source shift |
| --- | --- | --- | --- | --- | --- | --- |
| `breeding-pod/pathogen-lab-animation.png` | 500×500 | 60 | 8 | 0.15 | 0.5 | (0, -0.5) |
| `breeding-pod/pathogen-lab-emission.png` | 500×500 | 60 | 8 | 0.15 | 0.5 | (0, -0.5) |
| `breeding-pod/pathogen-lab-shadow.png` | 800×700 | 1, repeated 60 | 1 | 0.15 | 0.5 | (0, -0.5) |
| `incubator/oxidizer-base.png` | 275×313 | 60 | 8 | 0.3 | 0.5 | (0.0391, 0.0391) |
| `incubator/oxidizer-emission.png` | 280×320 | 60 | 9 | 0.3 | 0.5 | (0, 0) |
| `incubator/oxidizer-shadow.png` | 372×280 | 1, repeated 60 | 1 | 0.3 | 0.5 | (0.7969, 0.4844) |
| `loading-chamber/simulation-chamber-base.png` | 512×512 | 1 | 1 | none | 0.5 | (0, 0) |
| `loading-chamber/simulation-chamber-shadow.png` | 512×512 | 1 | 1 | none | 0.5 | (0, 0) |
| `loading-chamber/simulation-chamber-glow.png` | 512×512 | 1 | 1 | none | 0.5 | (0, 0) |
| `loading-chamber/simulation-chamber-layer4.png` | 512×512 | 1 | 1 | none | 0.5 | (0, 0) |
| `loading-chamber/simulation-chamber-screen-animation.png` | 64×64 | 255 | 32 | 1 | 0.5 | (-2, -1.75) |
| `loading-chamber/simulation-chamber-remnants.png` | 512×512 | 1 | 1 | none | 0.5 | (0, 0) |
| `larva-launcher/rocket-turret-attack.png` | 512×512 | 64 directions | 8 | none | 0.3 | (0, 0) |
| `larva-launcher/rocket-turret-attack-shadow.png` | 512×512 | 64 directions | 8 | none | 0.3 | (2, 0) |

All paths are under `graphics/entity/`. The sheet sizes match these
frame counts.

The mod fits the art to its footprint with one rule: the factor is
`footprint / drawn size`, the scale is `source scale × factor`, and each
shift is `source shift × factor`. These are the results:

| Building | Factor | Scale | Shifts that are not zero |
| --- | --- | --- | --- |
| Breeding pod | 5/7 ≈ 0.714 | 0.357 | all three sheets (0, -0.357) |
| Incubator | 1 | 0.5 | base (0.0391, 0.0391), shadow (0.7969, 0.4844) |
| Loading chamber | 4/6 ≈ 0.667 | 0.333 | screen (-1.333, -1.167) |
| Larva launcher | 3/4 = 0.75 | 0.225 | shadow (1.5, 0) |

The in-game check can tune a shift. A tuned value replaces the source
value in the code, with a comment.

### Icons (64 px)

| File | Use | Tint |
| --- | --- | --- |
| `breeding-pod.png`, `incubator.png`, `loading-chamber.png`, `larva-launcher.png` | building items and buildings | none |
| `egg-biter.png`, `egg-spitter.png` | eggs | none, coloured per species |
| `larva-biter.png`, `larva-spitter.png` | larvae | none, coloured per species |
| `stasis-ward.png`, `cryo-ward.png` | wards, the ward badge, the cryo technology | none |
| `larva-rocket-base.png` | loaded larva layer 1, and the casing | none |
| `larva-rocket-band-rear.png` | loaded larva layer 2 | the species |
| `larva-rocket-band-front.png` | loaded larva layer 3 | the species |
| `larva-rocket-larva.png` | loaded larva layer 4 | the species |

All paths are under `graphics/icons/`. Layers 2 to 4 are pale, so the
tint gives the colour. Each species has one `tint` in `core/species.lua`.
Today it colours the vanilla egg and larva icons. This release changes
the two values:

| Species | Tint (r, g, b) |
| --- | --- |
| Biter | 1.00, 0.52, 0.10 |
| Spitter | 0.45, 0.85, 0.20 |

After this release, the tint colours only the loaded-larva layers. The
previews also used worm (0.62, 0.38, 0.95), pentapod (0.20, 0.80, 0.85)
and hatchling (0.95, 0.15, 0.12). Those species get them when they
arrive. A hybrid in design version 2 can tint the rear band and the larva
with its first parent and the front band with its second.

### Technology icons (256 px)

`graphics/technology/monster-husbandry.png`, `ordnance-loading.png`,
`larva-rockets.png` and `stasis-ward.png`.

### Sounds

`sound/loading-chamber/simulation-chamber-working.ogg` and
`simulation-chamber-idle.ogg`, for the loading chamber's
`working_sound`.

## Prototype changes

### A new module for the looks

A new pure module, `core/prototypes/graphics.lua`, holds the source
values above as data and builds every look from them. It reads no game
globals. Paths start with `__abominable-ordnance__/`. Its functions:

- `Graphics.machine(name, size)` returns the `graphics_set` of the
  breeding pod, the incubator or the loading chamber at `size` tiles.
- `Graphics.chamber_sound()` returns the chamber's `working_sound`.
- `Graphics.launcher(size)` returns the turret picture fields.
- `Graphics.icon_path(file)` returns the full path of a file in
  `graphics/icons/`, and `Graphics.tech_path(file)` of a file in
  `graphics/technology/`. Both folders have a `stasis-ward.png`. Icon
  layers come from `Common.icon`, so the mod has one icon helper.
- `Graphics.loaded_larva(species, payload)` returns the four tinted layers
  and the payload badge.
- `Graphics.remnants(size)` returns the corpse prototype of the loading
  chamber.

`data.lua` passes these looks to the existing builders, as it passes the
vanilla looks today.

### Machines

- `Common.machine` and `Common.machine_kit` take a `size` and stop
  tinting. The collision box is `±(size / 2 - 0.3)` and the selection box
  is `±(size / 2)`, as vanilla machines do. The breeding pod is 5×5
  (±2.2 and ±2.5). The incubator and the loading chamber are 4×4 (±1.7
  and ±2.0). Today all three are 3×3.
- The constants `Lifecycle.POD_TINT`, `Ordnance.INCUBATOR_TINT` and
  `Ordnance.CHAMBER_TINT` go when nothing uses them.
- Breeding pod: `animation` has the sheet and the shadow
  (`draw_as_shadow`). One working visualisation has the emission sheet
  (`fadeout`, `draw_as_glow`, `blend_mode = "additive"`).
- Incubator: the same three parts as the pod.
- Loading chamber: `animation` has the base and the shadow. The working
  visualisations are the screen animation (`draw_as_glow`), layer 4 and
  the glow (`draw_as_glow`, `blend_mode = "additive"`). No layer uses
  `apply_recipe_tint`.
- The breeding pod uses the same art with and without Space Age. Only
  its sound still depends on the mode: it comes from the biochamber with
  Space Age and from the chemical plant without.
- Sound: the loading chamber gets its own `working_sound` (`sound` and
  `idle_sound` from `sound/loading-chamber/`, volume 0.7). The pod and the
  incubator keep the `working_sound` of the vanilla machine that they
  copy today. If another mod removed that machine, they have no sound.
  The asserts in `looks()` go.
- Remnants: the loading chamber gets a corpse prototype,
  `ao-loading-chamber-remnants`, with the remnants sheet. The pod and
  the incubator use the vanilla `big-remnants`, the biggest generic
  pile of rubble in the base game. It is a 3×3 pile, so it looks small
  beside a 5×5 pod. `data.lua` passes it only if it
  exists, so a mod that removes it leaves the machines with no corpse.

### Larva launcher

The footprint stays 3×3. The turret copies its boxes from the vanilla
artillery turret, as it does today.

- `cannon_base_pictures` is a RotatedSprite with `direction_count = 64`,
  `line_length = 8`, width and height 512 and scale 0.225. Its `layers`
  have the attack sheet, then the shadow sheet with
  `draw_as_shadow = true` and shift (1.5, 0).
- The turret drops `base_picture`, `cannon_barrel_pictures`,
  `cannon_barrel_recoil_shiftings`, its load correction matrix and
  `cannon_barrel_light_direction`. `make api` for Factorio 2.1.25 marks
  all five optional (2026-11-27).
- The API requires `cannon_base_shift`. It keeps the vanilla value. The
  in-game check tunes it if the art sits wrong.
- The turret tints no field. `LauncherPrototypes.TINT` goes when nothing
  uses it.
- The whole turret turns as one sprite, because each of the 64 frames
  shows the base and the rocket pods together. If the turning base looks
  wrong in the game, a later change cuts a static base for
  `base_picture`.

### Icons

- `Common.icon(path, tint)`: `tint` becomes optional.
  `Graphics.tech_icon(file)` gives the 256 px icons of a technology, and
  `Graphics.badge(icon, shift)` gives a small corner icon.
- `Graphics.SIZE` holds the footprint of each building. The prototypes
  and their art both read it.
- Eggs and larvae use `egg-<species>.png` and `larva-<species>.png`, with
  no tint.
- The loaded larva uses `Graphics.loaded_larva`: the four rocket layers,
  then the payload badge at scale 0.25 and shift (8, 8) in icon pixels, the
  bottom right corner.
- The ward badge moves to the top left corner, shift (-8, -8), so it does
  not cover the payload badge on a warded loaded larva. It uses
  `stasis-ward.png` or `cryo-ward.png`, with no tint. Each ward kind gets an
  `icon` path in place of its `tint`. `Stasis.WARD_TINT` and
  `Stasis.CRYO_TINT` go.
- The building items use their 64 px icons. The launcher item, turret
  and hidden guns use `larva-launcher.png`.
- The casing uses `larva-rocket-base.png`.
- Technologies: Monster husbandry, Ordnance loading, Larva rockets and the
  stasis ward research use their 256 px icons. The cryo ward research
  uses `cryo-ward.png` with `icon_size = 64`. The game scales it up in the
  research screen. The launcher speed and range upgrades use
  `larva-launcher.png`.
- Monster chow, spitter chow, the larva targeting remote and the larva
  flare keep their tinted vanilla icons until they get art.

## The mod zip

`tools/package.py` lists what ships. This release changes it, test-first
in `tools/tests/test_package.py`:

- `THIRD_PARTY.md` and `LICENSE-third-party-MIT.txt` join `REQUIRED`. The
  build then fails if either is missing. CC BY 4.0 needs the credit and
  MIT needs the licence text in every copy of the art.
- `is_mod_code` treats both files like `LICENSE`: a change to them needs
  no CHANGELOG entry.
- `sound/` joins `OPTIONAL`.
- A spec test collects every file path from the built prototypes, with
  the cryo ward built in. Every file under `graphics/` and `sound/` must
  appear in it. An unused file
  then fails the test instead of growing the zip.

`graphics/` and `sound/` hold about 26 MB of PNG and OGG files. The PR
gives the size of the built zip.

## Credits and licences

`THIRD_PARTY.md` lists each source, its licence and the changes.

| Files | Author | Licence |
| --- | --- | --- |
| `graphics/entity/breeding-pod/`, `graphics/icons/breeding-pod.png`, the building in `graphics/technology/monster-husbandry.png` | Hurricane046 | CC BY 4.0 |
| `graphics/entity/incubator/`, `graphics/icons/incubator.png` | Hurricane046 | CC BY 4.0 |
| `graphics/entity/loading-chamber/`, `graphics/icons/loading-chamber.png`, `sound/loading-chamber/`, the building in `graphics/technology/ordnance-loading.png` | snouz, with parts of Hurricane046's art | MIT, and CC BY 4.0 for the Hurricane046 parts |
| `graphics/entity/larva-launcher/`, `graphics/icons/larva-launcher.png`, the turret in `graphics/technology/larva-rockets.png` | hlittlezero | MIT |
| the other icons, `stasis-ward.png` and the rest of each technology icon | made for this mod in Blender, from no third-party meshes or textures | the mod's licence |

The pathogen lab came through the Mod Framework repository, and the
oxidizer through Nullius: Hurricane Reskins. CC BY 4.0 stays with the art
whoever repacks it, so Hurricane046's licence governs both.
`THIRD_PARTY.md` lists the changes: the new file names, the resized
icons, the removed lettering and the smaller scale in the game.

## Alternatives

| Alternative | Why not |
| --- | --- |
| Keep the tinted vanilla copies | A tinted centrifuge still reads as a centrifuge, so players cannot tell the mod's machines from vanilla ones at a glance. The portal page also shows the art. |
| Draw the buildings at their source size (7×7, 6×6) | A 7×7 pod takes 49 tiles for one early machine, about five times a 3×3. The maintainer capped machines at 5×5 for that reason. |
| Keep 3×3 footprints and shrink the art | At 3×3 the pod art shrinks to 43%, and its detail is lost. |
| Tinted layers for eggs and larvae as well | A tint over a pale body loses the shading that the coloured renders have, and an egg needs no parent colours. A new species then needs two new renders. The rocket shows two parents, so layers pay off there. |
| Show all four creature stages in the chamber | The stages need recipe colours that the mod's recipes do not have. With no colours, they show white. Layer 4 alone shows the full creature. The growth animation is lost until the recipes get colours. |
| A separate Space Age look for the pod | One art set is less code. The art is not tied to a planet. |
| Downsample the building sheets to the shipped scale | It saves memory, but it changes the source files. The in-game check decides if it is needed (see Risks). |

## Risks

| Risk | Effect | Mitigation |
| --- | --- | --- |
| Bigger footprints (pod 5×5, incubator and chamber 4×4) | In old saves, the bigger boxes overlap neighbours. Old blueprints with these machines no longer place. | The mod description warns that an update can break saves until 3.0.0. The CHANGELOG names the change under "Changed". |
| Large sheets | The pod's two 4000×4000 sheets take about 64 MB each in video memory. The launcher sheets are 4096×4096. | The in-game check notes the load time and memory. If the mod adds more than 5 seconds to the game's load, or more than 300 MB of video memory, a script in `art/` downsamples the pod and chamber sheets to their shipped scale. |
| The launcher sprite turns as a whole | The base turns with the rocket pods. | The in-game check looks at it. A static base is the fallback. |
| A shift is wrong | A building sits off its footprint or shadow. | The in-game check tunes the shifts. |
| The MIT grants rest on the portal labels | An author could dispute the reuse. | The maintainer accepted this. `THIRD_PARTY.md` names the source of each grant. |
| Another mod removes a vanilla machine | The pod or the incubator loses its sound. | The machine stays usable, with no sound. |

## Checks before merge

- [ ] The prototype changes follow `superpowers:test-driven-development`.
  The specs that assert tints today change with them.
- [ ] `make check` passes. It runs the unit tests, the gates and the
  in-game tests with and without Space Age.
- [ ] The built zip has `THIRD_PARTY.md`, `LICENSE-third-party-MIT.txt`,
  `graphics/` and `sound/`, and no `art/`. The package tests check this.
- [ ] In the game, with and without Space Age, each building lines up
  with its footprint and its shadow. It animates while it works and
  glows at night. The chamber plays its sound.
- [ ] The launcher aims in all 64 directions, and its base looks right.
  It parks and turns without a jump. It still copies
  `cannon_parking_frame_count` and `cannon_parking_speed` from vanilla.
- [ ] Each icon reads at 64 px in the inventory, on a belt and in the
  research screen. A warded loaded larva shows both badges apart.
- [ ] The loaded-larva tints are orange for the biter and green for the
  spitter.
- [ ] The PR gives the load time and the memory use with the new sheets.
- [ ] The CLAUDE.md review rounds pass for the changed paths. They
  include compatibility with other mods and with Space Age.
- [ ] `CHANGELOG.md`, `ROADMAP.md` and `docs/design.md` describe what
  shipped.
