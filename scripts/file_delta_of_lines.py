#!/usr/bin/env python3

import argparse
import sys
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
        description="Compute the delta from a list of numbers"
    )
    args = add_arguments(parser).parse_args()
    with read_from(args.source_file) as f:
        prev_line = next(iter(f))
        for row in f:
            print(int_or_float(row) - int_or_float(prev_line))
            prev_line = row


if __name__ == "__main__":
    main()
