# Stage 7: Critic Review

Target: `docs/superpowers/specs/2026-11-14-ordnance-design.md`, the whole
file (draft of 2026-11-14).

Goldfish context: `docs/design.md`, `docs/architecture.md`, the slice 1
spec, and for the design critic also `control.lua`, `data.lua`, `core/`
and the Factorio API annotations.

| Reviewer | Standard | Verdict |
| --- | --- | --- |
| `egm-design` | feature-spec-standard | Does not pass: 1 Blocker, 9 Major, 8 Nit |
| `egm-structural` | feature-spec-standard | Does not pass: 1 Blocker, 8 Major, 6 Nit |
| `egm-style` | STE80 house style | 6 Major, 15 Nit |

## Elephant notes

These notes come from the main session. They are not reviewer findings.

- **The Blocker.** Both D1 and S1: the spec has no Risks section. Slice 1
  had one.
- **Found by several reviewers in Stages 5 and 7.** One `on_entity_died`
  handler: D2, ZO-01, IC-2. The idle loaded monster: D3, IC-4, C3. Force
  and friendly fire of effect entities: D4, ZO-04, IC-5, C2. Tamed force
  setup: D6, ZO-03, IC-9. Hand delivery and inventory spoilage: D7, IC-3,
  ZO-05. One unit prototype per species and size: D8, IC-1. Changes to
  `docs/design.md`: D9, S8, ZO-06, IC-7. Payloads as a list and the
  unexplained `size`: N3, ZO-09, IC-8, C4. Decisions rows without a
  question number: S3, ST-21, C5. The gap between PR 2 and PR 3: N4, S9,
  C13.
- **New and important.** D5: a spawner that a loaded monster kills drops
  no eggs. The killer force is `ao-tamed`, which never has Monster
  husbandry. Nests destroyed by the mod's own weapon would stop the egg
  supply.
- **Checked and true.** D2: the `LuaBootstrap.on_event` annotation says
  a second registration replaces the first, even with other filters. D4:
  the `LuaSurface.create_entity` annotation gives `enemy` as the default
  force.

## Design findings (egm-design)

- **D1. Blocker.** No Risks and Mitigations section.
- **D2. Major.** A second `on_entity_died` handler replaces nest loot.
  One handler with an OR filter. A `type = "unit"` filter calls Lua on
  every native death.
- **D3. Major.** A loaded monster has no command. Default AI settings
  can destroy it with no death event (`allow_destroy_when_commands_fail`)
  or send it to a spawner it does not have. Specify the spawn routine:
  AI settings, a command, and what happens in the base.
- **D4. Major.** No force or cause on effect entities. The default is
  `enemy`, so acid puddles would hurt players and spare natives. Record
  the force condition of each effect. Pass `force` and `cause`. Split Q4
  into AI targets and blast damage.
- **D5. Major.** Spawners killed by `ao-tamed` drop no eggs, because of
  the research gate. Decide a rule (owner force, or share the research)
  and test it.
- **D6. Major.** Force setup: cease-fire both ways, existing saves,
  forces made later, other enemy factions. One idempotent
  `ensure_tamed_force()` from `on_init`, `on_configuration_changed`,
  `on_force_created` and `on_forces_merged`. Note the 64-force limit for
  version 3.
- **D7. Major.** Hand delivery rests on inventory spoilage that nobody
  probed, and the 5-minute fuse starts at the craft. The same fuse
  becomes ammo shelf life in slice 3. Probe it, and re-weigh the capsule
  option.
- **D8. Major.** The middle option is missing: one copied unit per
  species and size (8 now), payload in `storage`.
- **D9. Major.** Departures from `docs/design.md` are not recorded. The
  smoke rejection is weak: a re-created smoke is possible.
- **D10. Major.** Vanilla names are not guarded, and Space Age is not
  checked. Build payloads only from prototypes that exist, and check
  prototypes before `create_entity`.
- **N1 to N8. Nits.** Acid tick cost and buckets. Return the empty barrel
  and add `fluid-handling`. Missing numbers, the `size` argument and the
  effect ID lookup. The PR 2 gap and changelog edits. Test gaps. Payload
  icons and `data-updates`. What size by evolution means off Nauvis.
  Agreement with 10:1 for Q1.

## Structural findings (egm-structural)

- **S1. Blocker.** No Risks section. Candidates: friendly fire, spoiling
  in an inventory, `on_init` on existing saves, the tick cost, units that
  leave without dying.
- **S2. Major.** Q7 has no Decisions row.
- **S3. Major.** Which rows are settled? Rename the column to "Topic",
  say every row is a proposal, and split Q4's second question out.
- **S4. Major.** No runtime data flow. Add "Runtime behaviour" with steps
  for the larva hatch, loaded hatch, death effects, acid effect and the
  force.
- **S5. Major.** The data stage is missing: `data.lua`, `core/names.lua`,
  the reuse of `core/hatching.lua`, and the move from `data-final-fixes`.
- **S6. Major.** Game content lacks Payloads, Research and Tamed force
  subsections, and recipe times.
- **S7. Major.** Testing gaps, and no split into unit and in-game tests.
- **S8. Major.** No record of changes to `docs/design.md` and the
  roadmap.
- **S9. Major.** The state between PR 2 and PR 3 is not described.
- **S10 to S15. Nits.** The empty Space platforms cell. Q5 wording and
  the base-game fallback. "Plain larva" undefined. A repo fact under the
  data-file facts. Deferred items missing from Out of scope. Section names
  differ from slice 1, and there is no probe.

## Style findings (egm-style)

- **ST-01. Major.** "Acid cloud" names a puddle.
- **ST-02. Major.** "The game has no such smoke" is unchecked.
- **ST-03. Major.** The prerequisite sentence carries three ideas, and
  its "so" points at the wrong clause.
- **ST-04. Major.** "All recipes have `auto_recycle = false`" includes
  the machines. The recycler exists only in Space Age.
- **ST-05. Major.** `register_on_object_destroyed` does not remove the
  entry. A handler does, and the Architecture row does not list it.
- **ST-06. Major.** Q2 misstates `docs/design.md`, whose version 1 list
  names generated entity prototypes.
- **ST-07 to ST-21. Nits.** Wordy status line, "goes off", "on the spot",
  two names for one force, a repo fact in the data-file list, "a nuke"
  and "three times", passives in the Force and items rows, "playable",
  circuit and gear names, the `Effects` fragment, "learns" and "the
  script" against "the shell", "normal biter", Q3 and Q7 phrasing, and
  the duplicated questions.
