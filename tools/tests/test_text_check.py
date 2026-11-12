from tools import text_check as tc


def rules(found):
    return [f.rule for f in found]


def test_style_findings_come_from_the_vendored_checker():
    found = tc.check_files({"docs/x.md": "We utilize this tool.\n"})
    assert "word" in rules(found)
    assert all(f.path == "docs/x.md" and f.line == 1 for f in found)


def test_code_in_markdown_is_not_checked():
    text = "```\nwe utilize – code\n```\n\nUse `utilize` here.\n"
    assert tc.check_files({"docs/x.md": text}) == []


def test_en_dash_in_prose_fails():
    found = tc.check_files({"docs/x.md": "Read pages 1–3 first.\n"})
    assert "en-dash" in rules(found)


def test_lua_comments_are_checked_and_code_is_not():
    assert tc.check_files({"core/x.lua": "local utilize = 1\n"}) == []
    found = tc.check_files({"core/x.lua": "local x = 1\n-- we utilize this\n"})
    assert [f.line for f in found if f.rule == "word"] == [2]


def test_other_files_are_skipped():
    assert tc.kind("tools/x.py") is None
    assert tc.kind("tools/vendor/notes.md") is None
    assert tc.kind("locale/en/locale.cfg") == "locale"
    assert tc.check_files({"tools/x.py": "# we utilize this\n"}) == []


def test_parse_allow_reads_entries_and_comments():
    allows, problems = tc.parse_allow(
        "# a comment\n\nspelling | docs/reviews/*.md | color | quotes the old spec\n")
    assert problems == []
    assert allows == [tc.Allow("spelling", "docs/reviews/*.md", "color", "quotes the old spec")]


def test_parse_allow_rejects_bad_entries():
    for line in ["spelling | a.md | color", "* | a.md | | reason",
                 "spelling | | | reason", "spelling | a.md | |"]:
        allows, problems = tc.parse_allow(line + "\n")
        assert allows == [] and len(problems) == 1, line


def test_allowed_matches_rule_path_and_word():
    allows, _ = tc.parse_allow("spelling | docs/reviews/*.md | color | quotes\n")
    finding = tc.Finding("docs/reviews/a.md", 3, "spelling", "", "color")
    assert tc.allowed(finding, allows)
    assert not tc.allowed(finding._replace(excerpt="behavior"), allows)
    assert not tc.allowed(finding._replace(path="README.md"), allows)
    assert not tc.allowed(finding._replace(rule="word"), allows)


def test_an_entry_without_a_word_covers_the_rule_in_that_file():
    allows, _ = tc.parse_allow("passive | docs/design.md | | the design's voice\n")
    assert tc.allowed(tc.Finding("docs/design.md", 9, "passive", "", "is made"), allows)


def test_spelling_findings_parse_cspell_output():
    out = ("docs/x.md.txt:4:5 - Unknown word (color)\n"
           "./core/y.lua.txt:2:1 - Unknown word (behavior)\n"
           "CSpell: Files checked: 2\n")
    assert tc.spelling_findings(out) == [
        tc.Finding("docs/x.md", 4, "spelling", "not in the en-GB dictionary", "color"),
        tc.Finding("core/y.lua", 2, "spelling", "not in the en-GB dictionary", "behavior"),
    ]
