# Slice 5 stasis ward spec: EGM review

Target: `docs/superpowers/specs/2026-11-15-stasis-design.md`. The agent
wrote the spec overnight. Stages 5 to 8 ran on the draft, and two more
rounds checked the rewrites.

## Round 1

| Stage | Reviewer | Verdict |
| --- | --- | --- |
| 5 | Zoom out | 4 Major, 4 Nit |
| 6 | Comprehension | 6 Major, 9 Nit |
| 7 | Design critic | 2 Blocker, 4 Major, 5 Nit |
| 7 | Style | 1 Blocker, 8 Major, 3 Nit |

What changed:

- **The unpack recipe would not load** (critic, Blocker). It has two
  results and no `main_product`. Fixed: `main_product` is the lifecycle
  item.
- **A free quality loop in Space Age** (critic, Blocker). Pack and unpack
  in a machine with quality modules would raise quality for nothing.
  Fixed: both recipes set `allow_quality = false`, and productivity is
  off.
- **The timer slows, it does not stop** (style). Fixed in the spec and in
  the list of changes to `docs/design.md`.
- **Unclear fallbacks** (comprehension, zoom out). Fixed: the freshness
  facts are one probe gate. On failure the build stops and reports.
- **Two lists of lifecycle items** (zoom out). Fixed: no `core/stasis.lua`.
  The builder takes an explicit list of the version 1 items.
- **Other points:** recycling only off for pack and unpack, a check that
  the ward's ingredients exist, rocket packing only after Ordnance
  loading, platform losses in Risks, tests that set spoil progress.

## Round 2

The design critic and the zoom out reviewer found no Blocker. Fixed: the
builder input from `data.lua`, all five "pause" places in
`docs/design.md`, quality behaviour marked as inferred with two probe
rows and a same-quality ward rule, recipe flags against crafting-menu
loops, and `spoil_tick` for the tests.

## Round 3

The design critic found no new Blocker or Major issue. Two nits were
fixed: the recipe count and subgroup, and how a test turns a progress
into a `spoil_tick`.

## Calls for the maintainer

The spec lists them with the defaults the build uses. The main ones: the
ward recipe and its 20 times slower timer, Ordnance loading as a
prerequisite, warded rockets are not launcher ammo, spoil progress
carries over as a percentage, ward loss for spoiled eggs, and a quality
item needs a ward of the same quality. The Aquilo materials idea stays
open.
