# Stage 5: Initial Zoom Out Review

Target: `docs/superpowers/specs/2026-11-14-ordnance-design.md`, the whole
file (draft of 2026-11-14).

Goldfish context: `docs/design.md`, `docs/architecture.md` and the slice 1
spec `docs/superpowers/specs/2026-11-13-lifecycle-design.md`.

| Reviewer | Verdict |
| --- | --- |
| `egm-zoom-out` | Changes requested: 6 Major, 5 Nit |
| `egm-inventive-catalyst` | Advisory: 4 Major, 5 Nit |

Both reviewers say the context check passes: the objective, scope and
place between slices 1 and 3 are clear. Neither found a Blocker.

## Elephant notes

These notes come from the main session. They are not reviewer findings.

- **Found by both reviewers.** A second `on_entity_died` handler replaces
  the slice 1 nest-loot handler (ZO-01, IC-2). The force made only in
  `on_init` misses existing saves and later player forces (ZO-03, IC-9).
  Friendly fire and the force of effect entities (ZO-04, IC-5). No
  "Changes to `docs/design.md`" section (ZO-06, IC-7). Payloads as a
  list, and the unexplained `size` (ZO-09, IC-8). Delivery by hand (ZO-07,
  IC-3).
- **Checked and true.** ZO-01 and IC-2: `control.lua` on the slice 1
  branches already registers `on_entity_died` for nest loot. A second
  `script.on_event` call for the same event replaces the first.
- **Decisions for the maintainer.** IC-1 (one tinted unit prototype per
  species and size) changes Q2. IC-3 (a throwable capsule now) changes
  Q6. ZO-10 (no separate incubator) changes Q5.

## Zoom-out findings (egm-zoom-out)

- **ZO-01. Major.** "New handlers: `on_entity_died`" would replace the
  nest-loot handler. Keep one handler with both filters and dispatch.
- **ZO-02. Major.** `core/prototypes/lifecycle.lua` has the helpers the
  new builder needs (`tinted`, `icon`, `item`, `recipe`, `no_recycling`,
  `hatch_trigger`), all local. `hatch_trigger` hard-codes the egg
  ratio. Nothing says which builder owns Monster husbandry and its new
  unlocks. `data.lua` and `core/names.lua` are missing from the
  Architecture table. Move the helpers to a shared pure module and pick
  one owner for the technologies.
- **ZO-03. Major.** `on_init` does not run for saves that already have
  the mod. Use one idempotent "ensure tamed force" step from `on_init`
  and `on_configuration_changed`, and set cease-fire in
  `on_force_created`.
- **ZO-04. Major.** The force of the projectile, `poison-cloud` and acid
  puddles is not given, nor whether they hurt the player. A larva that
  spoils in the base leaves a monster there at peace, with an endless
  acid trail. State the rule, or call friendly fire an intended risk.
- **ZO-05. Major.** No probe for the engine behaviour the design rests
  on: a script-made projectile at its own target, the damage of clouds
  and puddles by force, idle units on a hostile force,
  `on_object_destroyed` order, and a spoil in a player's inventory. Add a
  Probe section with a stop rule, and a Risks table.
- **ZO-06. Major.** No record of the changes to `docs/design.md` and
  `ROADMAP.md`: the larva ratio, no generated entity prototypes,
  `data.lua` instead of `data-final-fixes`, the acid trail, and the
  research link between two branches.
- **ZO-07. Nit.** Describe delivery as "drop the loaded larva near the
  target". Mark the 5-minute spoil time for review in slice 3.
- **ZO-08. Nit.** The Force row's reason is wrong: slice 4's feral force
  is a separate force in `docs/design.md`.
- **ZO-09. Nit.** Say what `size` changes or drop it. Store payloads as a
  list, as `docs/architecture.md` shows. Consider one module for payload
  data and effects.
- **ZO-10. Nit.** The incubator could be a recipe in the breeding pod.
  Offer it under Q5, or record why a separate machine stays.
- **ZO-11. Nit.** Six loaded larvae need six effect IDs and a reverse
  lookup to species and payload.

## Inventive catalyst findings (egm-inventive-catalyst)

- **IC-1. Major.** Split identity from payload: one tinted unit prototype
  per species and size (8 now), with the payload in `storage`. It makes
  loaded monsters visible and lets `on_entity_died` filter by name, so
  native deaths never reach Lua. Cost: 8 prototypes, built late in the
  data stage, and a map from vanilla unit to loaded copy.
- **IC-2. Major.** Same as ZO-01. Add an in-game test that nest loot
  still drops after slice 2.
- **IC-3. Major.** Hand delivery ties the spoil time to playability, and
  nobody checked a spoil in a player's inventory. Make the loaded larva a
  spoiling `capsule` whose thrown projectile fires the same `script`
  effect ID, so one shell path serves spoil, throw and slice 3. Test a
  spoil in an inventory either way.
- **IC-4. Major.** A unit created by script with no command stays put.
  Give it an `attack_area` command at spawn, with the radius in
  `balance.lua`, and decide what an idle loaded monster does. Test that
  a loaded monster attacks a nearby spawner.
- **IC-5. Nit.** "Acid cloud" is now a puddle. Check the force and damage
  of every effect entity, and create them on `ao-tamed`.
- **IC-6. Nit.** Ask Q1 as "eggs per round of ammunition", next to the
  breeding rate. The risk per egg is already equal.
- **IC-7. Nit.** Same as ZO-06. Also: slice 3 cannot use a `create-entity`
  trigger, because the payload must be registered. Name the shared
  "spawn a loaded monster" shell function.
- **IC-8. Nit.** Store a one-item list. Explain or drop `size`. "Three
  times the items" should be four.
- **IC-9. Nit.** One tick handler over the tracked units, which slice 4
  extends. Set force relations in `on_init`, `on_configuration_changed`
  and `on_force_created`.

## Missing tests named by the reviewers

- Nest loot still works after slice 2.
- A loaded larva spoils in a player's inventory.
- A loaded monster attacks a nearby spawner.
- The `storage.loaded` entry goes away after the unit dies.
- The acid live effect in game.
