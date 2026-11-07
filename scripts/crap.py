#!/usr/bin/env python3
"""CRAP gate for Genki (AGENTS.md -> Quality gates, D-004, D-027).

CRAP(f) = CC(f)^2 * (1 - coverage(f))^3 + CC(f)

CC comes from `lizard` (cyclomatic complexity per function). Coverage comes
from `xcrun xccov view --report --json`. A function fails at CRAP >= 10.

Scope: every function lizard finds under Genki/, except functions declared
inside a type that conforms to `View`. Layout code has no unit tests, so its
CRAP isn't meaningful (D-027). Known limit: lizard doesn't report computed
properties, so their getters aren't scored.

Usage: crap.py --coverage coverage.json --complexity lizard.csv [--top 10]
Exit code: 0 when every in-scope function is under the threshold, 1 otherwise.
"""

import argparse
import csv
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

THRESHOLD = 10.0
VIEW_TYPE = re.compile(r"^\s*(?:private\s+|fileprivate\s+)?struct\s+\w+\s*:\s*[^{]*\bView\b[^{]*\{")
NOT_A_FUNCTION = ("closure #", "implicit closure #", "variable initialization expression")


@dataclass
class Score:
    file: str
    line: int
    name: str
    complexity: int
    coverage: float | None

    @property
    def crap(self) -> float:
        uncovered = 1.0 - (self.coverage or 0.0)
        return self.complexity ** 2 * uncovered ** 3 + self.complexity


def view_line_ranges(source: Path) -> list[range]:
    """Line ranges (1-based) of `struct X: View { ... }` bodies, by brace counting."""
    lines = source.read_text(encoding="utf-8").splitlines()
    ranges = []
    for start, line in enumerate(lines, start=1):
        if not VIEW_TYPE.match(line):
            continue
        depth = 0
        for end in range(start, len(lines) + 1):
            depth += lines[end - 1].count("{") - lines[end - 1].count("}")
            if depth == 0:
                ranges.append(range(start, end + 1))
                break
    return ranges


def load_coverage(path: Path) -> dict[str, list[dict]]:
    """Functions per source file of the app target, keyed by file name."""
    report = json.loads(path.read_text(encoding="utf-8"))
    app = next(t for t in report["targets"] if t["name"].startswith("Genki.app"))
    return {Path(f["path"]).name: f["functions"] for f in app["files"]}


def coverage_for(functions: list[dict], start: int, end: int) -> float | None:
    """Coverage of the first real function (not a closure) declared inside [start, end]."""
    for function in sorted(functions, key=lambda f: f["lineNumber"]):
        if start <= function["lineNumber"] <= end and not function["name"].startswith(NOT_A_FUNCTION):
            return function["lineCoverage"]
    return None


def scores(complexity_csv: Path, coverage: dict[str, list[dict]], root: Path) -> list[Score]:
    results = []
    view_ranges: dict[str, list[range]] = {}
    with complexity_csv.open(encoding="utf-8", newline="") as handle:
        # lizard --csv columns: NLOC, CCN, tokens, params, length, location,
        # file, name, long name, start, end.
        for row in csv.reader(handle):
            ccn, file, name, start, end = int(row[1]), row[6], row[7], int(row[9]), int(row[10])
            if file not in view_ranges:
                view_ranges[file] = view_line_ranges(root / file)
            if any(start in r for r in view_ranges[file]):
                continue
            cov = coverage_for(coverage.get(Path(file).name, []), start, end)
            results.append(Score(file, start, name, ccn, cov))
    return sorted(results, key=lambda s: s.crap, reverse=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--coverage", type=Path, required=True)
    parser.add_argument("--complexity", type=Path, required=True)
    parser.add_argument("--top", type=int, default=10)
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    results = scores(args.complexity, load_coverage(args.coverage), root)
    failing = [s for s in results if s.crap >= THRESHOLD]

    print(f"CRAP gate: {len(results)} functions in scope, threshold {THRESHOLD:g}")
    print(f"{'CRAP':>6}  {'CC':>3}  {'cover':>6}  function")
    for s in results[: args.top]:
        cover = "n/a" if s.coverage is None else f"{s.coverage:.0%}"
        print(f"{s.crap:6.1f}  {s.complexity:3d}  {cover:>6}  {s.name}  ({s.file}:{s.line})")

    if failing:
        print(f"\nFAILED: {len(failing)} function(s) at CRAP >= {THRESHOLD:g}. Split them, test them, or both.")
        return 1
    print("\nPASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
