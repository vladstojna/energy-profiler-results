#!/usr/bin/env python3

import sys
import re
import copy
import csv
import argparse
from typing import Any, Callable, Dict, List, Optional, Tuple, Union


def log(*args: Any) -> None:
    print("{}:".format(sys.argv[0]), *args, file=sys.stderr)


def read_from(path: Optional[str]) -> Any:
    return sys.stdin if not path else open(path, "r")


def output_to(path: Optional[str]) -> Any:
    return sys.stdout if not path else open(path, "w")


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument(
        "source_file",
        action="store",
        help="file to convert (default: stdin)",
        nargs="?",
        type=str,
        default=None,
    )
    parser.add_argument(
        "-o",
        "--output",
        action="store",
        help="destination file (default: stdout)",
        required=False,
        type=str,
        default=None,
    )
    return parser


def main():
    def not_empty_row(f):
        for r in f:
            row = r.strip()
            if row:
                yield row

    def int_or_float(s: str):
        try:
            return int(s)
        except ValueError:
            return float(s)

    def new_fieldnames(fieldnames: List[str], pattern_exprs: Tuple[str]) -> List[str]:
        converted = []
        for f in fieldnames:
            for p in pattern_exprs:
                if re.compile(p).match(f) is not None:
                    converted.append(f)
                    break
        return converted

    def filtered_fieldnames(row: List[str], fieldnames: List[str]) -> Dict[str, str]:
        return {k: v for (k, v) in row.items() if k in fieldnames}

    parser = argparse.ArgumentParser(
        description="Convert perf stat output to a more plottable format"
    )
    args = add_arguments(parser).parse_args()
    patterns = (r"^count$", r"^time$", r"^power/energy-.+/$")
    with read_from(args.source_file) as f:
        with output_to(args.output) as of:
            fieldnames = None
            for row in f:
                if row.startswith("#"):
                    print(row, file=of, end="")
                else:
                    fieldnames = row
                    break
            assert fieldnames is not None
            fieldnames = csv.DictReader((fieldnames,)).fieldnames
            csvrdr = csv.DictReader(not_empty_row(f), fieldnames)
            fieldnames = new_fieldnames(csvrdr.fieldnames, patterns)
            writer = csv.DictWriter(of, fieldnames)
            writer.writeheader()
            first_row = next(iter(csvrdr))
            if first_row is None:
                raise AssertionError("No data rows present")
            writer.writerow(filtered_fieldnames(first_row, writer.fieldnames))

            prev_row = first_row
            for row in csvrdr:
                time_current = int_or_float(row["time"])
                time_prev = int_or_float(prev_row["time"])
                new_row = {}
                new_row["count"] = row["count"]
                new_row["time"] = (time_current + time_prev) // 2
                for k, e_curr in (
                    (k, int_or_float(v))
                    for (k, v) in row.items()
                    if re.compile(r"^power/energy-.+/$").match(k)
                ):
                    delta = (time_current - time_prev) * 1e-9
                    new_row[k] = e_curr / delta
                writer.writerow(new_row)
                prev_row = row


if __name__ == "__main__":
    main()
