"""Each third-party gate fails on a planted mistake.

These tests run the real tools with this repository's settings. A test
skips when its tool is not installed, so CI's tools job skips most of
them. CI runs the gates themselves in the text and lua jobs.

The tests with the marker gates do not skip. make gates runs them after
it builds the API folder, and CI's lua job runs make gates.
"""
import json
import pathlib
import re
import shutil
import subprocess

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]
CSPELL = ROOT / "node_modules/.bin/cspell"
CONFIG = ROOT / "cspell.json"


def need(tool):
    return pytest.mark.skipif(shutil.which(tool) is None, reason=f"{tool} is not installed")


needs_cspell = pytest.mark.skipif(not CSPELL.exists(), reason="run npm ci first")


@needs_cspell
def test_cspell_flags_an_american_spelling():
    from tools import text_check
    found = text_check.spelling(CSPELL, CONFIG, {"bad.md": "The color is red.\n"})
    assert [(f.path, f.line, f.excerpt) for f in found] == [("bad.md", 1, "color")]


@needs_cspell
def test_cspell_accepts_the_british_spelling():
    from tools import text_check
    assert text_check.spelling(CSPELL, CONFIG, {"good.md": "The colour is red.\n"}) == []


def run(args, cwd=ROOT):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True)


@need("mdl")
def test_mdl_fails_on_a_heading_without_a_space(tmp_path):
    bad = tmp_path / "bad.md"
    bad.write_text("#Heading\n")
    result = run(["mdl", str(bad)])
    assert result.returncode != 0 and "MD018" in result.stdout


@need("luacheck")
def test_luacheck_fails_on_a_new_global(tmp_path):
    bad = tmp_path / "bad.lua"
    bad.write_text("larvae = 1\n")
    result = run(["luacheck", "--config", str(ROOT / ".luacheckrc"), str(bad)])
    assert result.returncode != 0


@need("lychee")
def test_lychee_fails_on_a_missing_local_file(tmp_path):
    bad = tmp_path / "bad.md"
    bad.write_text("[gone](missing.md)\n")
    result = run(["lychee", "--offline", "--no-progress", str(bad)])
    assert result.returncode != 0


@need("lychee")
def test_lychee_passes_a_good_local_link(tmp_path):
    (tmp_path / "there.md").write_text("# There\n")
    good = tmp_path / "good.md"
    good.write_text("[there](there.md)\n")
    assert run(["lychee", "--offline", "--no-progress", str(good)]).returncode == 0


def test_missing_cspell_says_what_to_do(tmp_path):
    from tools import text_check
    assert text_check.missing_tools(tmp_path) == [
        "cspell is missing: run `npm ci`, then try again"]
    assert text_check.missing_tools(ROOT) == [] or not CSPELL.exists()


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


def test_styluaignore_lists_every_luacheck_exclusion():
    luacheck = (ROOT / ".luacheckrc").read_text(encoding="utf-8")
    block = re.search(r"exclude_files = \{(.*?)\}", luacheck, re.S).group(1)
    excluded = {p[:-2] for p in re.findall(r'"([^"]+)"', block)}
    ignored = set((ROOT / ".styluaignore").read_text(encoding="utf-8").split())
    assert excluded == ignored
