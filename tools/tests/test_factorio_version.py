from tools import factorio_version as fv


def latest(headless):
    return {"stable": {"headless": headless, "alpha": "x"}, "experimental": {}}


def test_same_version_passes():
    assert fv.problems(latest("2.1.24"), "2.1.24") == []


def test_older_stable_passes():
    assert fv.problems(latest("2.1.9"), "2.1.24") == []


def test_newer_stable_fails():
    found = fv.problems(latest("2.1.25"), "2.1.24")
    assert found and "2.1.25" in found[0] and "2.1.24" in found[0]


def test_numeric_order_not_text_order():
    assert fv.problems(latest("2.1.100"), "2.1.24")


def test_a_changed_format_is_a_problem():
    for data in [{}, [], {"stable": {}}, latest(7), latest("2.1")]:
        assert "format" in fv.problems(data, "2.1.24")[0], data


def test_a_bad_pin_is_a_problem():
    assert "X.Y.Z" in fv.problems(latest("2.1.24"), "2.1")[0]
