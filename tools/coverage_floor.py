"""Fail when the busted tests cover less than 90% of the lines in core/.

luacov writes a report with a Summary table. This reads the rows for
core/ and adds up their lines. An empty core/ passes.

    python3 -m tools.coverage_floor build/luacov.report.out
"""
from __future__ import annotations

import pathlib
import re
import sys

FLOOR = 90.0
ROW = re.compile(r"^(?P<file>\S+)\s+(?P<hits>\d+)\s+(?P<missed>\d+)\s+[\d.]+%\s*$")


def problems(report: str, floor: float) -> list[str]:
    if "\nSummary\n" not in report:
        return ["the luacov report has no Summary section; did busted run with --coverage?"]
    summary = report.split("\nSummary\n", 1)[1]
    hits = missed = 0
    for line in summary.splitlines():
        match = ROW.match(line)
        if match and match["file"].removeprefix("./").startswith("core/"):
            hits += int(match["hits"])
            missed += int(match["missed"])
    if hits + missed == 0:
        return []
    percent = 100.0 * hits / (hits + missed)
    if percent >= floor:
        return []
    return [f"core/ coverage is {percent:.1f}%, under the floor of {floor:.0f}%"]


def main(argv: list[str]) -> int:
    path = pathlib.Path(argv[1])
    if not path.is_file():
        print(f"coverage: {path} does not exist; did busted run with --coverage?",
              file=sys.stderr)
        return 1
    found = problems(path.read_text(encoding="utf-8"), FLOOR)
    for problem in found:
        print(f"coverage: {problem}", file=sys.stderr)
    return 1 if found else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
