#!/usr/bin/env python3

import argparse
import csv
import sys
from typing import Any, Callable, Optional, Union


def read_from(path: Optional[str]) -> Any:
    return sys.stdin if not path else open(path, "r")


def output_to(path: Optional[str]) -> Any:
    return sys.stdout if not path else open(path, "w")


def _int_or_float(x: str):
    try:
        return int(x)
    except ValueError:
        return float(x)


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    def _split_values(x: str, sep=","):
        return x.split(sep)

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
        "--fields",
        action="store",
        help="CSV fields",
        required=True,
        type=_split_values,
        default=None,
    )
    parser.add_argument(
        "--values",
        action="store",
        help="values to use on each field entry",
        required=False,
        type=lambda x: [_int_or_float(i) for i in _split_values(x)],
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
    parser.add_argument(
        "--operation",
        action="store",
        help="operation to perform on column values",
        required=True,
        choices=("sub", "add", "mul", "div"),
        type=str,
    )
    parser.add_argument(
        "--operand",
        action="store",
        help="left-hand or right-hand side operator",
        required=False,
        choices=("left", "right"),
        type=str,
        default="right",
    )
    return parser


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


def _apply_operation(
    func: Callable,
    lhs: Union[float, int],
    rhs: Union[float, int],
    lhs_operand: bool = True,
) -> Union[float, int]:
    if lhs_operand:
        lhs, rhs = rhs, lhs
    return func(lhs, rhs)


def main():
    parser = argparse.ArgumentParser(description="Operate on CSV fields")
    args = add_arguments(parser).parse_args()
    if args.values is not None and len(args.values) != len(args.fields):
        raise AssertionError("values count must equal fields count")
    with read_from(args.source_file) as f:
        csvrdr = csv.DictReader(
            (r for r in f if not r.lstrip().rstrip().startswith("#")),
            delimiter=args.separator,
        )
        if not all(x in csvrdr.fieldnames for x in args.fields):
            raise AssertionError("All fields must exist in CSV file")
        with output_to(args.output) as of:
            csvwrt = csv.DictWriter(of, fieldnames=csvrdr.fieldnames)
            csvwrt.writeheader()
            first_row = next(iter(csvrdr), None)
            if first_row is not None:
                if args.values is None:
                    args.values = [_int_or_float(first_row[x]) for x in args.fields]
                for field, value in zip(args.fields, args.values):
                    first_row[field] = _apply_operation(
                        _get_operation(args.operation),
                        _int_or_float(first_row[field]),
                        value,
                        args.operand == "left",
                    )
                csvwrt.writerow(first_row)
                for row in csvrdr:
                    for field, value in zip(args.fields, args.values):
                        row[field] = _apply_operation(
                            _get_operation(args.operation),
                            _int_or_float(row[field]),
                            value,
                            args.operand == "left",
                        )
                    csvwrt.writerow(row)


if __name__ == "__main__":
    main()
