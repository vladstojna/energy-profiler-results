#!/usr/bin/env python3

import argparse
import csv
import json
import sys


def read_from(path):
    return sys.stdin if not path else open(path, "r")


def output_to(path):
    return sys.stdout if not path else open(path, "w")

def add_args(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument(
        "source_file",
        action="store",
        help="file to extract from (default: stdin)",
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
    return parser

def main():
    parser = argparse.ArgumentParser(description="Count samples of each execution")
    args = add_args(parser).parse_args()
    with read_from(args.source_file) as f:
        json_in = json.load(f)
        with output_to(args.output) as o:
            wrt = csv.writer(o)
            wrt.writerow(("group", "section", "execution", "duration", "samples"))
            for g in json_in["groups"]:
                for s in g["sections"]:
                    for idx, e in enumerate(s["executions"], start=1):
                        duration = e["sample_times"][-1] - e["sample_times"][0]
                        wrt.writerow((g["label"], s["label"], idx, duration, len(e["sample_times"])))


if __name__ == "__main__":
    main()