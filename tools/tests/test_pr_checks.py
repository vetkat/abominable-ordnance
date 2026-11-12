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
