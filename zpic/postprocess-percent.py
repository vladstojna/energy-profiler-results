#!/usr/bin/env python3

import argparse
import csv
import sys
from typing import Any, Callable, Dict, List, Optional, Tuple


def read_from(path: Optional[str]) -> Any:
    return sys.stdin if not path else open(path, "r")


def output_to(path: Optional[str]) -> Any:
    return sys.stdout if not path else open(path, "w")


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument(
        "source_file",
        action="store",
        help="extracted CSV file (default: stdin)",
        nargs="?",
        type=str,
        default=None,
    )
    parser.add_argument(
        "-s",
        "--sleep",
        action="store",
        help="sleep CSV input file",
        required=False,
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


def get_sums(data: List[Dict[str, str]], excluded: Tuple[str]) -> Dict[str, float]:
    first = data[0]
    sums = {k: float(v) for (k, v) in first.items() if k not in excluded}
    for next in data[1:]:
        for k in sums:
            sums[k] += float(next[k])
    return sums


def get_sums_without_sleep(
    data: List[Dict[str, str]],
    excluded: Tuple[str],
    sleep: Dict[str, str],
) -> Dict[str, float]:
    sums = {k: 0.0 for k in data[0] if k not in excluded}
    for row in data:
        for k in sums:
            if k in sleep:
                sums[k] += float(row[k]) - (float(sleep[k]) * int(row["executions"]))
            else:
                sums[k] += float(row[k])
    return sums


def main():
    parser = argparse.ArgumentParser()
    args = add_arguments(parser).parse_args()
    excluded_fields = ("group", "section", "executions")
    with read_from(args.source_file) as f:
        data = [r for r in csv.DictReader(f)]
        with output_to(args.output) as of:
            csvwrt = csv.DictWriter(of, data[0])
            csvwrt.writeheader()
            if args.sleep is None:
                sums = get_sums(data, excluded=excluded_fields)
                for row in data:
                    for k, v in sums.items():
                        row[k] = float(row[k]) / v * 100 if v else 0.0
                    csvwrt.writerow(row)
            else:
                with open(args.sleep, "r") as sf:
                    sleep_data = [r for r in csv.DictReader(sf)][0]
                    sums = get_sums_without_sleep(
                        data, excluded=excluded_fields, sleep=sleep_data
                    )
                    for row in data:
                        for k, v in sums.items():
                            if k in sleep_data:
                                to_sub = int(row["executions"]) * float(sleep_data[k])
                                row[k] = (
                                    (float(row[k]) - to_sub) / v * 100 if v else 0.0
                                )
                            else:
                                row[k] = float(row[k]) / v * 100 if v else 0.0
                        csvwrt.writerow(row)


if __name__ == "__main__":
    main()
