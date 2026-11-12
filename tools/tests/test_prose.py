from tools import prose


def lines(text):
    return text.split("\n")


def test_markdown_keeps_the_line_count():
    text = "a\n```\ncode\n```\nb\n"
    assert len(lines(prose.markdown_prose(text))) == len(lines(text))


def test_markdown_drops_code_blocks_and_spans():
    out = prose.markdown_prose("The `color` key.\n```lua\nlocal color = 1\n```\n")
    assert "color" not in out
    assert "The" in out and "key." in out


def test_markdown_drops_tilde_fences():
    assert "color" not in prose.markdown_prose("~~~\ncolor\n~~~\n")


def test_markdown_drops_link_targets_and_urls():
    out = prose.markdown_prose(
        "See [the docs](https://example.com/colour) and <https://x.org>.\n")
    assert "example" not in out and "x.org" not in out
    assert "the docs" in out


def test_lua_keeps_comments_only():
    out = prose.lua_prose('local color = 1 -- the colour of the larva\n'
                          'print("-- not a comment")\n')
    assert lines(out) == ["the colour of the larva", "", ""]


def test_lua_block_comments_span_lines():
    out = prose.lua_prose("--[[ first line\nsecond line ]] local x = 1\n")
    assert lines(out)[:2] == ["first line", "second line"]


def test_lua_long_strings_are_not_prose():
    out = prose.lua_prose("local s = [[ -- not a comment\nstill a string ]]\n")
    assert out.strip() == ""


def test_lua_doc_comment_dashes_are_dropped():
    assert prose.lua_prose("--- A doc comment.\n") == "A doc comment.\n"


def test_locale_keeps_values_only():
    text = "[mod-name]\nabominable-ordnance=Abominable Ordnance\n; a comment\n"
    assert lines(prose.locale_prose(text)) == ["", "Abominable Ordnance", "", ""]


def test_locale_drops_placeholders_and_rich_text():
    out = prose.locale_prose("[x]\nk=Fires __1__ [item=iron-plate] larvae\n")
    assert "__1__" not in out and "iron-plate" not in out and "larvae" in out
