# Lua tooling: Stage 7 critic report

Target: `docs/superpowers/specs/2026-11-13-lua-tooling-design.md`, lines
1 to 288. Reviewers: `egm-design` and `egm-structural` with the
feature-spec standard, and `egm-style`. All three completed. This was one
round, without fixes between reviewers.

## Design critic

Verdict: not ready.

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| DC-B1 | 🔴 Blocker | 67, 79-86, 114-123, 135, 191-194 | `luacheck .` lints the 1,171 generated files in `.factorio-api/`, because `.luacheckrc` does not exclude it. `.styluaignore` copies the gap. Same as ZO-1. |
| DC-B2 | 🔴 Blocker | 58-67 | No Alternatives Considered section, which the feature-spec standard requires. Name rejected options for the type checker, type source, formatter and gate placement. |
| DC-M1 | 🟡 Major | 168-169, 257-271, 276 | The new gate tests and the drift test always skip in CI. Same as ZO-2 and IC-1. |
| DC-M2 | 🟡 Major | 28, 141-142, 262-264 | The time estimate leaves out the second LuaLS run inside pytest. That gives about 9.7 seconds on day one. |
| DC-M3 | 🟡 Major | 77, 153-154, 262-264 | The LuaLS gate test has no place to live: `spec/` is ignored, and a temporary folder breaks the relative library path. It needs a positive control. |
| DC-M4 | 🟡 Major | 8-11, 23-24, 232-247 | No risk for false negatives. LuaLS does not check untyped parameters, `storage`, dynamic `data.raw` keys, or prototype fields in `data:extend`. |
| DC-M5 | 🟡 Major | 114-127, 160-161 | The spec does not check other tools that walk the tree. Suggestion: put the cache outside the worktree. |
| DC-M6 | 🟡 Major | 200-209, 234-235 | `actions/cache` saves only on success, so a failed run downloads again. Run `make api` as its own step with restore and save. |
| DC-N1 | 🟢 Nit | 80, 211-213 | No upgrade path for FMTK. |
| DC-N2 | 🟢 Nit | 148-149, 203-205 | No security item. No checksums for downloads. `plugin.lua` runs with full I/O. |
| DC-N3 | 🟢 Nit | 86, 222-223 | The format commit must come before, or with, the gate. |
| DC-N4 | 🟢 Nit | 136-139 | Each new worktree needs a download. |
| DC-N5 | 🟢 Nit | 160-165 | Neither gate separates the data and control stages. |
| DC-N6 | 🟢 Nit | 201-202 | The CI cache key ignores the generator code. |

## Structural reviewer

Verdict: not ready, because of ST-B1.

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| ST-B1 | 🔴 Blocker | 58-67 | No Alternatives Considered section. Same as DC-B2. |
| ST-M1 | 🟡 Major | 232-247 | Risks has no security item: binary downloads without checksums, a third-party npm package, outside JSON into a generator. |
| ST-M2 | 🟡 Major | 69-86, 191-194 | `.luacheckrc` is missing from the Files table. Same as DC-B1. |
| ST-M3 | 🟡 Major | 167-169, 269-271 | The drift test is described twice and has no file. No fixture paths. |
| ST-M4 | 🟡 Major | 21-28, 273-278 | Goal 3 has no acceptance criterion. |
| ST-M5 | 🟡 Major | 236-238 | "The maintainer decides what to do" is not a mitigation, and conflicts with lines 173-174. |
| ST-N1 | 🟢 Nit | 21, 280 | Goals and non-goals have no headings. |
| ST-N2 | 🟢 Nit | 28, 141, 277 | Time limits use different hedges. |
| ST-N3 | 🟢 Nit | 96-99 | The return type of `plan()` is unclear. |
| ST-N4 | 🟢 Nit | 62-86 | Table cells end with and without full stops. |
| ST-N5 | 🟢 Nit | 198-205 | The `lua` job needs Python for `make api`. The spec does not say so. |

## Style reviewer

No Blockers.

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| SY-M1 | 🟡 Major | 28, 277 | "Under about 10 seconds" is not measurable. Remove "about". |
| SY-M2 | 🟡 Major | several | Four terms for `.factorio-api/`: API copy, cache, this folder, the folder. Use one. |
| SY-M3 | 🟡 Major | 67, 163-165 | "luacheck gives the globals of each file" does not say what luacheck does. |
| SY-M4 | 🟡 Major | 222-223 | The hook paragraph does not give the link between its two sentences. Same as CO-2. |
| SY-M5 | 🟡 Major | 237-238 | A risk with no decision in it. Same as ST-M5. |
| SY-M6 | 🟡 Major | 63 | "FMTK is the maintained source" is not supported by the facts. |
| SY-N1 to SY-N11 | 🟢 Nit | various | Phrasal verbs, "type check" for "type library", the non-defining clause at line 99, "the download" for the download function, the lead-in at lines 108-112, the reason for searching class files, "planned cost", the drift test described twice, "false problem" undefined, "keep their form", "a search is enough" unsupported, a missing full stop at line 86, and the vague heading "A new download". |
