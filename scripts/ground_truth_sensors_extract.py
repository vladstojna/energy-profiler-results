#!/usr/bin/env python3

import argparse
import csv
import sys
from typing import Any, Dict, Optional, Tuple


def read_from(path: Optional[str]) -> Any:
    return sys.stdin if not path else open(path, "r")


def output_to(path: Optional[str]) -> Any:
    return sys.stdout if not path else open(path, "w")


def log(*args: Any) -> None:
    print("{}:".format(sys.argv[0]), *args, file=sys.stderr)


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
        "-o",
        "--output",
        action="store",
        help="output file (default: stdout)",
        required=False,
        type=str,
        default=None,
    )
    return parser


def to_nanoseconds(ts: float) -> int:
    return int(ts * 1e9)


def kwh2joule(kwh: float) -> float:
    return kwh * 3600000


def integrate_energy(
    prev_energy: float,
    prev_pwr: float,
    prev_ts: float,
    curr_pwr: float,
    curr_ts: float,
) -> Tuple[float, float]:
    energy = ((prev_pwr + curr_pwr) / 2) * (curr_ts - prev_ts)
    return (energy + prev_energy), energy


def generate_first_row(row: Dict[str, str]) -> Tuple[float, Dict[str, Any]]:
    localtime_ini = float(row["localtime_ini"])
    localtime_fin = float(row["localtime_fin"])
    localtime_avg = (localtime_ini + localtime_fin) / 2

    idx = int(row["#index"])
    errcode = float(row["err_code"])
    if errcode:
        log("Row with index {} with non-zero error code {}".format(idx, errcode))
        return None

    return float(row["total"]), {
        "count": 0,
        "index": idx,
        "current": float(row["current"]),
        "voltage": float(row["voltage"]),
        "power_watt": float(row["power"]),
        "energy_kwh": 0.0,
        "energy_joule_from_kwh": 0.0,
        "energy_joule": 0.0,
        "energy_joule_acc": 0.0,
        "errcode": float(row["err_code"]),
        "localtime_ini": localtime_ini,
        "localtime_ini_ns": to_nanoseconds(localtime_ini),
        "localtime_fin": localtime_fin,
        "localtime_fin_ns": to_nanoseconds(localtime_fin),
        "localtime_avg": localtime_avg,
        "localtime_avg_ns": to_nanoseconds(localtime_avg),
    }


def generate_first_row_no_err(reader: csv.DictReader) -> Tuple[float, Dict[str, Any]]:
    for raw in reader:
        val = generate_first_row(raw)
        if val is not None:
            return val
    raise AssertionError("No data rows without error found")


def generate_next_row(
    curr_row: Dict[str, str], prev_row: Dict[str, Any], first_kwh: float
) -> Dict[str, Any]:
    localtime_ini = float(curr_row["localtime_ini"])
    localtime_fin = float(curr_row["localtime_fin"])
    localtime_avg = (localtime_ini + localtime_fin) / 2
    curr_pwr = float(curr_row["power"])
    curr_kwh = float(curr_row["total"]) - first_kwh
    energy_acc, energy = integrate_energy(
        prev_energy=prev_row["energy_joule_acc"],
        prev_pwr=prev_row["power_watt"],
        prev_ts=prev_row["localtime_avg"],
        curr_pwr=curr_pwr,
        curr_ts=localtime_avg,
    )

    idx = int(curr_row["#index"])
    errcode = float(curr_row["err_code"])
    if errcode:
        log("Row with index {} with non-zero error code {}".format(idx, errcode))
        return None

    return {
        "count": prev_row["count"] + 1,
        "index": idx,
        "current": float(curr_row["current"]),
        "voltage": float(curr_row["voltage"]),
        "power_watt": curr_pwr,
        "energy_kwh": curr_kwh,
        "energy_joule_from_kwh": kwh2joule(curr_kwh),
        "energy_joule": energy,
        "energy_joule_acc": energy_acc,
        "errcode": float(curr_row["err_code"]),
        "localtime_ini": localtime_ini,
        "localtime_ini_ns": to_nanoseconds(localtime_ini),
        "localtime_fin": localtime_fin,
        "localtime_fin_ns": to_nanoseconds(localtime_fin),
        "localtime_avg": localtime_avg,
        "localtime_avg_ns": to_nanoseconds(localtime_avg),
    }


def generate_next_rows_no_err(
    reader: csv.DictReader,
    writer: csv.DictWriter,
    prev_row: Dict[str, Any],
    first_kwh: float,
) -> None:
    for raw in reader:
        val = generate_next_row(raw, prev_row, first_kwh=first_kwh)
        if val is not None:
            prev_row = val
            writer.writerow(prev_row)


def main():
    parser = argparse.ArgumentParser(
        description="Extract useful columns and convert units if necessary"
    )
    args = add_arguments(parser).parse_args()
    with read_from(args.source_file) as f:
        reader = csv.DictReader(f, delimiter=";")
        kwh, prev_row = generate_first_row_no_err(reader)
        with output_to(args.output) as of:
            writer = csv.DictWriter(of, prev_row, delimiter=",")
            writer.writeheader()
            writer.writerow(prev_row)
            generate_next_rows_no_err(reader, writer, prev_row=prev_row, first_kwh=kwh)


if __name__ == "__main__":
    main()
