# Lua tooling: consolidated EGM review

Target: `docs/superpowers/specs/2026-11-13-lua-tooling-design.md`. Mode:
consolidated report, Stages 5 to 9, with no fixes between stages. All 11
reviewers completed. The stage reports are:

- [Stage 5, zoom-out][s5]
- [Stage 6, comprehension][s6]
- [Stage 7, critic][s7]
- [Stage 8, intermediate zoom-out][s8]
- [Stage 9, implementation readiness][s9]

[s5]: 2026-11-13-lua-tooling-zoom-out-report.md
[s6]: 2026-11-13-lua-tooling-comprehension-report.md
[s7]: 2026-11-13-lua-tooling-critic-report.md
[s8]: 2026-11-13-lua-tooling-intermediate-zoom-out-report.md
[s9]: 2026-11-13-lua-tooling-plan-readiness-report.md

## Facts that the author checked after the reviews

The author ran four probes with LuaLS 3.19.2, FMTK 2.1.9 and the 2.1.24
JSON:

1. LuaLS does not apply FMTK's `config.json` from a library folder. With
   `runtime.builtin` unset, `io.open` gives no problem. So `.luarc.json`
   must copy the settings (IC-5).
2. An inline handler with a misspelt field gives `undefined-field`. A
   named handler with no annotation gives nothing. With
   `---@param event EventData.on_entity_died`, it gives `undefined-field`
   (DC-M4).
3. A misspelt prototype field in an untyped `data:extend` table gives
   nothing. With `---@type ItemPrototype`, LuaLS reports the missing
   `stack_size` (DC-M4).
4. LuaLS on a one-file workspace with the library takes 2.7 seconds. A
   LuaLS gate test in `make tools` brings `make fast` to about 9.8
   seconds (DC-M2, CD-M2).

Other facts: the Steam install has `doc-html/runtime-api.json` for
2.1.24, and the headless server has none (IC-7). StyLua 2.6.0 is on npm
as `@johnnymorganz/stylua-bin` (IC-2). Without `spec/fixtures/`, StyLua
changes four files, all in `spec/` (CD-M1).

## Action items

### 🔴 Blockers

| Item | Findings | Proposed resolution |
| --- | --- | --- |
| A1 | ZO-1, DC-B1, ST-M2, IR-B1, CD-B1 | Add `".factorio-api/**"` to `exclude_files` in `.luacheckrc`. Give the full `.styluaignore` with `.factorio-api/` by name. Add `.luacheckrc` to Files. |
| A2 | DC-B2, ST-B1 | Add a short Alternatives table: type checker (EmmyLua analyser, a name check against the JSON), type source (a Python generator), formatter (LuaFormatter), gate placement (CI only). |

### 🟡 Majors: decisions

| Item | Findings | Proposed resolution |
| --- | --- | --- |
| D1 | ZO8-1, ZO-3, ZO-4, ZO-7, IC-4, IC-6, IR-M5, IR-M6, CD-M6, S9-M1, CO-5, ST-N3 | Replace the Python tool with a Make file target `.factorio-api/stamp`, which depends on `.factorio-version` and `package-lock.json`. The recipe deletes the folder, downloads with `curl`, runs `npx --no-install fmtk docs` and writes the stamp last. `make lua` depends on the stamp. `make setup` stays offline. |
| D2 | DC-M2, CD-M2, IC-3 | Mark the LuaLS and StyLua gate tests `slow`. `make tools` skips them. `make check` and the CI `lua` job run them. Correct the fallback text: the staged-file rule does not apply to LuaLS. |
| D3 | IC-1, DC-M1, CD-M4 | The CI `lua` job runs `pytest -m slow` after `make lua`, so the gate tests run where the tools and the folder exist. |
| D4 | ZO-2, ZO8-2, IR-M4, CD-M4, ST-M3, S9-M3, S9-M4, ZO-6 | Drop the drift test. The FMTK upgrade step in the README says to compare `config.json` with `.luarc.json`. |
| D5 | IC-2, CO-9 | Pin StyLua through npm, `@johnnymorganz/stylua-bin` 2.6.0. Local and CI use the same version. The CI StyLua download goes. LuaLS still floats locally. |
| D6 | DC-M4 | Add a false-negative risk, and an annotation rule: a named event handler gets `---@param event EventData.<event>`, and a prototype table gets `---@type <Prototype>`. Put the rule in `docs/architecture.md`. |

### 🟡 Majors: text and detail

| Item | Findings | Proposed resolution |
| --- | --- | --- |
| T1 | CO-1, CO-2, SY-M4, ZO8-3 | One sentence on `make fast` and the hook. Delete the review-stamp paragraph. |
| T2 | CO-3 | "The implementation plan" and "the CI spec" in place of "the plan". |
| T3 | ST-M1, DC-N2 | A security risk. `sha256sum -c` for the LuaLS download. `package-lock.json` integrity covers npm. |
| T4 | ST-M4 | An acceptance criterion for goal 3. |
| T5 | ST-M5, SY-M5 | The false-positive rule: more than five inline exceptions for one diagnostic code means an issue, and the maintainer chooses a workspace exception or an FMTK report. |
| T6 | SY-M1, SY-M2, SY-M3, SY-M6, ST-N2 | One term, "the API folder". "Under 10 seconds". Plain wording for luacheck. Remove "the maintained source". |
| T7 | IR-M1, CD-M1 | Name the four reformatted files. |
| T8 | IR-M2 | A commit order: format pass and config, then tools and `make lua`, then CI and docs. Each commit passes `make fast`. |
| T9 | IR-M3, S9-M2 | Give the literal `.luarc.json`. |
| T10 | IR-M7, CD-M5, S9-M6, DC-M6 | Give the CI steps: LuaLS URL, extract folder, `PATH` line, cache key. Accept that a failed run downloads again. |
| T11 | IR-M8, CD-M3, DC-M3, S9-M5 | The LuaLS gate test writes a `.luarc.json` with absolute paths in `tmp_path`. It asserts `undefined-field`, and a clean file passes. The StyLua test uses a case that only the repository settings reject. |
| T12 | CD-M7 | Record the baseline: the current tree gives no problems. |

### 🟢 Nits

Apply the nits that the items above do not already cover: the reasons in
the Decisions table, table full stops, the factorio-test names, the
source of the no-I/O rule, the FMTK upgrade path, `.PHONY`, anchored
`ignoreDir` patterns, and `cspell.json` in Files.

## Rejected

| Findings | Reason |
| --- | --- |
| DC-M5, IC-8, DC-N4 | Moving or sharing the API folder needs absolute paths or a symlink. A1 fixes the root cause. |
| DC-M6 | Split cache steps save seconds a few times per version. |
| IC-7 | A second download source. The CI spec accepts the same risk for the server. |
| DC-N5 | Stage separation is a new feature. |
| IC-2, second half | A LuaLS version warning. LuaLS only reports, and CI pins it. |

## Traceability

Every finding ID from the five stage reports maps to one item above, to
the nits line, or to the rejected table.
