from tools import coverage_floor as cf

HEAD = ("=" * 30 + "\nSummary\n" + "=" * 30 + "\n\n"
        "File        Hits Missed Coverage\n" + "-" * 30 + "\n")
TAIL = "-" * 30 + "\nTotal 9 11 45.00%\n"


def report(*rows):
    return HEAD + "".join(row + "\n" for row in rows) + TAIL


def test_core_at_the_floor_passes():
    assert cf.problems(report("core/a.lua 9 1 90.00%", "spec/x.lua 0 10 0.00%"), 90.0) == []


def test_core_below_the_floor_fails():
    found = cf.problems(report("core/a.lua 8 2 80.00%"), 90.0)
    assert found and "80.0%" in found[0]


def test_lines_add_up_across_core_files():
    found = cf.problems(report("core/a.lua 10 0 100.00%", "./core/b.lua 5 5 50.00%"), 90.0)
    assert found and "75.0%" in found[0]


def test_an_empty_core_passes():
    assert cf.problems(report("spec/x.lua 0 10 0.00%"), 90.0) == []


def test_a_report_without_a_summary_is_a_problem():
    assert cf.problems("garbage", 90.0) == [
        "the luacov report has no Summary section; did busted run with --coverage?"]
