import json

from tools import check_version as cv

INFO = {
    "name": "abominable-ordnance", "version": "0.1.0",
    "title": "Abominable Ordnance", "author": "vetkat",
    "factorio_version": "2.1", "description": "d",
    "dependencies": ["base >= 2.1", "? space-age"],
}
UNRELEASED = "## [Unreleased]\n\n### Added\n\n- The empty mod.\n"
RELEASED = ("## [Unreleased]\n\n## [0.1.0] - 2026-11-12\n\n"
            "### Added\n\n- The empty mod.\n")


def info(**changes):
    return json.dumps({**INFO, **changes})


def test_unreleased_passes_without_a_tag():
    assert cv.problems(info(), UNRELEASED, None) == []


def test_released_version_passes_with_and_without_its_tag():
    assert cv.problems(info(), RELEASED, None) == []
    assert cv.problems(info(), RELEASED, "v0.1.0") == []


def test_newest_section_must_match_without_a_tag():
    text = "## [0.2.0] - 2026-11-12\n\n### Added\n\n- x\n"
    assert "0.2.0" in cv.problems(info(), text, None)[0]


def test_a_tag_needs_a_dated_section():
    assert cv.problems(info(), UNRELEASED, "v0.1.0")
    undated = "## [0.1.0]\n\n### Added\n\n- x\n"
    assert any("no date" in p for p in cv.problems(info(), undated, "v0.1.0"))


def test_a_tag_must_name_the_info_json_version():
    assert any("v0.2.0" in p for p in cv.problems(info(), RELEASED, "v0.2.0"))


def test_a_tag_fails_while_unreleased_has_entries():
    text = "## [Unreleased]\n\n### Fixed\n\n- y\n\n" + RELEASED.split("\n\n", 1)[1]
    assert any("Unreleased" in p for p in cv.problems(info(), text, "v0.1.0"))


def test_factorio_version_must_be_2_1():
    assert any("2.1" in p for p in cv.problems(info(factorio_version="2.0"), UNRELEASED, None))


def test_dependencies_must_include_base_and_optional_space_age():
    found = cv.problems(info(dependencies=["base >= 2.1"]), UNRELEASED, None)
    assert any("space-age" in p for p in found)


def test_version_must_be_semver():
    assert any("X.Y.Z" in p for p in cv.problems(info(version="0.1"), UNRELEASED, None))


def test_missing_key_is_a_problem():
    data = dict(INFO)
    del data["title"]
    assert any("title" in p for p in cv.problems(json.dumps(data), UNRELEASED, None))


def test_broken_json_is_a_problem_not_an_exception():
    assert "not valid JSON" in cv.problems("{", UNRELEASED, None)[0]
    assert "not a JSON object" in cv.problems("[]", UNRELEASED, None)[0]


def test_empty_changelog_is_a_problem():
    assert cv.problems(info(), "", None) == ["CHANGELOG.md has no release sections"]
