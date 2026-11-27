# Graphics for design version 1: EGM review

Target: `docs/superpowers/specs/2026-11-26-v1-graphics-design.md`.

## Round 1

Zoom out, comprehension, design critic and codebase details. The design
critic rated three findings as Blockers. The others found no Blocker.

- Blocker: the code tints every machine and turret look, and that would
  colour the new art. Fixed: the looks come with no tint from a new pure
  module, `core/prototypes/graphics.lua`, and `Common.machine` and the
  turret stop tinting. The tint constants go.
- Blocker: the spec had no Alternatives and no Risks sections. Fixed: both
  added.
- Blocker: the bigger footprints break old saves and blueprints. The
  maintainer already accepted this, and the mod description warns that
  saves can break before 3.0.0. Fixed: the Risks section records it, and
  the incubator's growth to 4×4 is now listed.
- `Common.machine` hard-codes a 3×3 box. Fixed: it takes a `size`, with
  the box rule and the values for 5×5 and 4×4.
- The loaded larva and the larva rocket are one item, but the spec gave
  it two icons. Fixed: it uses the four rocket layers and the payload
  badge. The capsule renders wait in `art/`. The author decided this.
- `core/species.lua` already holds a tint per species. Fixed: the spec
  changes those values. The worm, pentapod and hatchling tints are now a
  note.
- The ward badge and the payload badge used the same corner. Fixed: the
  ward badge moves to the top left.
- The launcher scale 0.3 did not follow the scaling rule. Fixed: 0.225
  (0.3 × 3/4), with the shadow shift at 1.5.
- The turret fields to drop were open. Fixed: the API marks the five
  dropped fields optional. `cannon_base_shift` is required and keeps the
  vanilla value.
- The sheets, the fields that they go to, and the final scales and
  shifts were missing. Fixed: two tables and a layer list per building.
- `frozen_patch` is dead art without `heating_energy`. Fixed: it is not
  wired and the file waits in `art/`.
- The sound and the `looks()` asserts were undefined. Fixed: the chamber
  gets its own sound. The pod and the incubator keep their vanilla sound
  where it exists. The asserts go.
- The zip did not ship the credits, and `is_mod_code` would need a
  CHANGELOG entry for each credit change. Fixed: both licence files join
  `REQUIRED`, `is_mod_code` exempts them, and a test fails on any unused
  file under `graphics/` or `sound/`.
- The technology icons had no size parameter, and the cryo research had
  no icon. Fixed: `Common.icon` takes a size, and the cryo research uses
  the 64 px cryo icon.
- The memory cost of the large sheets was unmeasured. Fixed: it is a
  recorded risk, and the in-game check measures it.
- Terms such as loaded larva, ward and "drawn for" were undefined. Fixed:
  a Terms section.

The author also found that three technology icons contain building art
from other mods. `THIRD_PARTY.md`, `LICENSE-third-party-MIT.txt` and the
spec's credit table now name them.

## Round 2

The same four reviewers. No reviewer found a new Blocker. The Majors:

- The Alternatives table gave "the maintainer chose" as a reason in three
  rows. Fixed: each row gives a technical reason. A new row records that
  the chamber loses its growth stages.
- The spec said six unused files wait in `art/`, but they were still in
  `graphics/`. Fixed: they moved to `art/waiting/`, and the spec lists
  them.
- The claim that the five dropped turret fields are optional needed a
  recorded API check. Fixed: the spec gives the `make api` result for
  Factorio 2.1.25.
- The casing, the recipe tint and the old species tints were unclear to a
  new reader. Fixed: a Terms entry for the casing, one sentence on
  `apply_recipe_tint`, and the current use of the tint.

Cheap Nits fixed: one icon helper (`Common.icon`), the cryo research icon
size, a number that triggers the downsampling, the parking fields in the
launcher check, a guard for `big-remnants`, the build of the cryo ward in
the unused-file test, the licence link for the pathogen lab, and the
Purpose now says that the release can break saves.

Accepted Nits: the box margin of 0.3 matches vanilla 3×3 machines and
the foundry. The chamber's sounds come from the Panglia download, and
`THIRD_PARTY.md` credits them to snouz with no further evidence.

## Round 3

A narrow check of the round 2 fixes by the same four reviewers. Three
found every Major closed and nothing new. The codebase reviewer found
one new Major: `Graphics.icon_path` covered two folders, and both hold a
`stasis-ward.png`. Fixed: `Graphics.icon_path` and `Graphics.tech_path`.

## Round 4

The codebase reviewer checked the two path functions. The Major is
closed and nothing new came up. The review ends here with no open
Blocker or Major.

## Plan, round 1

`docs/superpowers/plans/2026-11-27-v1-graphics.md`, reviewed for
implementation readiness and against the code. Each reviewer found one
Blocker:

- The larva icon test sat in the lifecycle task, but `ordnance.lua`
  builds the larva. Fixed: the test moved to the ordnance task.
- The plan ran `make test`, which does not exist. Fixed: the quick loop
  is `busted`, and each commit runs `make fast`.

The Majors, all fixed:

- Tasks left specs red and broke the data stage between commits. Now the
  first task only adds, the `data.lua` edits move into the tasks that need
  them, and each data task runs `make ingame`.
- `Graphics.machine`, the chamber sound and the corpse had no exact
  shape. The plan now gives each one, and the corpse copies the fields of
  the vanilla `big-remnants`.
- The specs that break were not named. Every one is now listed by line.
- `Common.tinted` and `Common.looks` would stay as dead code. The plan
  deletes both in the task that removes their last caller.
  `LauncherPrototypes.TINT` stays for the remote and flare.
- The ward kinds had one icon for the item and the research. Each kind
  now has `research.icon` and `research.icon_size`.
- The unused-file test had no exact fixture. It now walks the folders
  with `lfs`, builds the cryo kind from `Stasis.CRYO.needs`, and fails on
  an empty walk.

The check also found that the vanilla `big-remnants` is a 3×3 pile. The
spec now says so.

## Plan, rounds 2 and 3

The readiness reviewer found every round 1 finding fixed and called the
plan ready. The codebase reviewer found one new Major: Task 7 relied on
the default `tile_width`, which the reviewer could not find in the
local docs. `make api` does give that default, but the plan now sets
`tile_width` and `tile_height` from the size and tests them. Round 3
found the Major closed and nothing new. The review ends here with no
open Blocker or Major.
