#!/usr/bin/env python3

import argparse
import csv
from posixpath import sep
import sys
from typing import Any, Optional, Tuple


def read_from(path: Optional[str]) -> Any:
    return sys.stdin if not path else open(path, "r")


def output_to(path: Optional[str]) -> Any:
    return sys.stdout if not path else open(path, "w")


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument(
        "source_file",
        action="store",
        help="input file (default: stdin)",
        nargs="?",
        type=str,
        default=None,
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
        "-f",
        "--field",
        action="store",
        help="CSV field",
        required=True,
        type=str,
        default=None,
    )
    parser.add_argument(
        "-s",
        "--separator",
        action="store",
        help="CSV field separator",
        required=False,
        type=str,
        default=",",
    )
    return parser


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
    parser = argparse.ArgumentParser(description="Output specific field from CSV")
    args = add_arguments(parser).parse_args()
    with read_from(args.source_file) as f:
        csvrdr = csv.DictReader(
            (r for r in f if not r.lstrip().rstrip().startswith("#")),
            delimiter=args.separator,
        )
        with output_to(args.output) as of:
            for row in csvrdr:
                print(row[args.field], file=of, end="\n")


if __name__ == "__main__":
    main()
