# Architecture document: EGM review

Target: `docs/architecture.md`. Stages 5 to 7 ran in parallel on the
version of 2026-11-14, then a second round checked the rewrite. The
document is a standing rules document, so the reviewers applied the
feature spec standard only where it fits.

## Round 1 reviewers

| Stage | Reviewer | Verdict |
| --- | --- | --- |
| 5 | Zoom out | 2 Major, 5 Nit |
| 5 | Inventive catalyst | 2 Major, 1 Nit |
| 6 | Comprehension | 4 Major, 5 Nit |
| 7 | Design critic | 5 Major, 6 Nit |
| 7 | Structural | 3 Major, 5 Nit |
| 7 | Style | 3 Major, 4 Nit |

No reviewer found a Blocker.

## Round 1 findings and what changed

Several reviewers found the same problems:

- **The banned names were too few** (catalyst, design critic). The core
  rule named 4 globals. Factorio also has `prototypes`, `rendering`,
  `helpers`, `remote`, `commands`, `rcon`, `settings`, `mods` and `data`.
  Fixed: the rule and `spec/support/architecture.lua` now list 13 names.
  The checker now ignores a field or method with a global's name, such as
  `Lifecycle.prototypes`, and still catches a global after `..`. New
  fixtures show both.
- **The `math.random` rule covered more than the test** (comprehension,
  style, structural, design critic). The rule covers the control stage,
  but the test skipped `shell/`. Fixed: the test scans `shell/` too.
- **The examples did not match the code** (zoom out, catalyst,
  structural, design critic). They used a module that does not exist and
  an old `storage` shape. Fixed: the examples now come from
  `core/payloads.lua`, `control.lua` and `data.lua`.
- **The example test was weaker than the real one** (all six). Fixed: the
  doc points to the real checks instead.
- **The determinism rule matched neither the code nor the usual desync
  causes** (catalyst, design critic). Fixed: a seed in `storage`, a
  number or the generator passed to the core, state only in `storage`, no
  writes in `on_load`, the same events on every client.
- **No rules for old saves, other mods or performance** (design critic).
  `docs/design.md` names these risks. Fixed: three new sections that
  state the patterns the code already follows.
- **Undefined terms** (comprehension, style). The in-game tests, the
  `shell/` scope and the `docs_spec.lua` check are now explained. The
  title now names the document.

## Round 2

The design critic and the zoom out reviewer checked the rewrite. Neither
found a Blocker.

- **Examples will drift from the code** (zoom out). Fixed: the examples
  are short, marked as simplified, and name the real functions.
- **A rule about the feral check, which does not exist yet** (zoom out).
  Fixed: removed. The acid trail is now a named exception with a limit.
- **Wrong reason for the `math.random` ban** (design critic). Factorio
  makes `math.random` deterministic. The real reasons: the map's generator
  is shared with the game and every other mod, and the function fails
  outside events (`.factorio-api/factorio/library/lua/math.lua`). Fixed in
  the doc and in the checker's message.
- **`game.player` and per-user settings are not client-local** (design
  critic). Fixed: the rule now names a real desync cause, an event that
  only some clients register.
- **The old-saves rule contradicted `storage.seed`** (design critic).
  Fixed: the rule allows a field that every reader reads with a default.
- **The performance rule contradicted the acid trail** (design critic).
  Fixed: the trail is a named exception, to batch before loaded monsters
  come in the hundreds.

## Round 3

The design critic checked the four round 2 fixes against the code and
the Factorio docs. No new Blocker or Major findings. The loop stops here.

## Rulings

- **No rule IDs.** The structural reviewer asked for an ID on each rule.
  The document is short, and each rule is now one bullet or one
  sentence, so IDs add little. Cost if wrong: one more edit.
- **No sandbox loader.** The catalyst proposed loading each core module
  in an empty environment instead of scanning for names. The wider name
  list covers the known globals, and the sandbox would need more test
  code. Cost if wrong: a new global that Factorio adds later slips past
  the check.
- **Type annotations stay in this document.** The zoom out reviewer
  suggested a style document. No such document exists, and the section is
  short. Cost if wrong: none.

## Deferred to a code PR

- `data.lua` reads `data.raw["assembling-machine"][name]` with no nil
  check. A mod that removes the centrifuge makes the data stage fail. The
  new "Other mods" rule says to check it. The fix needs mod code, a test
  and a changelog entry.
- `nest_loot` in `control.lua` is a named handler without its
  `---@param event EventData.on_entity_died` annotation.
