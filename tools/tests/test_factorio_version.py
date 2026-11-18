import pytest

from tools import factorio_version as fv


def latest(headless):
    return {"stable": {"headless": headless, "alpha": "x"}, "experimental": {}}


def test_check_returns_the_newer_version():
    assert fv.check(latest("2.1.25"), "2.1.24") == ("2.1.25", [])


def test_check_returns_nothing_when_the_pin_is_current():
    assert fv.check(latest("2.1.24"), "2.1.24") == (None, [])
    assert fv.check(latest("2.1.9"), "2.1.24") == (None, [])


def test_numeric_order_not_text_order():
    assert fv.check(latest("2.1.100"), "2.1.24") == ("2.1.100", [])


@pytest.mark.parametrize("data", [
    {}, [], {"stable": {}}, latest(7), latest("2.1"),
    latest("2.1.25; rm -rf /"), latest("2.1.25\n"), latest("2.1.25\nfoo=bar"),
    latest("٢.1.25"), latest(" 2.1.25"),
])
def test_a_changed_format_gives_no_version(data):
    newer, found = fv.check(data, "2.1.24")
    assert newer is None and "format" in found[0]


def test_a_bad_pin_is_a_problem():
    assert "X.Y.Z" in fv.check(latest("2.1.24"), "2.1")[1][0]


def run(tmp_path, data, pin="2.1.24", env=None, fetch=None):
    (tmp_path / ".factorio-version").write_text(pin + "\n", encoding="utf-8")
    out = tmp_path / "github_output"
    out.write_text("", encoding="utf-8")
    code = fv.main(root=tmp_path, fetch=fetch or (lambda: data),
                   env={"GITHUB_OUTPUT": str(out)} if env is None else env)
    pin_now = (tmp_path / ".factorio-version").read_text(encoding="utf-8")
    return code, pin_now, out.read_text(encoding="utf-8")


def test_moves_the_pin_and_names_the_version(tmp_path):
    assert run(tmp_path, latest("2.1.25")) == (0, "2.1.25\n", "version=2.1.25\n")


def test_reads_a_pin_with_spaces_around_it(tmp_path):
    assert run(tmp_path, latest("2.1.25"), pin=" 2.1.24 \r") == (0, "2.1.25\n", "version=2.1.25\n")


def test_moves_the_pin_without_github_output(tmp_path):
    assert run(tmp_path, latest("2.1.25"), env={}) == (0, "2.1.25\n", "")


def test_changes_nothing_when_the_pin_is_current(tmp_path):
    assert run(tmp_path, latest("2.1.24")) == (0, "2.1.24\n", "")


def test_a_bad_version_never_reaches_the_pin_or_the_output(tmp_path):
    assert run(tmp_path, latest("2.1.25\nfoo=bar")) == (1, "2.1.24\n", "")


def test_fails_and_changes_nothing_for_a_bad_pin(tmp_path):
    assert run(tmp_path, latest("2.1.25"), pin="2.1") == (1, "2.1\n", "")


def test_fails_and_changes_nothing_when_the_api_cannot_be_read(tmp_path):
    def broken():
        raise OSError("offline")
    assert run(tmp_path, None, fetch=broken) == (1, "2.1.24\n", "")
