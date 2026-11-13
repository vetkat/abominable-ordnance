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

pytestmark = pytest.mark.skipif(
    shutil.which("make") is None or shutil.which("curl") is None,
    reason="make and curl are needed")


def project(tmp_path, version="2.1.24\n", fmtk=True):
    work = tmp_path / "work"
    work.mkdir()
    shutil.copy(ROOT / "Makefile", work / "Makefile")
    (work / ".factorio-version").write_text(version, encoding="utf-8")
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


def built(work, docs):
    result = build(work, docs)
    assert result.returncode == 0, result.stdout + result.stderr


def make_stale(work):
    # A .factorio-version newer than the stamp makes Make rebuild.
    os.utime(work / ".factorio-version", (2**31, 2**31))


def stamp(work):
    return work / ".factorio-api/stamp"


def test_build_writes_the_library_and_the_stamp(tmp_path):
    work, docs = project(tmp_path)
    built(work, docs)
    assert (work / ".factorio-api/factorio/library/runtime.lua").exists()
    assert stamp(work).read_text(encoding="utf-8") == "factorio 2.1.24\n"


def test_version_file_with_spaces_and_crlf(tmp_path):
    # tools/ingame.sh strips all white space from .factorio-version too.
    work, docs = project(tmp_path, version=" 2.1.24 \r\n")
    built(work, docs)
    assert stamp(work).read_text(encoding="utf-8") == "factorio 2.1.24\n"


def test_missing_fmtk_says_to_run_npm_ci(tmp_path):
    work, docs = project(tmp_path, fmtk=False)
    result = build(work, docs)
    assert result.returncode != 0
    assert "run `npm ci`, then try again" in result.stdout + result.stderr
    assert not stamp(work).exists()


def test_failed_download_leaves_no_stamp(tmp_path):
    work, docs = project(tmp_path)
    built(work, docs)
    make_stale(work)
    (docs / "runtime-api.json").unlink()
    assert build(work, docs).returncode != 0
    assert not stamp(work).exists()


def test_new_version_rebuilds_and_drops_old_files(tmp_path):
    work, docs = project(tmp_path)
    built(work, docs)
    old = work / ".factorio-api/factorio/library/removed.lua"
    old.write_text("-- a class from the old version\n", encoding="utf-8")
    (work / ".factorio-version").write_text("2.1.25\n", encoding="utf-8")
    make_stale(work)
    built(work, docs)
    assert not old.exists()
    assert stamp(work).read_text(encoding="utf-8") == "factorio 2.1.25\n"


def test_current_stamp_needs_no_download(tmp_path):
    work, docs = project(tmp_path)
    built(work, docs)
    shutil.rmtree(docs)
    built(work, docs)
