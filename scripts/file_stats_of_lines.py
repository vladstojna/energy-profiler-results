#!/usr/bin/env python3

import argparse
import sys
import statistics as stat
from typing import Any, Optional


def read_from(path: Optional[str]) -> Any:
    return sys.stdin if not path else open(path, "r")


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument(
        "source_file",
        action="store",
        help="file to read from (default: stdin)",
        nargs="?",
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
        description="Output the statistics of a file with numbers as lines"
    )
    args = add_arguments(parser).parse_args()
    with read_from(args.source_file) as f:
        data = [int_or_float(x) for x in f]
        mean = stat.mean(data)
        print("mean", mean)
        print("median", stat.median(data))
        print("mode", stat.mode(data))
        print("stddev", stat.stdev(data))
        print("variance", stat.variance(data, xbar=mean))


if __name__ == "__main__":
    main()
