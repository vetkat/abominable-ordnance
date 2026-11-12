"""Each third-party gate fails on a planted mistake.

These tests run the real tools with this repository's settings. A test
skips when its tool is not installed, so CI's tools job skips most of
them. CI runs the gates themselves in the text and lua jobs.
"""
import pathlib
import shutil
import subprocess

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]


def need(tool):
    return pytest.mark.skipif(shutil.which(tool) is None, reason=f"{tool} is not installed")


needs_cspell = pytest.mark.skipif(
    not (ROOT / "node_modules/.bin/cspell").exists(), reason="run npm ci first")


@needs_cspell
def test_cspell_flags_an_american_spelling():
    from tools import text_check
    found = text_check.spelling(ROOT, {"bad.md": "The color is red.\n"})
    assert [(f.path, f.line, f.excerpt) for f in found] == [("bad.md", 1, "color")]


@needs_cspell
def test_cspell_accepts_the_british_spelling():
    from tools import text_check
    assert text_check.spelling(ROOT, {"good.md": "The colour is red.\n"}) == []
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
