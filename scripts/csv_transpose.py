#!/usr/bin/env python3

import argparse
import csv
import sys
from typing import Any, Callable, Optional


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
    return parser


def yield_or_write_rows_predicate(infile: Any, outfile: Any, pred: Callable):
    for row in infile:
        yield row if pred(row) else print(row, file=outfile, end="")


def main():
    parser = argparse.ArgumentParser(description="Transpose CSV file")
    args = add_arguments(parser).parse_args()
    with read_from(args.source_file) as f:
        with output_to(args.output) as of:
            csvrdr = csv.reader(
                yield_or_write_rows_predicate(
                    f, of, lambda x: not x.strip().startswith("#")
                )
            )
            data = []
            csvwrt = csv.writer(of, dialect=csvrdr.dialect)
            for row in csvrdr:
                data.append(row)
            colcount = len(data[0])
            for ix in range(colcount):
                csvwrt.writerow(r[ix] for r in data)


if __name__ == "__main__":
    main()
