#!/usr/bin/env python3

import argparse
import csv
import random
import sys
import statistics as stat
from typing import Any, Callable, Dict, Iterable, List, Optional, Union


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
        "--factor",
        action="store",
        help="integer factor to compact dataset by (>= 1)",
        required=True,
        type=int,
        default=1,
    )
    parser.add_argument(
        "--start",
        action="store",
        help="data index (starting at 0) at which compaction starts",
        required=False,
        type=int,
        default=0,
    )
    parser.add_argument(
        "--end",
        action="store",
        help="data index (starting at 0, greater than START) at which compaction ends",
        required=False,
        type=int,
        default=sys.maxsize,
    )
    parser.add_argument(
        "--mode",
        action="store",
        choices=("avg", "first", "random"),
        help="compact by FACTOR using specific method",
        required=False,
        default="first",
    )
    return parser


def int_or_float(x: str):
    try:
        return int(x)
    except ValueError:
        return float(x)


def yield_or_write_rows_predicate(infile: Any, outfile: Any, pred: Callable):
    for row in infile:
        if pred(row):
            yield row
        else:
            print(row, file=outfile, end="")


def yield_inside_interval(
    reader: csv.DictReader, writer: csv.DictWriter, start: int, end: int
):
    for idx, row in enumerate(reader, start=0):
        if idx >= start and idx <= end:
            yield row
        elif idx == end + 1:
            yield None
            writer.writerow(row)
        else:
            writer.writerow(row)


def yield_first_row(rows: Iterable, factor: int):
    for idx, row in enumerate(rows, start=0):
        if row is not None and idx % factor == 0:
            yield row


def yield_random_row(rows: Iterable, factor: int):
    rng_idx: int = random.randint(0, factor - 1)
    for idx, row in enumerate(rows, start=0):
        if row is not None and idx % factor == rng_idx:
            yield row


def yield_average(rows: Iterable, factor: int):
    RowType = Dict[str, str]
    RowTypeNumeric = Dict[str, Union[int, float]]

    def compute_average(rows: List[RowType]) -> RowTypeNumeric:
        def yield_column_values(rows: List[RowType], key: str):
            for row in rows:
                yield int_or_float(row[key])

        assert len(rows) > 0
        first_row = rows[0]
        for k in first_row:
            mean = stat.mean(data=yield_column_values(rows, k))
            if isinstance(int_or_float(first_row[k]), int):
                mean = int(round(mean))
            first_row[k] = mean
        return first_row

    factor_init = factor
    rows_to_process: List[RowType] = []
    for idx, row in enumerate(rows, start=0):
        if row is None:
            yield compute_average(rows_to_process)
        elif idx < factor:
            rows_to_process.append(row)
        elif idx == factor:
            factor += factor_init
            yield compute_average(rows_to_process)
            rows_to_process.clear()
            rows_to_process.append(row)


def main():
    parser = argparse.ArgumentParser(description="Compact CSV dataset")
    args = add_arguments(parser).parse_args()
    if args.factor < 1:
        raise argparse.ArgumentTypeError("FACTOR must be >= 1")
    if args.start < 0:
        raise argparse.ArgumentTypeError("START must be >= 0")
    if args.end <= args.start:
        raise argparse.ArgumentTypeError("END must be > START")
    with read_from(args.source_file) as f:
        with output_to(args.output) as of:
            if args.factor == 1:
                for row in f:
                    print(row, file=of, end="")
            else:
                csvrdr = csv.DictReader(
                    yield_or_write_rows_predicate(
                        f, of, lambda x: not x.strip().startswith("#")
                    )
                )
                csvwrt = csv.DictWriter(
                    of, fieldnames=csvrdr.fieldnames, dialect=csvrdr.dialect
                )
                csvwrt.writeheader()
                rows_inside = yield_inside_interval(
                    csvrdr, csvwrt, args.start, args.end
                )
                if args.mode == "first":
                    csvwrt.writerows(yield_first_row(rows_inside, args.factor))
                elif args.mode == "avg":
                    csvwrt.writerows(yield_average(rows_inside, args.factor))
                elif args.mode == "random":
                    csvwrt.writerows(yield_random_row(rows_inside, args.factor))
                else:
                    assert False


if __name__ == "__main__":
    main()
