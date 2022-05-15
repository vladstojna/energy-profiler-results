#!/usr/bin/env python3

import argparse
import csv
import sys
import statistics as stat
import numpy as np
from typing import Any, Optional


def read_from(path: Optional[str]) -> Any:
    return sys.stdin if not path else open(path, "r")


def output_to(path: Optional[str]) -> Any:
    return sys.stdout if not path else open(path, "w")


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument(
        "source_file",
        action="store",
        help="file to extract from (default: stdin)",
        nargs="?",
        type=str,
        default=None,
    )
    parser.add_argument(
        "-f",
        "--field",
        action="store",
        help="CSV field/column to analyse",
        required=True,
        type=str,
    )
    parser.add_argument(
        "--corr",
        action="store",
        help="CSV field/column to correlate against -f/--field",
        required=False,
        type=str,
        default=None,
    )
    parser.add_argument(
        "--lr",
        action="store",
        help="CSV field/column for which -f/--field values are dependent on",
        required=False,
        type=str,
        default=None,
    )
    return parser


def main():
    def int_or_float(x: str):
        try:
            return int(x)
        except ValueError:
            return float(x)

    parser = argparse.ArgumentParser(
        description="Output the statistics of a field in a CSV file"
    )
    args = add_arguments(parser).parse_args()
    with read_from(args.source_file) as f:
        reader = csv.DictReader((r for r in f if not r.strip().startswith("#")))
        if args.field not in reader.fieldnames:
            raise AssertionError("{} is not a valid fieldname".format(args.field))

        padding = 15

        data = list(reader)
        col = [int_or_float(r[args.field]) for r in data]
        mean = stat.mean(col)
        print("{}{}".format("Mean".ljust(padding), mean))
        print("{}{}".format("Median".ljust(padding), stat.median(col)))
        print("{}{}".format("Mode".ljust(padding), stat.mode(col)))
        print("{}{}".format("Std. Dev".ljust(padding), stat.stdev(col)))
        print("{}{}".format("Variance".ljust(padding), stat.variance(col, xbar=mean)))

        if args.lr:
            if args.lr not in reader.fieldnames:
                raise AssertionError("{} is not a valid fieldname".format(args.lr))
            x = np.array([r[args.lr] for r in data], dtype=float)
            y = np.array(col, dtype=float)
            A = np.vstack([x, np.ones(len(x))]).T

            m, c = np.linalg.lstsq(A, y, rcond=None)[0]
            print("{}m = {} c = {}".format("Regression".ljust(padding), m, c))

        if args.corr:
            if args.corr not in reader.fieldnames:
                raise AssertionError("{} is not a valid fieldname".format(args.corr))
            x = np.array([r[args.corr] for r in data], dtype=float)
            y = np.array(col, dtype=float)
            r = np.corrcoef(x, y)[1, 0]
            print("{}{}".format("R".ljust(padding), r))


if __name__ == "__main__":
    main()
