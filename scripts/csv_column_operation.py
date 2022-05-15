#!/usr/bin/env python3

import argparse
import csv
import sys
from itertools import zip_longest
from typing import Any, Callable, Optional, Tuple, Union


def output_to(path: Optional[str]) -> Any:
    return sys.stdout if not path else open(path, "w")


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument(
        "source_files",
        action="store",
        help="input file",
        nargs=2,
        type=str,
    )
    parser.add_argument(
        "-o",
        "--output",
        action="store",
        help="output file (default: stdout)",
        required=False,
        type=str,
        default=None,
    )
    parser.add_argument(
        "-e",
        "--exclude",
        action="store",
        help="columns to exclude (default: none)",
        required=False,
        type=lambda x: set(x.split(",")),
        default=set(),
    )
    parser.add_argument(
        "--operation",
        action="store",
        help="operation to perform on column values",
        required=True,
        choices=("sub", "add", "mul", "div"),
        type=str,
    )
    return parser


def _int_or_float(x: str) -> Union[int, float]:
    try:
        return int(x)
    except ValueError:
        return float(x)


def _get_operation(x: str) -> Callable:
    lower = x.lower()
    if lower == "sub":
        return lambda x, y: x - y
    if lower == "add":
        return lambda x, y: x + y
    if lower == "mul":
        return lambda x, y: x * y
    if lower == "div":
        return lambda x, y: x / y
    raise AssertionError("Invalid operation {}".format(x))


def read_file(f) -> Tuple[csv.reader, csv.reader]:
    comments = []
    rest = []
    for row in f:
        if row.lstrip().rstrip().startswith("#"):
            comments.append(row)
        else:
            rest.append(row)
    return csv.reader(comments), csv.reader(rest)


def main():
    parser = argparse.ArgumentParser(description="Erase first data row from a CSV file")
    args = add_arguments(parser).parse_args()
    args.operation = _get_operation(args.operation)
    with open(args.source_files[0]) as fleft, open(args.source_files[1]) as fright:
        rdr_left = csv.DictReader(r for r in fleft if not r.lstrip().startswith("#"))
        rdr_right = csv.DictReader(r for r in fright if not r.lstrip().startswith("#"))
        # forward excluded columens from left-side file
        with output_to(args.output) as of:
            writer = csv.DictWriter(of, rdr_left.fieldnames)
            writer.writeheader()
            for rl, rr in zip_longest(rdr_left, rdr_right, fillvalue=None):
                if rl is None or rr is None:
                    raise AssertionError("Files must have the same number of rows")
                if len(rl) != len(rr):
                    raise AssertionError("Rows must have the same number of columns")
                newrow = {
                    k: args.operation(_int_or_float(v), _int_or_float(rr[k]))
                    if k not in args.exclude
                    else v
                    for (k, v) in rl.items()
                }
                writer.writerow(newrow)


if __name__ == "__main__":
    main()
