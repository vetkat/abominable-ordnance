# Lua tooling: Stage 9 implementation readiness report

Target: `docs/superpowers/specs/2026-11-13-lua-tooling-design.md`, lines
1 to 288. The spec has no implementation plan section, so the reviewers
read the whole file. Reviewers: `egm-implementation-readiness` and
`egm-codebase-details` with the implementation-readiness standard, and
`egm-style`. All three completed.

## Implementation readiness

Verdict: not ready.

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| IR-B1 | 🔴 Blocker | 78-87, 114-123, 135, 191-194 | luacheck and StyLua walk `.factorio-api/`. Same as DC-B1. Give the full `.styluaignore`. |
| IR-M1 | 🟡 Major | 53-54, 86 | The reformatted files are not named. |
| IR-M2 | 🟡 Major | 69-86, 273-278 | No commit order. The format pass, `package.json`, the exclusions and the CI steps must land before or with the new `make lua`. |
| IR-M3 | 🟡 Major | 146-161 | `.luarc.json` is described, not given. Give the literal file. |
| IR-M4 | 🟡 Major | 167-169, 269-271 | The drift test has no file, no key list and no mapping between the two key formats. |
| IR-M5 | 🟡 Major | 93-106 | The core API of `tools/factorio_api.py` is not defined: step type, error form, entry point, HTTP client, how FMTK runs. |
| IR-M6 | 🟡 Major | 96-123 | A new run does not delete the old `factorio/` folder. Removed API names stay in the library, which defeats goal 1. |
| IR-M7 | 🟡 Major | 198-205 | The LuaLS release is a folder tree and StyLua is a zip. The lychee pattern does not fit. Give the URLs, the extract commands, the `PATH` lines and the cache key. |
| IR-M8 | 🟡 Major | 257-264 | The gate tests can pass for the wrong reason. The LuaLS test needs the library. The StyLua test needs a case that only the repository settings reject. Both need a passing control. |
| IR-N1 to IR-N6 | 🟢 Nit | various | Vague workflow-test strings. `api` as a prerequisite or a recipe line, and `.PHONY`. `cspell.json` is missing from Files. No clean baseline. `ignoreDir` patterns are not anchored. A stamp with missing files. |

## Codebase details

Verdict: fail.

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| CD-B1 | 🔴 Blocker | 62, 81, 114-123, 135, 192-194 | Same as IR-B1. |
| CD-M1 | 🟡 Major | 53-54, 86 | One-line blocks exist in four files, all under `spec/`. Name them. |
| CD-M2 | 🟡 Major | 141-142, 257-264 | The LuaLS gate test runs LuaLS a second time in `make tools`. The estimate is about 9.7 seconds. Same as DC-M2. |
| CD-M3 | 🟡 Major | 77, 262-264 | The LuaLS gate test in `tmp_path` gets no library. The log path is not set. |
| CD-M4 | 🟡 Major | 146-169, 269-271 | The drift test is not specified and always skips in CI. |
| CD-M5 | 🟡 Major | 203-205 | Same as IR-M7. |
| CD-M6 | 🟡 Major | 96-106 | Same as IR-M6. |
| CD-M7 | 🟡 Major | 45-48, 160-161 | No baseline for the current code. |
| CD-N1 to CD-N9 | 🟢 Nit | various | Reuse `SEMVER`, the download and the `npm ci` message. The FMTK command. The `plan()` return type. Name the 13 factorio-test globals. "The core does no I/O" is not in `docs/architecture.md`. `.PHONY`. The cache key can reuse the `ingame` step. Exact workflow-test strings. No update path for FMTK. |

Verified as accurate: the `check.yml` structure, the lychee step, the
column width, the `spec/fixtures/` exclusion, the `package.py` whitelist,
`text_check` and lychee reading only tracked files, the scopes of
`.busted` and `.luacov`, and the hook running `make fast`.

## Style

No Blockers.

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| S9-M1 | 🟡 Major | 96-99 | No return type for `plan`. "Problem" is also LuaLS's word. |
| S9-M2 | 🟡 Major | 146-158 | `.luarc.json` items mix real keys and descriptions. |
| S9-M3 | 🟡 Major | 167-169 | "The FMTK settings" has no defined set. |
| S9-M4 | 🟡 Major | 74-76, 269-271 | The drift test has no file. |
| S9-M5 | 🟡 Major | 153-154, 193-194, 257-264 | Planted files in `spec/fixtures/` are ignored by both tools. |
| S9-M6 | 🟡 Major | 203-205 | The `PATH` folder is not named. |
| S9-N1 to S9-N9 | 🟢 Nit | various | The files are not named. "The download and the runner". How fmtk runs, and where temporary files go. "Current" is not defined. The hedged time limit. "Gives the globals". Ignore syntax differs. "Stamp" means two things. "The maintained source". |
