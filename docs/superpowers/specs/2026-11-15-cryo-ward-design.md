# Abominable Ordnance: the cryo ward

Date: 2026-11-15. Status: approved by EGM. The agent (Claude) wrote this
spec from the maintainer's decision of 2026-11-15 and from the slice 5
spec. An EGM review (the project's spec review by fresh reviewers) ran
three rounds and a final narrow check, which found no new Blocker or
Major issue. The defaults in "Calls for the maintainer" stay open for
the maintainer.

"Answers" lists what the maintainer already decided. "Proposals" lists
the agent's own calls. "Calls for the maintainer" lists the ones the
maintainer should confirm, each with the default the build uses.

## Purpose

Slice 5 (`docs/superpowers/specs/2026-11-15-stasis-design.md`) added the
base stasis ward. It slows the spoiling of a lifecycle item 20 times, in
both modes. The maintainer wants a stronger, Space Age only ward that
uses Aquilo materials, because cold fits the theme.

Goals:

1. In Space Age, a cryo ward slows spoiling 100 times.
2. A player makes the cryo ward on Aquilo, from cold fluoroketone and
   lithium plates. The recipe needs Aquilo's pressure, so it can't run
   anywhere else. The finished wards ship to any planet.
3. The base ward stays unchanged in both modes.
4. Without Space Age, the cryo ward does not exist. New games without
   Space Age see no change. A save that drops Space Age loses its cryo
   items (see Risks).

## Terms

Terms are as in the slice 5 spec. The most important ones:

- **Lifecycle item.** An egg, a larva or a larva rocket of the mod. There
  are 10 in version 1: 2 eggs, 2 larvae and 6 larva rockets.
- **Base ward.** The slice 5 ward, `ao-stasis-ward`. It slows spoiling
  20 times.
- **Warded item.** A lifecycle item packed with a base ward, for example
  `ao-warded-biter-egg`.
- **Spoil progress.** How far an item is through its spoil time, from 0%
  to 100%.
- **Hatch handlers.** The mod's existing `on_script_trigger_effect`
  code. When a lifecycle item spoils, its spoil trigger runs a script
  effect, and these handlers spawn the monster.
- **Probe.** A throwaway test mod that runs before the build, in a real
  Factorio.
- **`.factorio-api/`.** The local copy of the Factorio API documentation
  in the repository.

New terms:

- **Cryo ward.** `ao-cryo-ward`. The Space Age ward. It slows spoiling
  100 times.
- **Cryo-warded item.** A lifecycle item packed with a cryo ward, for
  example `ao-cryo-warded-biter-egg`.
- **Cold fluoroketone.** The Space Age fluid `fluoroketone-cold`. Hot
  fluoroketone is `fluoroketone-hot`.
- **Aquilo's fluoroketone loop.** On Aquilo, recipes use cold
  fluoroketone and give back hot fluoroketone. The vanilla
  `fluoroketone-cooling` recipe turns hot fluoroketone back into cold.
- **Ward kind.** A plain data table that describes one ward. The stasis
  builder takes a ward kind and builds that ward's items, recipes and
  research. "Game content" lists its fields.

## Facts found during design

The agent read these in the Space Age 2.1.24 data
(`~/.cache/abominable-ordnance/factorio-2.1.24/data/space-age`) and in
`.factorio-api/factorio/library/`:

- `fluoroketone-cold` and `fluoroketone-hot` are fluids
  (`space-age/prototypes/fluid.lua`). Neither sets `auto_barrel`, so
  both get barrels. `base/data-updates.lua` makes
  `fluoroketone-cold-barrel`, with Aquilo as its default import
  location. So cold fluoroketone can leave Aquilo in barrels.
- The `fluoroketone-cooling` recipe and the cryogenic plant have no
  surface condition. A player can cool hot fluoroketone on any planet.
- `lithium-plate` is an item (`space-age/prototypes/item.lua`).
- The recipe category `cryogenics` belongs to the cryogenic plant. The
  `railgun` recipe uses it with cold fluoroketone and has no surface
  condition. The `cryogenic-science-pack` recipe uses it with cold
  fluoroketone, gives back hot fluoroketone next to an item main
  product, and has a pressure condition of exactly 300 (Aquilo). So a
  recipe with a fluid result next to an item main product loads, and a
  pressure condition ties a recipe to Aquilo.
- The cryogenic plant has 8 module slots and allows quality modules.
- The `cryogenic-science-pack` technology unlocks the Aquilo science
  pack. Its prerequisite is `cryogenic-plant`.
- A recipe result takes its spoil progress from its ingredients. The
  slice 5 probe confirmed this for the base ward, with a hand craft and
  an assembler. The cryo ward uses the same recipe shape.
- A `spoil_ticks` value is a uint32 (at most about 4.29 billion). The
  longest base time of the 10 lifecycle items is the egg's, 30 minutes.
  At 100 times, that is 10 800 000 ticks, well below the limit.

The probe in "Delivery" must confirm this fact:

| Fact to confirm | Fallback |
| --- | --- |
| Pack and unpack with a cryo ward keep the spoil progress, as with the base ward. This includes the hand-off: base-warded, unpacked, then cryo-warded | Stop the build, write the probe results to the plan, open no build PR, and report to the maintainer, as in slice 5 |

## Answers

The maintainer decided these on 2026-11-15:

| Question | Answer |
| --- | --- |
| How many wards | Two. The base ward stays unchanged. Space Age adds the cryo ward |
| Cryo ward materials | Cold fluoroketone and lithium plates |
| Where it is made | On Aquilo |
| Without Space Age | The cryo ward does not exist |
| Research | An Aquilo research unlocks the cryo ward |

## Alternatives considered

| Choice | Rejected alternative | Why rejected |
| --- | --- | --- |
| A second warded item per lifecycle item | One warded item with two pack recipes | An item has one spoil time. The ward type must decide the spoil time, so the cryo ward needs its own items |
| Cryo ward as a separate item | The base ward recipe changes in Space Age | The base ward is a version 1 tech and must stay early. Aquilo comes late |
| Pack and unpack anywhere | Pack and unpack only on Aquilo | The cold cost is in the ward itself. Packing at the base, where the eggs are, is the point |
| Unpack first to repack | A direct recipe from a warded item to a cryo-warded item | 10 more recipes for a two-step task that the player can automate |
| A pressure condition of 300 on the ward recipe | No surface condition | Cold fluoroketone ships in barrels, and players can cool hot fluoroketone anywhere. Without a condition, the ward could be made on any planet, which does not match "made on Aquilo" |
| One builder for both wards | A second builder module for the cryo ward | The two wards differ only in data. A copy would drift |

## Proposals

The agent made these calls. "Calls for the maintainer" lists the ones
that change how the game feels.

- **Ten cryo-warded items.** One per lifecycle item, with a spoil time
  of 100 times the item's own time. They copy the item's spoil trigger,
  as the warded items do. So when one spoils, the hatch handlers spawn
  the same monster as for the plain item.
- **The cryo ward recipe** runs in a cryogenic plant (category
  `cryogenics`) with a pressure condition of exactly 300 (`min` and
  `max` both 300). It takes lithium
  plates and cold fluoroketone, and gives one cryo ward and hot
  fluoroketone. The hot fluoroketone goes back into Aquilo's
  fluoroketone loop. "Game content" has the amounts.
- **No quality loop on the ward recipe.** The cryogenic plant takes 8
  quality modules. A ward made with quality and then recycled would give
  back lithium plates with a second quality roll. So the ward recipe
  sets `auto_recycle = false`, `allow_productivity = false` and, as a
  maintainer call, `allow_quality = false`. The base ward recipe stays
  as slice 5 built it.
- **Pack and unpack recipes** for the cryo ward use the category
  `crafting`, so any assembler or the player can run them anywhere. They
  follow every slice 5 rule: `allow_quality = false`,
  `allow_productivity = false`, `maximum_productivity = 0`,
  `allow_decomposition = false`, `allow_as_intermediate = false`,
  `main_product` on unpack, no recycling, and the `ao-stasis` subgroup.
- **Weight.** Slice 5 gives every lifecycle item that spoils an explicit
  weight, the rocket lift weight divided by its stack size. Warded items
  copy that weight. Cryo-warded items copy it too, so a packed item
  weighs the same as the plain one. The cryo ward itself has no explicit
  weight. Space Age derives its weight from its recipe, and the design
  accepts that.
- **Research** `ao-cryo-ward`: needs `ao-stasis-ward` and
  `cryogenic-science-pack`. It unlocks the cryo ward recipe and every
  cryo pack and unpack recipe.
- **One builder for both wards.** `Stasis.prototypes(sources, kinds)`
  takes a list of ward kinds and builds each ward's items, recipes and
  research. It makes the `ao-stasis` subgroup once, so no prototype
  appears twice. `data.lua` calls it once.
- **Which kinds to build.** A pure function,
  `Stasis.kinds({ space_age = bool, has = {...} })`, returns the kind
  list and the names of missing prototypes. The base kind is always in
  the list. The cryo kind is in it with Space Age when every Aquilo
  prototype it needs exists. `data.lua` only gathers the facts and logs
  the missing names.
- **Other mods.** If an Aquilo prototype that the cryo ward needs is
  missing, the cryo kind is left out with one log line. The base ward
  still loads.

## Calls for the maintainer

| Call | Default |
| --- | --- |
| Cryo factor | 100. An egg then lasts 50 hours, a larva rocket 500 minutes |
| Cryo ward recipe | 2 lithium plates and 10 cold fluoroketone give 1 cryo ward and 5 hot fluoroketone, 4 s, cryogenic plant |
| Where it is made | Pressure condition 300, so only on Aquilo. The alternative is no condition: then barrels of cold fluoroketone let a player make it anywhere |
| Quality on the ward recipe | Not allowed (`allow_quality = false`). The alternative allows quality wards but keeps recycling off |
| Pack and unpack | Anywhere, 1 s, any assembler or by hand |
| Repacking | Unpack the base-warded item first. No direct recipe |
| Research | Needs Stasis ward and the Aquilo science pack tech. 500 × the six packs below, 60 s |
| Cryo icon | The base ward icon with a pale blue tint (`{ r = 0.6, g = 0.85, b = 1 }`) |
| A save that drops Space Age | Cryo wards and cryo-warded items disappear, as any mod item does when its prototype goes away. The game warns at load |

## Game content

All numbers go in `core/balance.lua`, under `Balance.cryo`:

| Name | Value |
| --- | --- |
| `cryo.factor` | 100 |
| `cryo.ward` | stack 50, time 4 s, 2 lithium plates, 10 cold fluoroketone, 5 hot fluoroketone back |
| `cryo.pressure` | 300, the fallback when Aquilo gives no pressure. The recipe condition is `{ { property = "pressure", min = p, max = p } }` with Aquilo's pressure `p` |
| `cryo.pack_time` | 1 s |
| `cryo.research` | count 500, time 60 |

The six science packs map to these prototypes:
`automation-science-pack` (red), `logistic-science-pack` (green),
`military-science-pack`, `chemical-science-pack` (blue),
`space-science-pack` and `cryogenic-science-pack`.

### The ward kind

A ward kind is a plain data table with these fields. The base kind holds
the slice 5 values, and the cryo kind the values above:

| Field | Base kind | Cryo kind |
| --- | --- | --- |
| Ward item name | `ao-stasis-ward` | `ao-cryo-ward` |
| Factor | 20 | 100 |
| Warded prefix | `ao-warded-` | `ao-cryo-warded-` |
| Pack recipe prefix | `ao-ward-` | `ao-cryo-ward-` |
| Unpack recipe prefix | `ao-unward-` | `ao-cryo-unward-` |
| Icon and tint | Plastic bar icon, slice 5 tint | Same icon, pale blue tint |
| Ward recipe category | `crafting` | `cryogenics` |
| Ward recipe ingredients and results | Slice 5 values | `Balance.cryo.ward` |
| Surface condition | None | `{ { property = "pressure", min = 300, max = 300 } }`, Aquilo only |
| Research name | `ao-stasis-ward` (same string as the ward item) | `ao-cryo-ward` (same string as the ward item) |
| Research packs and prerequisites | Slice 5 values | The six packs above, Stasis ward and `cryogenic-science-pack` |

### Items

| Item | Type | Stack | Spoil |
| --- | --- | --- | --- |
| `ao-cryo-ward` | item | 50 | None |
| `ao-cryo-warded-<item>` for each lifecycle item | item | As the lifecycle item | 100 × the item's time, then the item's spoil effect |

### Recipes

| Recipe | Ingredients | Result | Unlocked by |
| --- | --- | --- | --- |
| `ao-cryo-ward` | 2 lithium plates, 10 cold fluoroketone, 4 s, pressure exactly 300 | 1 cryo ward (main product), 5 hot fluoroketone | Cryo ward |
| `ao-cryo-ward-<item>` | 1 lifecycle item, 1 cryo ward, 1 s | 1 cryo-warded item | Cryo ward |
| `ao-cryo-unward-<item>` | 1 cryo-warded item, 1 s | 1 lifecycle item (main product), 1 cryo ward | Cryo ward |

### Research

| Tech | Needs | Cost | Effect |
| --- | --- | --- | --- |
| `ao-cryo-ward` | Stasis ward, Aquilo science pack | 500 × six packs, 60 s | Unlocks the cryo ward and its 20 pack and unpack recipes |

The cryo ward adds 11 items, 21 recipes and 1 research, all in Space
Age only.

## Runtime behaviour

None. A cryo-warded item spoils into its lifecycle item's spoil effect,
which the hatch handlers already run. The slice adds no `storage` field.

Old saves:

- **Space Age added to a save.** The game adds the prototypes. The
  existing `on_configuration_changed` resets technology effects, so once
  a force researches the cryo ward, it gets the recipes.
- **Space Age removed from a save.** Cryo wards and cryo-warded items
  disappear (see Risks).

## Architecture

The rules in `docs/architecture.md` apply. Changed modules:

| Module | Layer | Job |
| --- | --- | --- |
| `core/prototypes/stasis.lua` | core | `Stasis.prototypes(sources, kinds)` builds every kind's items, recipes and research, and the `ao-stasis` subgroup once. `Stasis.kinds(facts)` picks the kinds |
| `core/balance.lua` | core | `Balance.cryo`. `Balance.cryo.pressure` (300) is only the fallback: the build reads Aquilo's pressure from the planet |
| `core/names.lua` | core | `CRYO_TECH`, `CRYO_WARD` and the prefixes `ao-cryo-warded-`, `ao-cryo-ward-` and `ao-cryo-unward-` |
| `data.lua` | shell | With Space Age, looks up `data.raw.item["lithium-plate"]`, `data.raw.fluid["fluoroketone-cold"]`, `data.raw.fluid["fluoroketone-hot"]`, `data.raw["recipe-category"]["cryogenics"]` and `data.raw.technology["cryogenic-science-pack"]`. It passes these facts to `Stasis.kinds`, logs the missing names, and calls `Stasis.prototypes` once |
| `locale/en/locale.cfg` | data | Names for every new item, recipe and the research |

The lookups also cover the science packs the research uses, the
cryogenic plant and the planet `aquilo`. `data.lua` reads Aquilo's
pressure from the planet and passes it to `Stasis.kinds`, with 300 as
the fallback (see the ledger rulings in the plan).

These lookups run in `data.lua`. A mod that removes one of these
prototypes later, in `data-updates.lua` or `data-final-fixes.lua`,
still breaks the load, and the check can't catch that.

The base ward keeps its names and numbers. A busted test pins that the
base kind still builds the slice 5 prototypes unchanged.

## Testing

### Unit tests (busted)

- The base kind builds the same prototypes as before the refactor.
- No prototype name appears twice across both kinds, so the subgroup and
  every recipe exist once.
- `Stasis.kinds`: without Space Age it returns only the base kind. With
  Space Age and every prototype present it returns both kinds. With one
  prototype missing it returns only the base kind and that name.
- A builder given only the base kind makes no `ao-cryo-` prototype.
- The cryo kind builds 10 cryo-warded items with 100 times the spoil
  time, a copied trigger, the source weight and no ammo fields. Larva
  rockets are ammo items, but a warded copy must not be ammo, so it is
  built fresh as a plain item.
- The cryo ward recipe uses `cryogenics`. It has one surface condition
  on `pressure`, with `min` and `max` both 300. It has the ward as main
  product and gives back hot fluoroketone. It sets
  `auto_recycle = false`, `allow_productivity = false` and
  `allow_quality = false`.
- Every cryo pack and unpack recipe has the slice 5 locks.
- The research needs Stasis ward and the Aquilo science pack tech, and
  unlocks 21 recipes.

### In-game tests (factorio-test)

These run with Space Age. "About 40%" means 40% plus or minus 2
percentage points.

- An assembler packs a larva rocket at 40% into a cryo-warded rocket at
  about 40%, and unpacking gives it back at about 40%.
- The hand-off: an assembler packs a larva rocket at 40% with a base
  ward, unpacks it, then packs it with a cryo ward. The cryo-warded rocket is at
  about 40%.
- A cryo-warded egg and a plain egg both get 60 ticks of plain egg time
  left. The plain egg spoils within 180 ticks. The cryo-warded egg does
  not.
- The test creates Aquilo with `game.planets["aquilo"].create_surface()`.
  Aquilo freezes machines that get no heat, so the test places a heating
  tower with coal next to the cryogenic plant and waits for it to heat
  up. An electric energy interface powers the plant. The plant, with cold
  fluoroketone and lithium plates, makes a cryo ward and gives back hot
  fluoroketone.
- The same plant on Nauvis does not craft the ward. After 600 ticks the
  test checks that `products_finished` is 0 and that the output holds no
  ward. If `set_recipe` raises an error because the recipe can't run on
  that surface, the test counts that as a pass.

## Delivery

### Probe

A throwaway probe checks the table in "Facts found during design" in
Space Age. If the fact fails, the build follows that row's fallback.

### Pull requests

One PR: the builder refactor, the cryo kind, `data.lua`, the locale and
the tests.

## Risks

- **Late game only.** The cryo ward needs Aquilo, so most players meet
  it near the end of Space Age. That is by design.
- **Wards made only on Aquilo.** With the pressure condition, a player
  must ship cryo wards from Aquilo. That is the maintainer's "made on
  Aquilo". If the maintainer drops the condition, barrels of cold
  fluoroketone let a player make wards anywhere.
- **A save that drops Space Age.** Cryo wards and cryo-warded items
  disappear, and the eggs inside them are lost.
- **Item count.** 11 more items and 21 more recipes in Space Age.
- **Platform losses.** As with the base ward, a cryo-warded item that
  spoils on a space platform is lost. At 100 times, this is unlikely on
  any trip.

## Changes to `docs/design.md` and `ROADMAP.md`

This PR makes these changes:

- `docs/design.md`, "Stasis ward materials": this PR moves the open
  question to Answered (done on this branch, one entry). Two wards: the
  base ward in both modes, and a Space Age cryo ward made on Aquilo from
  cold fluoroketone and lithium plates, 100 times slower.
- `docs/design.md`, core loop step 5: mention the cryo ward with Space
  Age (done on this branch).
- `docs/design.md`, "Logistics and delivery": one bullet about the cryo
  ward (done on this branch).
- `ROADMAP.md`: add "Cryo ward (Space Age)" under the next release.

## Out of scope

- A cryo ward without Space Age.
- A direct repack recipe from a warded to a cryo-warded item.
- Version 2 lifecycle items such as embryos and hybrid eggs. They get
  wards when version 2 adds them to the builder's list.
