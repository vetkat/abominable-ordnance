import json
import zipfile

from tools import package


def test_shipped_files():
    for path in ["info.json", "LICENSE", "core/a.lua", "locale/en/locale.cfg",
                 "tests/ingame/smoke_test.lua", "data.lua", "control.lua"]:
        assert package.is_shipped(path), path
    for path in ["README.md", "tools/package.py", "spec/a_spec.lua",
                 "core/.gitkeep", "CHANGELOG.md", "tools/vendor/factorio-test_3.2.0.zip"]:
        assert not package.is_shipped(path), path


def test_mod_code_is_shipped_code_without_tests_and_licence():
    assert package.is_mod_code("core/a.lua")
    assert package.is_mod_code("info.json")
    assert not package.is_mod_code("LICENSE")
    assert not package.is_mod_code("tests/ingame/smoke_test.lua")
    assert not package.is_mod_code("README.md")


def test_missing_required():
    assert package.missing_required(["info.json", "LICENSE", "data.lua",
                                     "control.lua", "locale/en/locale.cfg"]) == []
    assert package.missing_required(["info.json"]) == [
        "LICENSE", "data.lua", "control.lua", "locale/"]


def test_plan_adds_the_changelog_and_the_folder_prefix():
    entries = package.plan("m_0.1.0", ["info.json", "README.md"], "text\n")
    assert [e.name for e in entries] == ["m_0.1.0/changelog.txt", "m_0.1.0/info.json"]
    assert entries[0].text == "text\n" and entries[0].source is None


def test_plan_without_changelog_text():
    assert [e.name for e in package.plan("m_0.1.0", ["info.json"], "")] == ["m_0.1.0/info.json"]


def make_tree(root, files):
    for path in files:
        (root / path).parent.mkdir(parents=True, exist_ok=True)
        (root / path).write_text("x\n")
    (root / "info.json").write_text(json.dumps({"name": "m", "version": "0.1.0"}))
    (root / "CHANGELOG.md").write_text("## [Unreleased]\n\n### Added\n\n- x\n")


def test_build_writes_a_zip_with_changelog_txt(tmp_path):
    files = ["info.json", "LICENSE", "data.lua", "control.lua",
             "locale/en/locale.cfg", "README.md", "CHANGELOG.md"]
    make_tree(tmp_path, files)
    out, problems = package.build(tmp_path, files, tmp_path / "build")
    assert problems == []
    names = zipfile.ZipFile(out).namelist()
    assert "m_0.1.0/changelog.txt" in names
    assert "m_0.1.0/README.md" not in names
    text = zipfile.ZipFile(out).read("m_0.1.0/changelog.txt").decode()
    assert text.startswith("-" * 99 + "\nVersion: 0.1.0\n")


def test_build_refuses_a_tree_without_required_files(tmp_path):
    make_tree(tmp_path, ["info.json"])
    out, problems = package.build(tmp_path, ["info.json", "CHANGELOG.md"], tmp_path / "build")
    assert out is None
    assert "missing from the repository: LICENSE" in problems
