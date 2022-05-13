#!/usr/bin/env python3

import sys
import csv
import argparse
import itertools
from typing import Any, Callable, Dict, List, Optional, Tuple, Union


def log(*args: Any) -> None:
    print("{}:".format(sys.argv[0]), *args, file=sys.stderr)


def read_from(path: Optional[str]) -> Any:
    return sys.stdin if not path else open(path, "r")


def output_to(path: Optional[str]) -> Any:
    return sys.stdout if not path else open(path, "w")


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    def positive_int_or_float(s: str) -> Union[int, float]:
        try:
            val = int(s)
            if val <= 0:
                raise argparse.ArgumentTypeError("value must be positive")
            return val
        except ValueError:
            try:
                val = float(s)
                if val <= 0:
                    raise argparse.ArgumentTypeError("value must be positive")
            except ValueError as err:
                raise argparse.ArgumentTypeError(
                    err.args[0] if len(err.args) else "could not convert value to float"
                )

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
    parser.add_argument(
        "-s",
        "--start",
        action="store",
        help="absolute start time (default: 0)",
        required=False,
        type=positive_int_or_float,
        default=0,
    )
    parser.add_argument(
        "-e",
        "--end",
        action="store",
        help="absolute end time (default: 0)",
        required=False,
        type=positive_int_or_float,
        default=0,
    )
    return parser


def main():

    FieldNamesData = Dict[str, Tuple[int, int, Any, Callable]]
    SampleRows = List[List[str]]

    def not_empty_not_comment(f):
        for r in f:
            row = r.strip()
            if row and not row.startswith("#"):
                yield row

    def int_or_float(s: str):
        try:
            return int(s)
        except ValueError:
            return float(s)

    def all_rows_of_sample(
        first_row: List[str], csvrdr: csv.reader
    ) -> Tuple[SampleRows, List[str]]:
        sample_rows = [first_row]
        iterator = iter(csvrdr)
        next_row = next(iterator, None)
        # row exists and time is the same
        while next_row is not None and next_row[0] == first_row[0]:
            sample_rows.append(next_row)
            next_row = next(iterator, None)
        return sample_rows, next_row

    def generate_field_names(sample_rows: SampleRows, start: int) -> FieldNamesData:
        def inc_count(c: List[int]) -> int:
            c[0] += 1
            return c[0]

        def enumerate_step(iterable, start=0, step=1):
            for x in iterable:
                yield (start, x)
                start += step

        fieldnames = {
            "count": (0, 0, [0], inc_count),
            "time": (1, 0, 0, lambda t: int(int_or_float(t) * 1e9) + start),
        }
        for (ix, r), srow_ix in zip(
            enumerate_step(sample_rows, start=2, step=3), range(len(sample_rows))
        ):
            event_name = r[3]
            fieldnames[event_name] = (ix, srow_ix, 1, lambda x: x)
            fieldnames["{}-counter_run_time".format(event_name)] = (
                ix + 1,
                srow_ix,
                4,
                lambda x: x,
            )
            fieldnames["{}-counter_run_percent".format(event_name)] = (
                ix + 2,
                srow_ix,
                5,
                lambda x: x,
            )
        return fieldnames

    def convert_sample_rows(sample_rows: SampleRows, fieldnames: FieldNamesData):
        return (
            call(ix)
            if not isinstance(ix, int)
            else call(sample_rows[srow][ix])
            if sample_rows[srow][ix]
            else 0
            for _, (_, srow, ix, call) in fieldnames.items()
        )

    def shift_row_time(row: List, shift_by: int, time_ix: int):
        return (
            row[ix] if ix != time_ix else row[ix] - shift_by for ix in range(len(row))
        )

    parser = argparse.ArgumentParser(
        description="Convert perf stat output to a more plottable format"
    )
    args = add_arguments(parser).parse_args()
    if args.start and args.end and args.end <= args.start:
        raise parser.error("-e/--end must be greater than -s/--start")
    if args.end and not args.start:
        raise parser.error("-e/--end requires -s/--start")
    with read_from(args.source_file) as f:
        csvrdr = csv.reader(not_empty_not_comment(f))
        first_row = next(iter(csvrdr), None)
        if first_row:
            units_meta = ["#units", "energy=J", "power=W", "time=ns"]
            sample_rows, next_row = all_rows_of_sample(first_row, csvrdr)
            fieldnames = generate_field_names(sample_rows, start=args.start)
            first_data_row = [0, args.start] + ([0.0, 0, 0.0] * len(sample_rows))
            assert len(first_data_row) == len(fieldnames)
            with output_to(args.output) as of:
                writer = csv.writer(of)
                writer.writerow(units_meta)
                writer.writerow(fieldnames)

                if not args.end:
                    writer.writerow(first_data_row)
                    writer.writerow(convert_sample_rows(sample_rows, fieldnames))
                    sample_rows, next_row = all_rows_of_sample(next_row, csvrdr)
                    while next_row is not None:
                        writer.writerow(convert_sample_rows(sample_rows, fieldnames))
                        sample_rows, next_row = all_rows_of_sample(next_row, csvrdr)
                else:
                    data = [first_data_row]
                    data.append(
                        [x for x in convert_sample_rows(sample_rows, fieldnames)]
                    )
                    sample_rows, next_row = all_rows_of_sample(next_row, csvrdr)
                    while next_row is not None:
                        data.append(
                            [x for x in convert_sample_rows(sample_rows, fieldnames)]
                        )
                        sample_rows, next_row = all_rows_of_sample(next_row, csvrdr)
                    time_ix = fieldnames["time"][0]
                    last_time = data[-1][time_ix]
                    if last_time > args.end:
                        shift_by = last_time - args.end
                        log("perf overhead ~", shift_by, "ns")
                        log("shifting time values left by", shift_by, "ns")
                        for row in data:
                            writer.writerow(shift_row_time(row, shift_by, time_ix))
                    else:
                        log("provided end time >= {}".format(last_time))
                        for row in data:
                            writer.writerow(row)


if __name__ == "__main__":
    main()
