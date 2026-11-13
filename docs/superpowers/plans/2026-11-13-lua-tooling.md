# Lua tooling implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task by task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The gates get a LuaLS type check against the Factorio 2.1 API
and a StyLua format check. The agent gets a local API folder.

**Architecture:** A Make file target builds `.factorio-api/` from the
pinned Factorio version with `curl` and FMTK. `make lua` runs StyLua and
LuaLS after luacheck. The tests that need LuaLS or StyLua carry the
pytest marker `gates` and run in `make gates`, outside `make fast`.

**Tech stack:** GNU Make, LuaLS 3.19.2, FMTK (`factoriomod-debug`) 2.1.9,
StyLua 2.6.0 (`@johnnymorganz/stylua-bin`), pytest, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-13-lua-tooling-design.md`.
Read it before you start.

## Global constraints

- Work in the worktree `~/Documents/Abominable-Ordnance-lua-tooling` on
  branch `ci/lua-tooling`.
- Factorio target: the version in `.factorio-version` (2.1.24).
- Versions: LuaLS 3.19.2, `factoriomod-debug` 2.1.9,
  `@johnnymorganz/stylua-bin` 2.6.0. npm versions are exact, with no `^`.
- LuaLS SHA-256:
  `93ad326b10f6c00911dd8c450fa098332dbd8f9f45d1052f5636a2d54479b947`.
- Tools in `tools/` use the Python standard library only.
- `make fast` takes under 10 seconds.
- All text is British English. Run `make text` on changed Markdown.
- Commit as CLAUDE.md says: `/ste80-humanizer` on changed prose and
  comments, `/simplify` on changed code, then `git add` the files,
  `make stamp` and `git commit`, each as a Bash call of its own.
- The git hook runs `make fast` on each commit, so each commit must pass
  it.

## Deviation from the spec

The spec's recipe calls `npx --no-install fmtk`. This plan calls
`node_modules/.bin/fmtk` directly, as the recipe already tests that this
file exists. The tests in Task 3 replace it with a stub, and `npx` would
look for a real package. The behaviour is the same.

## Review focus

The spec implies these cases, and no other test covers them. Each one has
a test in the task named.

1. A fresh clone without `npm ci` runs `make lua`. Expected: a message
   that says to run `npm ci`, and no stamp. Task 3.
2. A download fails, for example when the computer is offline. Expected:
   Make fails, and no stamp stays behind, so the next run starts again.
   Task 3.
3. `.factorio-version` changes after a build. Expected: the next run
   deletes the old library and writes a stamp with the new version.
   Task 3.
4. The stamp is current. Expected: Make does nothing and needs no
   network. Task 3.
5. Someone adds a folder to `exclude_files` in `.luacheckrc` but not to
   `.styluaignore`. Expected: a test fails. Task 2.

---

### Task 0: Prerequisites

- [ ] **Step 1: Check for LuaLS**

Run: `lua-language-server --version`
Expected: `3.19.2`. If the command is missing, stop and ask the
maintainer to run `! sudo pacman -S lua-language-server`. The agent
cannot run `sudo`.

- [ ] **Step 2: Check the worktree**

Run: `git status --short && git log --oneline -1`
Expected: a clean tree on `ci/lua-tooling`, with the spec commit on top.

### Task 1: The `gates` marker and Make targets

**Files:**

- Modify: `pyproject.toml`
- Modify: `Makefile`
- Modify: `tools/tests/test_workflows.py`

**Interfaces:**

- Produces: the pytest marker `gates`. `make tools` runs
  `python3 -m pytest -m "not gates"`. `make gates` runs
  `python3 -m pytest -m gates`. `make check` runs `fast gates ingame`.
  Task 3 makes `gates` depend on the API folder.

- [ ] **Step 1: Write the failing test**

Add to `tools/tests/test_workflows.py`. Change the module docstring to:

```python
"""Static checks on the workflows and the Makefile, for rules that only fail on GitHub."""
```

```python
def makefile():
    return (ROOT / "Makefile").read_text(encoding="utf-8")


def test_make_fast_leaves_out_the_gate_tests():
    text = makefile()
    assert 'python3 -m pytest -m "not gates"' in text
    assert "python3 -m pytest -m gates" in text
    assert "\ncheck: fast gates ingame\n" in text
```

- [ ] **Step 2: Run it and see it fail**

Run: `python3 -m pytest tools/tests/test_workflows.py -k gate_tests`
Expected: FAIL on the first assertion.

- [ ] **Step 3: Register the marker**

Append to the `[tool.pytest.ini_options]` table in `pyproject.toml`:

```toml
# make gates runs these. They need LuaLS, StyLua and the API folder.
markers = ["gates: needs LuaLS, StyLua or the API folder; run by make gates"]
```

- [ ] **Step 4: Change the Makefile**

Change the `.PHONY` line to:

```make
.PHONY: setup fast check text lua tools gates format ingame stamp package
```

Change `check` and `tools`, and add `gates` after `tools`:

```make
## before a PR
check: fast gates ingame
```

```make
tools:
	python3 -m pytest -m "not gates"
	python3 -m tools.check_version

## the gate tests that need LuaLS, StyLua and the API folder
gates:
	python3 -m pytest -m gates
```

- [ ] **Step 5: Run the tests**

Run: `python3 -m pytest tools/tests/test_workflows.py`
Expected: PASS.

Run: `make tools`
Expected: PASS, with the same count of tests as before plus one.

Run: `make gates`
Expected: exit code 5 from pytest, "no tests ran", because no test has
the marker yet. Accept this. Task 2 adds the first one.

- [ ] **Step 6: Commit**

Run `/simplify` with one reviewer (under 50 lines, existing pattern).

```bash
git add pyproject.toml Makefile tools/tests/test_workflows.py
```

```bash
make stamp
```

```bash
git commit -m "build: add the gates pytest marker and make gates"
```

### Task 2: StyLua

**Files:**

- Modify: `package.json`, `package-lock.json`
- Create: `stylua.toml`, `.styluaignore`
- Modify: `Makefile`
- Modify: `tools/tests/test_gates.py`
- Reformat: `spec/architecture_spec.lua`, `spec/docs_spec.lua`,
  `spec/support/architecture.lua`, `spec/support/locale.lua`

**Interfaces:**

- Consumes: the `gates` marker (Task 1).
- Produces: `make format`. `make lua` runs `$(STYLUA) --check .`, where
  `STYLUA := node_modules/.bin/stylua`.

- [ ] **Step 1: Write the failing tests**

Add to `tools/tests/test_gates.py` (add `import re` at the top):

```python
STYLUA = ROOT / "node_modules/.bin/stylua"
FOUR_SPACES = "if ready then\n    return 1\nend\n"
TWO_SPACES = "if ready then\n  return 1\nend\n"


def stylua_check(tmp_path, source):
    assert STYLUA.exists(), "StyLua is missing: run `npm ci`, then try again"
    path = tmp_path / "sample.lua"
    path.write_text(source, encoding="utf-8")
    return run([str(STYLUA), "--config-path", str(ROOT / "stylua.toml"),
                "--check", str(path)])


@pytest.mark.gates
def test_stylua_fails_on_four_space_indents(tmp_path):
    assert stylua_check(tmp_path, FOUR_SPACES).returncode != 0


@pytest.mark.gates
def test_stylua_passes_two_space_indents(tmp_path):
    # StyLua's default indent is a tab. This passes only when StyLua reads
    # the repository's stylua.toml.
    result = stylua_check(tmp_path, TWO_SPACES)
    assert result.returncode == 0, result.stdout + result.stderr


def test_styluaignore_lists_every_luacheck_exclusion():
    luacheck = (ROOT / ".luacheckrc").read_text(encoding="utf-8")
    block = re.search(r"exclude_files = \{(.*?)\}", luacheck, re.S).group(1)
    excluded = {p[:-2] for p in re.findall(r'"([^"]+)"', block)}
    ignored = set((ROOT / ".styluaignore").read_text(encoding="utf-8").split())
    assert excluded == ignored
```

The last test has no marker, so it runs in `make fast`. It checks that
each `"x/**"` in `exclude_files` appears as `x/` in `.styluaignore`.

- [ ] **Step 2: Run them and see them fail**

Run: `python3 -m pytest -m gates tools/tests/test_gates.py`
Expected: FAIL, "StyLua is missing".

Run: `python3 -m pytest tools/tests/test_gates.py -k styluaignore`
Expected: FAIL, `.styluaignore` does not exist.

- [ ] **Step 3: Install the npm packages**

```bash
npm install --save-dev --save-exact factoriomod-debug@2.1.9 @johnnymorganz/stylua-bin@2.6.0
```

Check that `package.json` lists both with exact versions, and that
`node_modules/.bin/stylua --version` prints `stylua 2.6.0`.

- [ ] **Step 4: Write `stylua.toml`**

```toml
# Lua format for the mod. The column width matches max_line_length in
# .luacheckrc.
column_width = 100
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
```

- [ ] **Step 5: Exclude the API folder from luacheck**

In `.luacheckrc`, change the `exclude_files` block and its comment to:

```lua
-- .lua, .luarocks and .install hold the Lua that CI installs in the
-- workspace. docs/archive holds old chat logs. .factorio-api holds the
-- generated Factorio type library.
exclude_files = {
  "spec/fixtures/**", "node_modules/**", "build/**", "docs/archive/**",
  ".lua/**", ".luarocks/**", ".install/**", ".factorio-api/**",
}
```

- [ ] **Step 6: Write `.styluaignore`**

```text
spec/fixtures/
node_modules/
build/
docs/archive/
.lua/
.luarocks/
.install/
.factorio-api/
```

Do not add comments: the test in Step 1 reads every word as a folder.

- [ ] **Step 7: Run the tests**

Run: `python3 -m pytest -m gates tools/tests/test_gates.py`
Expected: PASS (2 tests).

Run: `python3 -m pytest tools/tests/test_gates.py -k styluaignore`
Expected: PASS.

- [ ] **Step 8: Add `make format` and the check in `make lua`**

Add near the top of the `Makefile`, after the `BUSTED` block:

```make
# StyLua comes from npm, so the maintainer and CI use the same version.
STYLUA := node_modules/.bin/stylua
```

Add after the `lua` target:

```make
## rewrites the Lua files in the repository's format
format:
	$(STYLUA) .
```

In the `lua` recipe, add `$(STYLUA) --check .` on the line after
`luacheck .`.

- [ ] **Step 9: Reformat and check**

Run: `make format`, then `git status --short`.
Expected: exactly these four files change: `spec/architecture_spec.lua`,
`spec/docs_spec.lua`, `spec/support/architecture.lua`,
`spec/support/locale.lua`. If another file changes, stop and learn the
reason before you continue.

Run: `make lua`
Expected: PASS.

- [ ] **Step 10: Commit**

Run `/ste80-humanizer` on the new comments and `/simplify` with one
reviewer.

```bash
git add package.json package-lock.json stylua.toml .styluaignore .luacheckrc Makefile tools/tests/test_gates.py spec/architecture_spec.lua spec/docs_spec.lua spec/support/architecture.lua spec/support/locale.lua
```

```bash
make stamp
```

```bash
git commit -m "build: check the Lua format with StyLua"
```

### Task 3: The API folder

**Files:**

- Create: `tools/tests/test_api_folder.py`
- Modify: `Makefile`
- Modify: `.gitignore`
- Modify: `tools/tests/test_workflows.py`

**Interfaces:**

- Consumes: `make gates` (Task 1).
- Produces: the file target `$(API)/stamp`, with `API := .factorio-api`.
  `make lua` and `make gates` depend on it. Its recipe takes the
  variables `FACTORIO`, `DOCS` and `FMTK`. The tests override `DOCS` and
  give a stub `node_modules/.bin/fmtk`.

- [ ] **Step 1: Write the failing tests**

Create `tools/tests/test_api_folder.py`:

```python
"""The Make target that builds .factorio-api/.

Each test copies the Makefile into a temporary folder with a stub fmtk
and local JSON files, so the tests need no network and no Node.
"""
import os
import pathlib
import shutil
import subprocess

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]
STUB_FMTK = """#!/bin/sh
# Stub for fmtk docs -d RUNTIME -p PROTOTYPE OUTDIR.
mkdir -p "$6/factorio/library"
cp "$3" "$6/factorio/library/runtime.lua"
"""

needs_make = pytest.mark.skipif(
    shutil.which("make") is None or shutil.which("curl") is None,
    reason="make and curl are needed")


def project(tmp_path, version="2.1.24", fmtk=True):
    work = tmp_path / "work"
    work.mkdir()
    shutil.copy(ROOT / "Makefile", work / "Makefile")
    (work / ".factorio-version").write_text(version + "\n", encoding="utf-8")
    (work / "package-lock.json").write_text("{}\n", encoding="utf-8")
    docs = tmp_path / "docs"
    docs.mkdir()
    (docs / "runtime-api.json").write_text('{"v": 1}\n', encoding="utf-8")
    (docs / "prototype-api.json").write_text('{"v": 1}\n', encoding="utf-8")
    if fmtk:
        stub = work / "node_modules/.bin/fmtk"
        stub.parent.mkdir(parents=True)
        stub.write_text(STUB_FMTK, encoding="utf-8")
        stub.chmod(0o755)
    return work, docs


def build(work, docs):
    return subprocess.run(
        ["make", "--no-print-directory", "DOCS=file://" + str(docs),
         ".factorio-api/stamp"],
        cwd=work, capture_output=True, text=True)


def stamp(work):
    return work / ".factorio-api/stamp"


@needs_make
def test_build_writes_the_library_and_the_stamp(tmp_path):
    work, docs = project(tmp_path)
    result = build(work, docs)
    assert result.returncode == 0, result.stdout + result.stderr
    assert (work / ".factorio-api/factorio/library/runtime.lua").exists()
    assert stamp(work).read_text(encoding="utf-8") == "factorio 2.1.24\n"


@needs_make
def test_missing_fmtk_says_to_run_npm_ci(tmp_path):
    work, docs = project(tmp_path, fmtk=False)
    result = build(work, docs)
    assert result.returncode != 0
    assert "run `npm ci`, then try again" in result.stdout + result.stderr
    assert not stamp(work).exists()


@needs_make
def test_failed_download_leaves_no_stamp(tmp_path):
    work, docs = project(tmp_path)
    assert build(work, docs).returncode == 0
    os.utime(work / ".factorio-version", (2**31, 2**31))
    (docs / "runtime-api.json").unlink()
    assert build(work, docs).returncode != 0
    assert not stamp(work).exists()


@needs_make
def test_new_version_rebuilds_and_drops_old_files(tmp_path):
    work, docs = project(tmp_path)
    assert build(work, docs).returncode == 0
    old = work / ".factorio-api/factorio/library/removed.lua"
    old.write_text("-- a class from the old version\n", encoding="utf-8")
    (work / ".factorio-version").write_text("2.1.25\n", encoding="utf-8")
    os.utime(work / ".factorio-version", (2**31, 2**31))
    result = build(work, docs)
    assert result.returncode == 0, result.stdout + result.stderr
    assert not old.exists()
    assert stamp(work).read_text(encoding="utf-8") == "factorio 2.1.25\n"


@needs_make
def test_current_stamp_needs_no_download(tmp_path):
    work, docs = project(tmp_path)
    assert build(work, docs).returncode == 0
    shutil.rmtree(docs)
    result = build(work, docs)
    assert result.returncode == 0, result.stdout + result.stderr
```

Add to `tools/tests/test_workflows.py`:

```python
def test_lua_and_gates_depend_on_the_api_folder():
    text = makefile()
    assert "\nlua: $(API)/stamp\n" in text
    assert "\ngates: $(API)/stamp\n" in text
```

- [ ] **Step 2: Run them and see them fail**

```bash
python3 -m pytest tools/tests/test_api_folder.py tools/tests/test_workflows.py
```

Expected: the five API folder tests FAIL with "No rule to make target",
and the workflow test fails.

- [ ] **Step 3: Add the target**

Add to the `Makefile`, after the `STYLUA` line:

```make
# The Factorio API for the pinned version, and the LuaLS type library
# that FMTK builds from it. Make rebuilds it when .factorio-version or
# package-lock.json (and so FMTK) changes. The spec is
# docs/superpowers/specs/2026-11-13-lua-tooling-design.md.
API      := .factorio-api
FACTORIO := $(shell cat .factorio-version)
DOCS     := https://lua-api.factorio.com/$(FACTORIO)
FMTK     := node_modules/.bin/fmtk

# The recipe deletes the old folder first, so no class from an old
# version stays. It writes the stamp last, so a run that stops part way
# starts again next time.
$(API)/stamp: .factorio-version package-lock.json
	@test -x $(FMTK) || \
	  { echo "fmtk is missing: run \`npm ci\`, then try again"; exit 1; }
	rm -rf $(API)
	mkdir -p $(API)
	curl -fsSL -o $(API)/runtime-api.json $(DOCS)/runtime-api.json
	curl -fsSL -o $(API)/prototype-api.json $(DOCS)/prototype-api.json
	$(FMTK) docs -d $(API)/runtime-api.json -p $(API)/prototype-api.json $(API)
	echo "factorio $(FACTORIO)" > $@
```

Change the first line of the `lua` target to `lua: $(API)/stamp`, and the
first line of `gates` to `gates: $(API)/stamp`.

- [ ] **Step 4: Ignore the folder**

Add to `.gitignore`:

```text
# The Factorio API and the LuaLS type library (make .factorio-api/stamp)
.factorio-api/
```

- [ ] **Step 5: Run the tests**

```bash
python3 -m pytest tools/tests/test_api_folder.py tools/tests/test_workflows.py
```

Expected: PASS.

- [ ] **Step 6: Build the real folder**

Run: `make .factorio-api/stamp`
Expected: two downloads, "Generated bundle with 1171 files", and
`.factorio-api/stamp` holds `factorio 2.1.24`.

Run: `make lua`
Expected: PASS. luacheck and StyLua skip `.factorio-api/`.

- [ ] **Step 7: Commit**

Run `/ste80-humanizer` on the comments and the module text, and run `/simplify`
with two reviewers (one new test module).

```bash
git add Makefile .gitignore tools/tests/test_api_folder.py tools/tests/test_workflows.py
```

```bash
make stamp
```

```bash
git commit -m "build: build the Factorio API folder from the pinned version"
```

### Task 4: The LuaLS type check

**Files:**

- Create: `.luarc.json`
- Modify: `Makefile`
- Modify: `tools/tests/test_gates.py`

**Interfaces:**

- Consumes: `.factorio-api/factorio/library/` and
  `.factorio-api/factorio/plugin.lua` (Task 3), the `gates` marker
  (Task 1), `run()` in `test_gates.py`.
- Produces: `make lua` runs
  `lua-language-server --check . --checklevel=Warning --logpath build/luals`.

- [ ] **Step 1: Write the failing tests**

Add to `tools/tests/test_gates.py` (add `import json` at the top):

```python
LIBRARY = ROOT / ".factorio-api/factorio"


def luals_check(tmp_path, source):
    luals = shutil.which("lua-language-server")
    assert luals, "lua-language-server is missing: see README.md"
    assert LIBRARY.exists(), "the API folder is missing: run make gates"
    work = tmp_path / "work"
    work.mkdir()
    config = json.loads((ROOT / ".luarc.json").read_text(encoding="utf-8"))
    config["runtime.plugin"] = str(LIBRARY / "plugin.lua")
    config["workspace.library"] = [str(LIBRARY / "library")]
    (work / ".luarc.json").write_text(json.dumps(config), encoding="utf-8")
    (work / "control.lua").write_text(source, encoding="utf-8")
    return run([luals, "--check", ".", "--checklevel=Warning",
                "--logpath", str(tmp_path / "log")], cwd=work)


@pytest.mark.gates
def test_luals_fails_on_an_unknown_event(tmp_path):
    result = luals_check(
        tmp_path, "script.on_event(defines.events.on_entity_dyed, function() end)\n")
    assert result.returncode == 1
    assert "undefined-field" in result.stdout + result.stderr


@pytest.mark.gates
def test_luals_passes_a_known_event(tmp_path):
    result = luals_check(
        tmp_path, "script.on_event(defines.events.on_entity_died, function() end)\n")
    assert result.returncode == 0, result.stdout + result.stderr
```

- [ ] **Step 2: Run them and see them fail**

Run: `python3 -m pytest -m gates tools/tests/test_gates.py -k luals`
Expected: FAIL, `.luarc.json` does not exist.

- [ ] **Step 3: Write `.luarc.json`**

Copy the JSON block from the spec section "The type check" exactly.

- [ ] **Step 4: Run the tests**

Run: `python3 -m pytest -m gates tools/tests/test_gates.py -k luals`
Expected: PASS (2 tests).

- [ ] **Step 5: Check that the settings still match FMTK**

```bash
python3 -c "import json; print(json.load(open('.factorio-api/factorio/config.json'))['settings'])"
```

Expected: each key and value there, without the `Lua.` prefix, is in
`.luarc.json`. If not, stop and report the difference.

- [ ] **Step 6: Add LuaLS to `make lua`**

In the `lua` recipe, add after the StyLua line:

```make
	lua-language-server --check . --checklevel=Warning --logpath build/luals
```

- [ ] **Step 7: Run the gates**

Run: `make lua`
Expected: PASS, with "no problems found". This is the baseline from the
spec.

Run: `make gates`
Expected: PASS (4 tests).

- [ ] **Step 8: Measure `make fast`**

```bash
s=$(date +%s.%N); make fast >/dev/null 2>&1; echo "$? $(echo "$(date +%s.%N) - $s" | bc)"
```

Run it twice, and record the second time. Expected: exit 0, under 10
seconds. If it takes 10 seconds or more, stop and report the time.

- [ ] **Step 9: Commit**

Run `/simplify` with one reviewer.

```bash
git add .luarc.json Makefile tools/tests/test_gates.py
```

```bash
make stamp
```

```bash
git commit -m "build: type-check the mod against the Factorio API with LuaLS"
```

### Task 5: CI

**Files:**

- Modify: `.github/workflows/check.yml`
- Modify: `tools/tests/test_workflows.py`

**Interfaces:**

- Consumes: `make lua` and `make gates` (Tasks 1 to 4).

- [ ] **Step 1: Write the failing test**

Add to `tools/tests/test_workflows.py`:

```python
def test_lua_job_installs_luals_and_runs_the_gate_tests():
    text = read("check.yml")
    lua_job = text[text.index("\n  lua:\n"):text.index("\n  tools:\n")]
    assert "lua-language-server-3.19.2-linux-x64.tar.gz" in lua_job
    assert "sha256sum -c" in lua_job
    assert "path: .factorio-api" in lua_job
    assert "touch .factorio-api/stamp" in lua_job
    assert "run: npm ci" in lua_job
    assert "make gates" in lua_job
```

- [ ] **Step 2: Run it and see it fail**

Run: `python3 -m pytest tools/tests/test_workflows.py -k luals`
Expected: FAIL.

- [ ] **Step 3: Change the `lua` job**

Replace the `lua` job in `.github/workflows/check.yml` with:

```yaml
  lua:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      # Factorio embeds Lua 5.2. A newer Lua could hide a bug.
      - uses: leafo/gh-actions-lua@v13
        with:
          luaVersion: "5.2"
      - uses: leafo/gh-actions-luarocks@v6
      - run: luarocks install busted && luarocks install luacheck && luarocks install luacov
      # FMTK builds the type library, and StyLua checks the format.
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
      # The checkout gives each file the current time, and the cache keeps
      # the stamp's old time. Without this step, Make rebuilds the folder.
      - name: Mark the restored API folder as current
        if: steps.api.outputs.cache-hit == 'true'
        run: touch .factorio-api/stamp
      - run: make lua
      - run: pip install pytest
      - run: make gates
```

- [ ] **Step 4: Run the tests**

Run: `python3 -m pytest tools/tests/test_workflows.py`
Expected: PASS.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the YAML comments and `/simplify` with one
reviewer.

```bash
git add .github/workflows/check.yml tools/tests/test_workflows.py
```

```bash
make stamp
```

```bash
git commit -m "ci: run LuaLS, StyLua and the gate tests in the lua job"
```

### Task 6: Docs

**Files:**

- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `docs/architecture.md`
- Modify: `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md`
- Modify: `cspell.json` if `make text` asks for words

- [ ] **Step 1: README**

In `README.md`, change the first pacman line to:

```bash
sudo pacman -S lua52 lua52-busted luacheck luarocks lychee lua-language-server
```

Replace the rows for `make lua`, `make tools` and `make check`, and add
rows for `make gates` and `make format`:

```markdown
| `make lua` | Builds the API folder if needed, then luacheck, StyLua, LuaLS, busted under Lua 5.2, the coverage floor | in `make fast`, CI job `lua` |
| `make tools` | pytest without the gate tests, `check_version.py` without a tag | in `make fast`, CI job `tools` |
| `make gates` | The gate tests that need LuaLS, StyLua and the API folder | in `make check`, CI job `lua` |
| `make format` | Rewrites the Lua files in the repository's format | before you stage Lua |
| `make check` | `make fast`, `make gates`, `make ingame` | before a PR |
```

After the table, add:

```markdown
`make lua` builds `.factorio-api/` the first time, and again after a
change to `.factorio-version` or `package-lock.json`. That needs the
network. The folder holds the Factorio API JSON for the pinned version
and the type library that FMTK builds from it.

For VS Code, the FMTK extension (Factorio Modding Tool Kit) gives a
debugger and a profiler for the running game. If it offers to write
`.luarc.json`, keep the committed file.

To move to a new FMTK version:

1. Change the version of `factoriomod-debug` in `package.json`.
2. Run `npm install`, then `make lua`.
3. Compare the `settings` object in
   `.factorio-api/factorio/config.json` with `.luarc.json`. Copy any
   change.

After a factorio-test upgrade, compare its globals in `.luacheckrc` with
`diagnostics.globals` in `.luarc.json` in the same way.
```

- [ ] **Step 2: CLAUDE.md**

Add to the Rules list in `CLAUDE.md`:

```markdown
- Before you use a Factorio API name, look it up in
  `.factorio-api/factorio/library/`. Give that path to the search: a
  search from the repository root skips the folder, because git ignores
  it.
- Run `make format` before you stage Lua files.
```

- [ ] **Step 3: docs/architecture.md**

Add before the section "Tests for these rules":

```markdown
## Type annotations

LuaLS checks the mod against the Factorio API, but only values whose type
it knows. Give the shell code types:

- A named event handler gets `---@param event EventData.<event name>`.
  An inline handler needs no annotation.
- A prototype table for `data:extend` gets `---@type <Prototype class>`,
  for example `---@type ItemPrototype`.

LuaLS does not check values from `storage`, `data.raw` lookups with keys
that the code builds, or values of type `any`. The busted tests and the
in-game tests check those.
```

- [ ] **Step 4: The CI spec**

In `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md`, add after
the Make targets table:

```markdown
The [Lua tooling spec](2026-11-13-lua-tooling-design.md) adds
`make gates`, `make format`, the API folder, StyLua and LuaLS to these
targets.
```

- [ ] **Step 5: Check the text**

Run: `make text`
Expected: PASS. If cspell flags a correct word, add it to `cspell.json`
in alphabetical order.

Run: `make lua`. `spec/docs_spec.lua` checks that
`docs/architecture.md` still names the same game API as the test.
Expected: PASS.

- [ ] **Step 6: Commit**

Run `/ste80-humanizer` on all changed prose.

```bash
git add README.md CLAUDE.md docs/architecture.md docs/superpowers/specs/2026-11-12-repo-and-ci-design.md cspell.json
```

```bash
make stamp
```

```bash
git commit -m "docs: document the Lua tooling and the annotation rules"
```

### Task 7: Acceptance and the PR

- [ ] **Step 1: A version change rebuilds the folder (criterion 3)**

Write `2.1.23` into `.factorio-version`, then run
`make .factorio-api/stamp`.
Expected: the recipe runs, and the stamp holds `factorio 2.1.23`. Then
restore the file with `git checkout .factorio-version`, and run
`make .factorio-api/stamp` again. Expected: the stamp holds
`factorio 2.1.24`. If FMTK 2.1.9 cannot read the 2.1.23 JSON, report it
and use any other 2.1 version that it reads.

- [ ] **Step 2: The full check (criterion 1)**

Run: `make check`
Expected: PASS. It runs the in-game tests, which take a few minutes.

- [ ] **Step 3: The whole-branch review**

Run `/simplify` with four reviewers on the whole branch
(`git diff origin/main...HEAD`). This change touches the hook gates and
CI, so CLAUDE.md asks for four. Fix and commit what they find, with the
same commit steps.

- [ ] **Step 4: Push and open the PR**

```bash
git push -u origin ci/lua-tooling
```

Open the PR with `gh pr create`. Title: `ci: add the LuaLS type check,
StyLua and the Factorio API folder`. The body follows
`.github/pull_request_template.md`, records the `make fast` time from
Task 4, and ends with the attribution line from the session.

- [ ] **Step 5: Auto-merge**

```bash
gh pr merge --auto --squash
```

Watch the run. If `all-checks` fails, read the log, fix the cause on the
branch, and push again.
