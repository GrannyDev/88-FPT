#!/usr/bin/env python3
"""Extract RSCM coefficient sets from MiniZinc output files.

Each input file is rewritten as plain text with one integer set per line:

    [-4, -3, 0, 1, 2, 3, 4, 5]
"""

from __future__ import annotations

import argparse
import ast
import re
from pathlib import Path


COEFFS_RE = re.compile(r"^\s*(?:coeffs\s*=\s*)?(\[[^\]]*\])\s*$")


def parse_coeff_sets(path: Path) -> list[list[int]]:
    sets: list[list[int]] = []

    for line_number, line in enumerate(path.read_text().splitlines(), start=1):
        match = COEFFS_RE.match(line)
        if not match:
            continue

        try:
            values = ast.literal_eval(match.group(1))
        except (SyntaxError, ValueError) as exc:
            raise ValueError(f"{path}:{line_number}: invalid set syntax") from exc

        if not isinstance(values, list) or not all(isinstance(value, int) for value in values):
            raise ValueError(f"{path}:{line_number}: expected a list of integers")
        if len(values) != len(set(values)):
            raise ValueError(f"{path}:{line_number}: duplicate values in set")

        sets.append(values)

    if not sets:
        raise ValueError(f"{path}: no coefficient sets found")

    return sets


def format_set(values: list[int]) -> str:
    return "[" + ", ".join(str(value) for value in values) + "]"


def rewrite_file(path: Path) -> int:
    sets = parse_coeff_sets(path)
    path.write_text("\n".join(format_set(values) for values in sets) + "\n")
    return len(sets)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=sorted(Path(__file__).parent.glob("RSCM*.txt")),
        help="RSCM text files to rewrite. Defaults to sets/RSCM*.txt.",
    )
    args = parser.parse_args()

    for path in args.paths:
        count = rewrite_file(path)
        print(f"{path}: wrote {count} sets")


if __name__ == "__main__":
    main()
