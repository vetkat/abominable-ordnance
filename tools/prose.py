"""Pull the prose out of Markdown, Lua and locale files.

Each function returns text with the same number of lines as its input.
A line without prose becomes an empty line, so a finding in the output
has the line number of the source.
"""
from __future__ import annotations

import re

FENCE = re.compile(r"^\s*(`{3,}|~{3,})")
CODE_SPAN = re.compile(r"`[^`]*`")
LINK_TARGET = re.compile(r"\]\([^)]*\)")
URL = re.compile(r"<https?://[^>]*>|https?://\S+")
LONG_BRACKET = re.compile(r"\[(=*)\[")
PLACEHOLDER = re.compile(r"__\w+__|\[[^\]]*\]")
LINK_DEFINITION = re.compile(r"^ {0,3}\[[^\]]+\]:\s*\S")


def without_link_definitions(text: str) -> str:
    """Blank out Markdown link definitions ([label]: target), line by line."""
    return "\n".join("" if LINK_DEFINITION.match(line) else line
                     for line in text.split("\n"))


def markdown_prose(text: str) -> str:
    out = []
    fence = None
    for line in without_link_definitions(text).split("\n"):
        match = FENCE.match(line)
        if fence:
            if match and match.group(1).startswith(fence):
                fence = None
            out.append("")
        elif match:
            fence = match.group(1)[0] * 3
            out.append("")
        else:
            line = CODE_SPAN.sub(lambda m: " " * len(m.group()), line)
            line = LINK_TARGET.sub("]", line)
            out.append(URL.sub(" ", line))
    return "\n".join(out)


def _lua_line(line: str, block: tuple[str, bool] | None) -> tuple[str, tuple[str, bool] | None]:
    """One line of Lua: its comment text, and the open block after it.

    block is (closing bracket, is a comment) for a block comment or a long
    string that is still open.
    """
    parts = []
    i = 0
    while i < len(line):
        if block:
            close, is_comment = block
            j = line.find(close, i)
            if is_comment:
                parts.append(line[i:] if j < 0 else line[i:j])
            if j < 0:
                break
            i = j + len(close)
            block = None
            continue
        if line.startswith("--", i):
            match = LONG_BRACKET.match(line, i + 2)
            if match:
                block = ("]" + match.group(1) + "]", True)
                i = match.end()
                continue
            if not line.startswith("---@", i):  # a type annotation is code
                parts.append(line[i + 2:].lstrip("-"))
            break
        if line[i] in "\"'":
            quote = line[i]
            j = i + 1
            while j < len(line) and line[j] != quote:
                j += 2 if line[j] == "\\" else 1
            i = j + 1
            continue
        match = LONG_BRACKET.match(line, i)
        if match:
            block = ("]" + match.group(1) + "]", False)
            i = match.end()
            continue
        i += 1
    # A code span in a comment names code, such as an API field.
    text = CODE_SPAN.sub(" ", " ".join(parts))
    return " ".join(text.split()), block


def lua_prose(text: str) -> str:
    out = []
    block = None
    for line in text.split("\n"):
        prose_line, block = _lua_line(line, block)
        out.append(prose_line)
    return "\n".join(out)


def locale_prose(text: str) -> str:
    out = []
    for line in text.split("\n"):
        stripped = line.strip()
        if not stripped or stripped[0] in "[;#" or "=" not in line:
            out.append("")
        else:
            out.append(PLACEHOLDER.sub(" ", line.split("=", 1)[1]).strip())
    return "\n".join(out)
