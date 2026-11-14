# Slice 1 build ledger

The progress ledger of the slice 1 build (plan
`docs/superpowers/plans/2026-11-13-lifecycle.md`), kept at the
maintainer's request. It is a record and is not edited.

```text
# SDD ledger — plan: docs/superpowers/plans/2026-11-13-lifecycle.md
Pre-flight: Interfaces checked in two Stage 9 rounds; Task 4 consumes Task 3 Lifecycle.prototypes; Task 5 consumes Task 2 Species; Task 6 consumes Task 5 Hatching.hatch and Task 4 Helpers; Task 8 consumes Task 7 Loot.drop, Task 6 random(), Task 4 Helpers.arena. No conflicts found.
Task 0: complete (PR #5 merged as 6e4c992)
Task 1: complete (probe run 2026-11-13 20:05 CET, throwaway branch deleted; answers below)
Task 1: Ruling: info.json uses "spoiling_required": true, not "feature_flags": ["spoiling"] — the game refused to load with feature_flags ("Spoiling is disabled") and space-age/info.json uses spoiling_required — cost if wrong: none, the probe proved it loads.
Task 1: answers: both position fields set (chest and ground); spoil() works; 9 eggs -> 1 event (rounds up); SA 25 biter-egg -> 1 big-biter, 1 pentapod-egg -> 1 wriggler; 4800 eggs -> 480 events, 2.6 ms; drop_full_stack lands 1 entity of 10.
Task 1: table: 9 eggs give one event -> each loot pile hatches one monster; Task 5 waits for the maintainer's answer.
Task 2: complete (no commit: PR 1 commits at the end of Task 4; tests: make lua -> 23/23 pass)
Task 3: complete (no commit yet; tests: make lua -> 31/31 pass)
Task 4: Ruling: info.json gets "spoiling_required": true instead of the plan's "feature_flags": ["spoiling"] — the probe showed the feature flag does not load — cost if wrong: none, tested
Task 4: Ruling: .luacheckrc makes game writable for tests/ingame (a test may change game state) — luacheck forbids field writes on the read-only global game — cost if wrong: a test could reassign game unnoticed. Task 8 needs nothing extra.
Task 4: Ruling: index forces as game.forces["player"] / ["enemy"], not .player — LuaLS reports undefined-field for .player — cost if wrong: none. Tasks 6 and 8 code uses .enemy/.player in four places: apply the same.
Task 4: steps 1-9, 11, 12 done (make check green: 32 unit, gates, ingame base 5/5, SA 6/6). Step 10 icon check waits for the maintainer; Step 13 commit after it.
Task 4: /simplify (4 reviewers) applied: species carry tint and adopts; FEEDS list replaces copied chow items; adopt recipe from species.adopts; one space_age value in data.lua; tests use Names/Species. Skipped: unused helpers (PR 2/3 need them), multi-return, recipe passes, spec build caching, locale fallbacks, name prefixes, changelog note. make check green.
Maintainer 2026-11-14: loot eggs — keep (every loot pile hatches one monster). Task 5 unblocked. Icon check (Task 4 Step 10) deferred by maintainer.
Maintainer 2026-11-14: commit PR 1 locally, stack PR 2/3, push all as draft PRs without auto-merge. Then draft slice 2 spec + EGM.
Task 4: complete (commits 6e4c992..9ac60d8, tests: make check → Tests: 1 skipped, 6 passed (7 total))
Task 5: Ruling: branch feat/lifecycle-hatching cut from unmerged PR 1 (9ac60d8) instead of main after merge — maintainer asked for stacked draft PRs overnight — cost if wrong: a rebase after PR 1 changes
Task 5: complete (commits 9ac60d8..9ac60d8, tests: make lua → python3 -m tools.coverage_floor build/luacov.report.out)
Task 6: Ruling: /simplify (2 reviewers) found the species looked up twice (shell guard + Hatching.hatch) — shell keeps the guard (EGM F14 early return before random()) and calls Hatching.pick(species.units, ...); Hatching.hatch and its spec case removed — cost if wrong: re-add a 3-line wrapper
Task 6: simplify skipped: storing LuaRandomGenerator in storage (earlier ruling keeps only the seed); moving random() to a shared module (Task 8 lives in the same control.lua); weights scratch table (4 units, no measured cost); Species.unit_names / Helpers.surface (one test file uses them)
Task 6: complete (commits 9ac60d8..fafe8da, tests: make check → Tests: 1 skipped, 9 passed (10 total))
Task 7: Ruling: branch feat/lifecycle-loot cut from unmerged PR 2 (fafe8da) — stacked draft PRs per maintainer — cost if wrong: a rebase
Task 7: complete (commits fafe8da..fafe8da, tests: make lua → python3 -m tools.coverage_floor build/luacov.report.out)
Task 8: Ruling: loot_test uses game.forces["player"], Names.TECH and Species egg name instead of .player and literals — earlier LuaLS ruling and /simplify (names from core) — cost if wrong: none
Task 8: Ruling: /simplify (2 reviewers) — event filter built from Species.ALL by spawner name instead of type unit-spawner (species table is the single source; no calls for Gleba or other mods' spawners); research guard simplified (this mod's tech exists on every force); Helpers.research and Helpers.count_items added; test spawner name from Species — cost if wrong: none, tests cover
Task 8: simplify skipped: early return before random() when not researched (would duplicate core's gate in the shell); dropping the ROADMAP line (the plan requires it, EGM R3); local surface closure (matches hatching_test)
Task 8: complete (commits fafe8da..4498d52, tests: make check → Tests: 1 skipped, 12 passed (13 total))
Final review: fresh reviewer (opus), package review-6e4c992..4498d52.diff — 0 Critical, 2 Important, 4 Minor
Final: Ruling: Important 1 (name filter can fail when another mod removes a vanilla spawner) — reverted the Task 8 /simplify ruling to the spec's type = "unit-spawner" filter; Loot.drop already ignores other spawners; no RED test possible without a mod that removes a spawner, the loot tests stay green — cost if wrong: a few extra handler calls per spawner death
Final: fixed Important 2 (a unit removed by another mod crashes the hatch on every load) — spec "the available units" RED→GREEN, suite 43/43; shell filters species.units by prototypes.entity before the pick
Final: minor (deferred): Hatching.pick fallback returns the last unit even when its weight is 0 (unreachable for r in [0,1))
Final: minor (deferred): no in-game test spills 1 to 3 eggs on the ground and checks one hatch (rests on the probe)
Final: minor (deferred): eggs have no item description warning that they hatch an enemy monster
Final: minor (deferred): spec drift on the loot filter — resolved by the Important 1 revert
```
