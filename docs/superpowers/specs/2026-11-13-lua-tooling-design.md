# Abominable Ordnance: Lua tooling

Date: 2026-11-13. Status: the maintainer approved the design in chat. An
EGM review (Stages 5 to 9) followed. This version applies its findings,
as the maintainer approved. The spec waits for the maintainer's review.

## Purpose

The agent writes most of the mod's Lua. Today the gates check Lua syntax
and globals (luacheck) and the logic in `core/` (busted). No gate checks
that the code uses the Factorio API correctly. A wrong event name or a
misspelt field appears only in the game, or in the `ingame` CI job, which
starts a headless Factorio server.

This project adds three things:

1. A type check of the mod's Lua against the Factorio 2.1 API, in
   `make fast` and in CI.
2. One fixed Lua format, checked in `make fast` and in CI.
3. A local copy of the Factorio API for the pinned version, which the
   agent can search.

### Goals

1. `make lua` fails on an unknown API name, such as
   `defines.events.on_entity_dyed`, in a mod file.
2. `make lua` fails on a Lua file that is not formatted.
3. A change to `.factorio-version` updates the API folder and the type
   library, with no other edit.
4. `make fast` takes under 10 seconds on the maintainer's machine.

The out-of-scope list is at the end of this spec. Terms are as in the
repository and CI spec,
[2026-11-12-repo-and-ci-design.md](2026-11-12-repo-and-ci-design.md). In
short:

- `make fast` runs `make text`, `make lua` and `make tools`. The git
  pre-commit hook runs `make fast` before each commit. `make check` runs
  `make fast` and the in-game tests, before a PR.
- CI runs each of `make text`, `make lua` and `make tools` in a job of
  its own. The job `all-checks` must pass before a merge.
- The core is the code in `core/`. It is pure: it does not call the game
  API (`docs/architecture.md`), and by the functional-core rules it does
  no I/O.
- factorio-test is the framework for the in-game tests in
  `tests/ingame/`.

## Facts found during design

The agent checked these facts on 2026-11-13.

- Factorio publishes its API as JSON for each version:
  `https://lua-api.factorio.com/<version>/runtime-api.json` and
  `prototype-api.json`. For 2.1.24 the two files are about 2 MB each. The
  site publishes no checksums. The Steam install of the game has the same
  files in `doc-html/`. The headless server does not.
- FMTK, the Factorio Mod Tool Kit, is the npm package `factoriomod-debug`.
  Version 2.1.9 gives the command
  `fmtk docs -d <runtime> -p <prototype> <outdir>`. From the 2.1.24 files
  it writes a type library for lua-language-server (LuaLS) to
  `<outdir>/factorio/`: `library/`, `plugin.lua` and `config.json`. The
  library has 1,171 files and is about 7.5 MB.
- LuaLS 3.19.2 runs headless with `lua-language-server --check .`. It exits
  with 1 when it finds a problem and with 0 when it finds none. On this
  repository it takes about 2.6 seconds. On a workspace with one file it
  takes about 2.7 seconds, because loading the library takes most of the
  time.
- With the `.luarc.json` in this spec, LuaLS finds no problems in the
  current repository. It finds a planted unknown event and a planted
  misspelt field.
- The library folder must be in `workspace.ignoreDir`. If it is not, LuaLS
  also checks the library and reports about 1,900 problems in it. LuaLS
  still loads a folder in `workspace.library` when the folder is in
  `workspace.ignoreDir`.
- LuaLS does not apply the settings in FMTK's `config.json` from a library
  folder. With `runtime.builtin` unset, `io.open` gives no problem. So
  `.luarc.json` must copy those settings.
- LuaLS checks an inline event handler, because FMTK's plugin gives its
  parameter a type. It does not check a named handler without an
  annotation. With `---@param event EventData.on_entity_died`, it reports
  the misspelt field.
- LuaLS does not check the fields of an untyped table in `data:extend`.
  With `---@type ItemPrototype`, it reports a missing `stack_size`.
- StyLua 2.6.0 is on npm as `@johnnymorganz/stylua-bin`. The package has
  no install script. It takes its binary from a platform package that
  `package-lock.json` pins with an integrity hash. Its author publishes
  it with npm provenance. One run takes about 0.2 seconds.
- With the settings in this spec, StyLua changes four files:
  `spec/architecture_spec.lua`, `spec/docs_spec.lua`,
  `spec/support/architecture.lua` and `spec/support/locale.lua`. Each
  change splits a one-line `if` or `for` block.
- `make fast` takes 4.4 seconds before this project.
- Arch Linux packages `lua-language-server` 3.19.2.
- The SHA-256 of `lua-language-server-3.19.2-linux-x64.tar.gz` is
  `93ad326b10f6c00911dd8c450fa098332dbd8f9f45d1052f5636a2d54479b947`.

## Decisions

| Topic | Decision | Why |
| --- | --- | --- |
| API folder | `.factorio-api/`, which git ignores. Not committed. | Each Factorio version would add about 4 MB to the history. `.factorio-version` stays the only pin. |
| How the API folder is built | A Make file target, as `tools/ingame.sh` does for the server. | Make already knows when a file is older than its inputs. A Python tool would answer the same question with more code. |
| Type library | Generated by `fmtk docs` from the API JSON. | FMTK 2.1.9 generates a LuaLS library from the 2.1.24 JSON, and LuaLS found the planted mistakes with it. |
| Type checker | LuaLS `--check` at level Warning. Any problem fails. | A warning that never fails gets ignored. |
| Formatter | StyLua from npm, as a check only. `make format` rewrites files. | npm pins one version for the maintainer and CI. Nothing rewrites files unless a person or the agent asks. |
| Gate tests | The tests that need LuaLS or StyLua run in `make gates`, not in `make fast`. | A second LuaLS run would bring `make fast` to about 9.8 seconds. |
| FMTK scope | `fmtk docs` only. The README recommends the FMTK VS Code extension for its debugger and profiler. | Upload to the mod portal waits for design version 1, the first release with mod features. `package.py` stays the build. |
| luacheck | Stays. | luacheck sets the allowed globals for each folder and checks `spec/`. LuaLS does neither. |

## Alternatives considered

| Topic | Option | Why not |
| --- | --- | --- |
| Type checker | The EmmyLua analyser (`emmylua_check`) | Not tested with the FMTK library. The FMTK VS Code extension and the LuaLS extension both use LuaLS, so the gate and the editor agree. |
| Type checker | A script that checks names against the JSON | It finds unknown names but not wrong field types or missing fields, and the project would maintain a Lua parser. |
| Type source | A Python generator in `tools/` | It repeats FMTK's work for hundreds of type shapes. |
| Formatter | LuaFormatter (`lua-format`) | It needs a C++ build on CI and has no npm package. StyLua has one. |
| Formatter | StyLua from pacman | The local version floats and can format code in a different way from CI. |
| Gate placement | The type check in CI only | The agent would see an API mistake only after a push. The point is to catch it in the commit that makes it. |
| API folder | Shared between worktrees, outside the repository | `.luarc.json` would need absolute paths or a symlink. Each worktree pays about 4 MB and one `fmtk docs` run instead. |

## Files

| File | Change |
| --- | --- |
| `Makefile` | New targets `.factorio-api/stamp`, `format` and `gates`. `lua`, `tools` and `check` change. |
| `.luarc.json` | New. LuaLS settings, with paths relative to the repository. |
| `stylua.toml` | New. StyLua settings. |
| `.styluaignore` | New. StyLua exclusions. |
| `.luacheckrc` | Add `".factorio-api/**"` to `exclude_files`. |
| `package.json`, `package-lock.json` | Add `factoriomod-debug` 2.1.9 and `@johnnymorganz/stylua-bin` 2.6.0 as development dependencies. |
| `pyproject.toml` | Register the pytest marker `gates`. |
| `.gitignore` | Add `.factorio-api/`. |
| `cspell.json` | Add the words that the new text needs, such as `FMTK` and `pacman`. |
| `tools/tests/test_gates.py` | Two new tests with the marker `gates` (see Testing). |
| `tools/tests/test_workflows.py` | Two new tests (see Testing). |
| `.github/workflows/check.yml` | The `lua` job installs Node, the npm packages and LuaLS, restores the API folder and runs `make gates`. |
| `README.md` | Tools, targets, the FMTK extension, the FMTK upgrade steps. |
| `CLAUDE.md` | Two rules (see The agent). |
| `docs/architecture.md` | A section on type annotations (see The type check). |
| `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md` | The Make targets table points to this spec. |
| `spec/architecture_spec.lua`, `spec/docs_spec.lua`, `spec/support/architecture.lua`, `spec/support/locale.lua` | One StyLua pass. |

## The API folder

The Makefile builds the API folder with a file target:

```make
API      := .factorio-api
FACTORIO := $(shell tr -d '[:space:]' < .factorio-version)
DOCS     := https://lua-api.factorio.com/$(FACTORIO)
FMTK     := node_modules/.bin/fmtk

$(API)/stamp: .factorio-version package-lock.json
	@test -x $(FMTK) || \
	  { echo "fmtk is missing: run \`npm ci\`, then try again"; exit 1; }
	rm -rf $(API)
	mkdir $(API)
	curl -fsSL -o $(API)/runtime-api.json $(DOCS)/runtime-api.json
	curl -fsSL -o $(API)/prototype-api.json $(DOCS)/prototype-api.json
	$(FMTK) docs -d $(API)/runtime-api.json -p $(API)/prototype-api.json $(API)
	echo "factorio $(FACTORIO)" > $@
```

Make runs the recipe when the stamp is missing, or older than
`.factorio-version` or `package-lock.json`. A new FMTK version changes
`package-lock.json`, so it also rebuilds the folder.

The recipe deletes the whole folder first. So no class file from an old
version stays in the library, and no old stamp stays behind. It writes the
stamp last. So a run that stops part way leaves no stamp, and the next run
starts again. When `curl` or `fmtk` fails, Make shows its error and stops.

The folder then holds:

```text
.factorio-api/
  stamp                    factorio 2.1.24
  runtime-api.json
  prototype-api.json
  factorio/                fmtk docs output
    library/  plugin.lua  config.json
```

Each class in `factorio/library/` has a file of its own, with a line such
as `---@class LuaEntity`. A search for that line gives one class, not a
2 MB JSON file.

## Make targets

| Target | Change |
| --- | --- |
| `.factorio-api/stamp` | New. Builds the API folder (see The API folder). |
| `make format` | New. `node_modules/.bin/stylua .` |
| `make lua` | Depends on `.factorio-api/stamp`. Runs luacheck, `stylua --check .`, `lua-language-server --check . --checklevel=Warning`, busted and the coverage floor. |
| `make tools` | `python3 -m pytest -m "not gates"`, then `check_version.py` as now. |
| `make gates` | New. Depends on `.factorio-api/stamp`. `python3 -m pytest -m gates`. |
| `make check` | `make fast`, `make gates` and `make ingame`. |
| `make setup` | No change. It stays offline. |

`.PHONY` gets `format` and `gates`.

The first `make lua` after a clone, or after a change to
`.factorio-version`, needs the network and `npm ci`. Each later run uses
the API folder. The same holds for each new working copy that
`git worktree` makes.

The estimated time of `make fast` is about 7.2 seconds: 4.4 seconds now,
about 2.6 for LuaLS and about 0.2 for StyLua. When the stamp is current,
Make only compares three file times. The implementation plan measures
the real time.

The CI spec has a fallback for a slow `make fast`: the hook checks only
the staged files. That fallback does not apply to LuaLS. LuaLS reads the
whole workspace to resolve `require` calls. The maintainer then
decides where the LuaLS check runs.

## The type check

`.luarc.json`:

```json
{
  "runtime.version": "Lua 5.2",
  "runtime.path": ["?.lua"],
  "runtime.builtin": { "io": "disable", "os": "disable", "coroutine": "disable" },
  "runtime.plugin": ".factorio-api/factorio/plugin.lua",
  "workspace.library": [".factorio-api/factorio/library"],
  "workspace.ignoreDir": [
    ".factorio-api", "spec", "tools", "build", "node_modules", "docs",
    ".lua", ".luarocks", ".install"
  ],
  "workspace.checkThirdParty": false,
  "diagnostics.globals": [
    "__DebugAdapter", "__Profiler",
    "test", "describe", "it", "before_each", "after_each", "before_all",
    "after_all", "async", "done", "after_ticks", "on_tick",
    "ticks_between_tests", "tags"
  ],
  "diagnostics.disable": ["lowercase-global"],
  "language.fixIndent": false
}
```

These values come from two sources:

- `runtime.version`, `runtime.path`, `runtime.builtin`, the first two
  names in `diagnostics.globals`, `diagnostics.disable` and
  `language.fixIndent` copy the `settings` object of FMTK 2.1.9's
  `config.json`.
- The other 13 names in `diagnostics.globals` are the factorio-test
  globals, as in the `ingame` list in `.luacheckrc`.

The `ignoreDir` names do not start with `/`, so they also match folders
deeper in the tree. This is on purpose, because the mod has no deeper
folders with these names.

So LuaLS checks `control.lua`, the `data*.lua` and `settings*.lua` files,
`core/`, `prototypes/` and `tests/ingame/`. The game does not give mods
`io`, `os` or `coroutine`, so LuaLS reports their use. In `core/` that
also supports the functional-core rule that the core does no I/O.

LuaLS reads `diagnostics.globals` for every file. So LuaLS does not report
`describe` in `core/`. luacheck sets the allowed globals for each folder,
and it fails on `describe` in `core/`.

### Type annotations

LuaLS checks only values whose type it knows. `docs/architecture.md`
gets a section with two rules, so that the shell code has types:

- A named event handler gets `---@param event EventData.<event name>`.
  An inline handler needs no annotation.
- A prototype table for `data:extend` gets `---@type <Prototype class>`,
  for example `---@type ItemPrototype`.

LuaLS still does not check values read from `storage`, `data.raw` lookups
with keys that the code builds, or any value of type `any`. The busted
tests and the in-game tests stay the check for those.

### False positives

A false positive is a problem that LuaLS reports on correct code. It gets
a line such as `---@diagnostic disable-next-line: undefined-field`, with a
comment above it that gives the reason. No setting turns off a diagnostic
for a whole file or for the workspace.

When the mod has more than five inline exceptions for one diagnostic
code, the agent opens an issue. The maintainer then makes one of two
choices. One choice is a workspace exception for that code in
`.luarc.json`. The other is a report of the wrong type to FMTK, and the
inline exceptions stay.

VS Code with the LuaLS extension uses the same `.luarc.json`. The FMTK
extension also offers to write `.luarc.json`. The README says to keep the
committed file.

## The format check

`stylua.toml`:

```toml
column_width = 100
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
```

The column width matches `max_line_length` in `.luacheckrc`.

`.styluaignore` uses the gitignore syntax:

```text
.factorio-api/
spec/fixtures/
node_modules/
build/
docs/archive/
.lua/
.luarocks/
.install/
```

These are the folders in `exclude_files` in `.luacheckrc`, in the
gitignore syntax. `spec/fixtures/` holds planted bad files. They must stay
as they are, so that the tests that use them still fail as planned.

## CI

The `lua` job in `check.yml` gets these steps before `make lua`:

```yaml
- uses: actions/setup-node@v7
  with:
    node-version: 22
    cache: npm
- run: npm ci
- name: Install lua-language-server
  run: |
    mkdir -p "$HOME/.local/luals"
    curl -fsSL -o luals.tar.gz https://github.com/LuaLS/lua-language-server/releases/download/3.19.2/lua-language-server-3.19.2-linux-x64.tar.gz
    echo "93ad326b10f6c00911dd8c450fa098332dbd8f9f45d1052f5636a2d54479b947  luals.tar.gz" | sha256sum -c
    tar -xzf luals.tar.gz -C "$HOME/.local/luals"
    rm luals.tar.gz
    echo "$HOME/.local/luals/bin" >> "$GITHUB_PATH"
- id: factorio
  run: echo "version=$(cat .factorio-version)" >> "$GITHUB_OUTPUT"
- id: api
  uses: actions/cache@v6
  with:
    path: .factorio-api
    key: factorio-api-${{ steps.factorio.outputs.version }}-${{ hashFiles('package-lock.json') }}
- name: Mark the restored API folder as current
  if: steps.api.outputs.cache-hit == 'true'
  run: touch .factorio-api/stamp
```

The `touch` step is necessary. The checkout gives every file the current
time, and the cache restores the stamp with its old time. Without the
step, Make would rebuild the folder on every run. The cache key holds the
same inputs as the Make target, so a restored folder is current.

After `make lua`, the job sets up Python with `actions/setup-python`, as
the `tools` job does, then runs `pip install pytest` and `make gates`.
The Python of the Ubuntu runner refuses `pip install`.

`actions/cache` saves the folder only when the job passes. A failed run
on a new key downloads the JSON again on the next run. That costs a few
seconds, a few times per Factorio version. This spec accepts that cost.

`release.yml` calls `check.yml`, so a release runs the new checks too.
`weekly.yml` does not change. A PR that changes `.factorio-version`
changes the cache key, so CI downloads the new API and builds the new
library.

Dependabot covers only GitHub Actions. A new version of LuaLS, FMTK or
StyLua is a PR by hand, as for lychee today.

## The agent

`CLAUDE.md` gets two rules:

- Before you use a Factorio API name, look it up in
  `.factorio-api/factorio/library/`. Give that path to the search. A
  search from the repository root skips the folder, because git ignores
  it.
- Run `make format` before you stage Lua files.

## Developer setup

The README changes:

- The pacman line gets `lua-language-server`. StyLua and FMTK come from
  `npm ci`.
- The targets table gets `make format` and `make gates`, and the new
  steps in `make lua`, `make tools` and `make check`.
- It recommends the FMTK extension for VS Code, for its debugger and
  profiler in the running game. It says to keep the committed
  `.luarc.json` if the extension offers to write one.
- It gives the FMTK upgrade steps: change the version in `package.json`,
  run `npm install`, run `make lua`, then compare the `settings` object
  in `.factorio-api/factorio/config.json` with `.luarc.json`. The same
  comparison applies to the factorio-test globals after a factorio-test
  upgrade.

## Commit order

The git hook runs `make fast` on every commit. So each commit must pass
it:

1. StyLua and the API folder exclusions: `package.json`,
   `package-lock.json`, `stylua.toml`, `.styluaignore`, `.luacheckrc`,
   `make format`, the StyLua pass over the four files, and
   `stylua --check` in `make lua`.
2. The type check: `.factorio-api/stamp`, `.luarc.json`, `.gitignore`,
   and LuaLS in `make lua`.
3. The gate tests: the `gates` marker, `make gates`, the `make tools` and
   `make check` changes, and the tests.
4. CI: the `lua` job steps and the workflow tests.
5. Docs: `README.md`, `CLAUDE.md`, `docs/architecture.md`, `cspell.json`
   and the pointer in the CI spec.

CI checks the head of the PR, so only the last commit needs a green CI.

## Risks

- **A new outside source.** The API JSON comes from lua-api.factorio.com.
  CI caches it by version. GitHub removes a cache that is not used for 7
  days, so a quiet repository downloads it again more often. If the site
  is down and the cache is empty, the `lua` job fails. The CI spec
  accepts the same risk for the headless server.
- **Supply chain.** These checks run code from outside the project. FMTK
  and StyLua come from npm, and `package-lock.json` pins each package
  with an integrity hash. The LuaLS download has a SHA-256 check in CI.
  LuaLS runs FMTK's `plugin.lua`, with full Lua I/O, on each check.

  The API JSON has no checksum, and FMTK reads it as data. A version
  change of any of these tools is a reviewed PR.
- **False positives.** The FMTK types can be wrong or incomplete. See
  False positives for the rule.
- **False negatives.** LuaLS does not check values without a known type.
  See Type annotations for the cases. A clean `make lua` does not prove
  that the code uses the API correctly. The in-game tests stay
  necessary.
- **FMTK lags behind Factorio.** A new Factorio version can change the
  JSON format before FMTK supports it. Then the API folder target fails,
  and the move to the new version waits for FMTK.
- **The local LuaLS version floats.** On the maintainer's machine, LuaLS
  comes from pacman. A newer version can report a problem that CI does
  not, or the reverse. CI pins it and is the source of truth.
- **`make fast` grows.** LuaLS time grows with the code. See Make
  targets.

## Testing

`test_gates.py` gets two tests with the marker `gates`. They run in
`make gates`, which builds the API folder first. A missing tool or a
missing API folder fails them. They do not skip.

- **LuaLS.** The test writes a `.luarc.json` into `tmp_path`. It is the
  repository's `.luarc.json` with absolute paths to the library and the
  plugin in the repository's `.factorio-api/factorio/`. It runs LuaLS
  with `--logpath` in `tmp_path`, first on a file with
  `defines.events.on_entity_dyed`, then on the same file with
  `on_entity_died`. The first run exits with 1 and reports
  `undefined-field`. The second run exits with 0.
- **StyLua.** The test runs StyLua with the repository's `stylua.toml`,
  first on a file indented with four spaces, then on the same code
  indented with two spaces. The first run fails and the second passes.
  StyLua's default indent is a tab, so the second run passes only when
  StyLua reads the repository settings.

`test_workflows.py` gets two tests:

- `check.yml` installs LuaLS with a `sha256sum -c` line, caches the path
  `.factorio-api`, touches `.factorio-api/stamp` and runs `make gates`.
- `make lua` in the Makefile depends on `.factorio-api/stamp`.

The tests check strings in the files, as the existing tests in that file
do.

### Acceptance criteria

1. `make check` passes on a clean clone after `npm ci`, with LuaLS
   installed.
2. Each new gate fails on its planted mistake and passes on the clean
   case. `make gates` shows this locally, and the CI `lua` job runs it.
3. A change of `.factorio-version` to another version that FMTK supports,
   on a branch, rebuilds the API folder in the next `make lua`. The stamp
   then names the new version.
4. `make fast` takes under 10 seconds. The implementation plan records
   the time.
5. CI's `all-checks` passes on the PR.

## Out of scope

- Upload to the mod portal with `fmtk upload` or `fmtk publish`. Design
  version 1 adds it.
- A type check of `spec/`. Busted tests use `io`, and the Factorio
  settings disable `io`.
- Type annotations beyond the two rules in Type annotations.
- A check that separates the data stage from the control stage. Neither
  luacheck nor LuaLS makes this check.
- A Claude Code hook that formats files after each edit.
- A search tool for the API folder. A search for `---@class <Name>` in
  the library finds each class file.
