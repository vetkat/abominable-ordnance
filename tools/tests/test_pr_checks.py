from tools import pr_checks as pr


def test_conventional_titles_pass():
    for title in ["feat: add larvae", "fix(core)!: stop a desync",
                  "ci: bump actions/checkout from 7 to 8", "docs: tidy the README"]:
        assert pr.title_problems(title) == [], title


def test_other_titles_fail():
    for title in ["Add larvae", "feature: add larvae", "feat:add larvae",
                  "feat: ", "FEAT: add larvae", ""]:
        assert pr.title_problems(title), title


def test_long_title_fails():
    assert pr.title_problems("feat: " + "x" * 70)


def test_mod_code_needs_a_changelog_entry():
    assert pr.changelog_problems(["core/a.lua"], [])
    assert pr.changelog_problems(["core/a.lua", "CHANGELOG.md"], []) == []


def test_the_label_skips_the_rule():
    assert pr.changelog_problems(["core/a.lua"], ["no-changelog"]) == []


def test_docs_and_tests_need_no_entry():
    assert pr.changelog_problems(["README.md", "tests/ingame/smoke_test.lua",
                                  "tools/package.py"], []) == []


GOOD_BODY = """## What changes

Stuff.

## Review angles

- Multiplayer safety: pass
- Save compatibility: fixed: migration added for the new storage field
- Mod compatibility: minor: an icon clashes with a large mod pack
- Performance (UPS): n/a
- Test quality: pass
- Security: N/A
"""


def test_a_filled_review_section_passes():
    assert pr.review_problems(GOOD_BODY, [], "vetkat") == []


def test_a_missing_review_section_fails():
    assert pr.review_problems("## What changes\n\nStuff.\n", [], "vetkat")
    assert pr.review_problems(None, [], "vetkat")


def test_a_blank_verdict_fails():
    body = GOOD_BODY.replace("Test quality: pass", "Test quality:")
    problems = pr.review_problems(body, [], "vetkat")
    assert len(problems) == 1 and "Test quality" in problems[0]


def test_a_missing_angle_fails():
    body = GOOD_BODY.replace("- Security: N/A\n", "")
    assert any("Security" in p for p in pr.review_problems(body, [], "vetkat"))


def test_an_open_finding_fails():
    body = GOOD_BODY.replace("Mod compatibility: minor: an icon clashes with a large mod pack",
                             "Mod compatibility: Important: another mod's force breaks the peace")
    problems = pr.review_problems(body, [], "vetkat")
    assert len(problems) == 1 and "Mod compatibility" in problems[0]


def test_the_section_ends_at_the_next_heading():
    body = GOOD_BODY.replace("- Security: N/A\n", "") + "\n## Notes\n\n- Security: pass\n"
    assert any("Security" in p for p in pr.review_problems(body, [], "vetkat"))


def test_the_label_and_dependabot_skip_the_rule():
    assert pr.review_problems("", ["no-review"], "vetkat") == []
    assert pr.review_problems("", [], "dependabot[bot]") == []
