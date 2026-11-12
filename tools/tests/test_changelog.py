from tools import changelog

SAMPLE = """# Changelog

Intro text.

## [Unreleased]

### Added

- Larvae that explode.
- A long entry that
  goes on to a second line.

### Fixed

- A crash.

## [0.1.0] - 2026-11-12

### Added

- The empty mod.

[Unreleased]: https://example.com
"""


def releases():
    return changelog.parse(SAMPLE).releases


def test_parse_reads_releases_in_order():
    parsed = changelog.parse(SAMPLE)
    assert parsed.problems == ()
    assert [r.version for r in parsed.releases] == ["Unreleased", "0.1.0"]
    assert parsed.releases[1].date == "2026-11-12"
    assert parsed.releases[0].date is None


def test_parse_joins_continuation_lines():
    added = dict(releases()[0].groups)["Added"]
    assert added == ("Larvae that explode.",
                     "A long entry that goes on to a second line.")


def test_parse_reports_an_unknown_heading():
    parsed = changelog.parse("## [Unreleased]\n\n### Improved\n\n- x\n")
    assert any("Improved" in p for p in parsed.problems)


def test_parse_reports_a_bad_release_heading():
    parsed = changelog.parse("## 0.1.0\n")
    assert any("release heading" in p for p in parsed.problems)


def test_parse_never_raises_on_odd_input():
    for text in ["", "###", "### \n- x", "- x", "## [", "  continuation",
                 "## [Unreleased]\n  continuation\n"]:
        changelog.parse(text)


def test_render_maps_headings_to_factorio_categories():
    text = changelog.render(releases(), "0.2.0")
    assert "Version: 0.2.0\n  Features:\n    - Larvae that explode." in text
    assert "  Bugfixes:\n    - A crash." in text


def test_render_starts_every_block_with_99_dashes():
    lines = changelog.render(releases(), "0.2.0").splitlines()
    separators = [line for line in lines if set(line) == {"-"}]
    assert lines[0] == "-" * 99
    assert len(separators) == 2
    assert all(len(line) == 99 for line in separators)


def test_render_dates_released_versions_only():
    text = changelog.render(releases(), "0.2.0")
    assert "Version: 0.1.0\nDate: 2026-11-12\n" in text
    assert "Version: 0.2.0\n  Features" in text


def test_render_skips_an_empty_unreleased_section():
    parsed = changelog.parse(
        "## [Unreleased]\n\n## [0.1.0] - 2026-11-12\n\n### Added\n\n- x\n")
    assert changelog.render(parsed.releases, "0.1.0").count("Version:") == 1


def test_render_skips_unreleased_when_its_version_is_already_released():
    parsed = changelog.parse(
        "## [Unreleased]\n\n### Fixed\n\n- y\n\n"
        "## [0.1.0] - 2026-11-12\n\n### Added\n\n- x\n")
    text = changelog.render(parsed.releases, "0.1.0")
    assert text.count("Version: 0.1.0") == 1


def test_render_of_nothing_is_empty():
    assert changelog.render((), "0.1.0") == ""


def test_notes_give_the_markdown_of_one_version():
    assert changelog.notes(releases(), "0.1.0") == "### Added\n\n- The empty mod.\n"


def test_notes_of_a_missing_version_are_empty():
    assert changelog.notes(releases(), "9.9.9") == ""
