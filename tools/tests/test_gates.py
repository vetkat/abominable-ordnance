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
