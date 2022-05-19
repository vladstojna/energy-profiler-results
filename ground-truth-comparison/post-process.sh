#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

if [[ -z "$EP_PREFIX" ]]; then
    echoerr "Environment variable EP_PREFIX not set"
    exit 1
fi

args=( $@ )
if [[ "${#args[@]}" -lt 2 ]]; then
    echoerr "Usage: $0 <file_prefix> <output_directory> [section]"
    exit 1
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $0)/../scripts"

file_prefix=${args[0]}
outdir=${args[1]}
section=${args[2]}

file_base=$(basename "$file_prefix")

read -r sensors_file
first_time=$($results_scripts/ground_truth_sensors_extract.py "$sensors_file" | \
    $results_scripts/csv_field_values.py \
        --field 'localtime_avg_ns' | \
        head -n 1)

$results_scripts/ground_truth_sensors_extract.py "$sensors_file" | \
    $results_scripts/csv_column_operation2.py \
        --operation sub \
        --fields 'localtime_ini,localtime_ini_ns,localtime_fin,localtime_fin_ns,localtime_avg,localtime_avg_ns' \
    > "$outdir/$file_base.gt.csv"

$results_scripts/relative_time.py --amount "$first_time" "$file_prefix.timeprinter.csv" \
    > "$outdir/$file_base.timeprinter.relative.csv"

if [[ ! -z "$section" ]]; then
    $scripts/filter_duplicates.py "$file_prefix.profiler.json" | \
        $scripts/convert.py --to power | \
        $scripts/convert_representation.py -e nm --relative-time "$first_time" | \
        $scripts/extract_execution.py -s "$section" \
        > "$outdir/$file_base.profiler.csv"
else
    $scripts/filter_duplicates.py "$file_prefix.profiler.json" | \
        $scripts/convert.py --to power | \
        $scripts/convert_representation.py -e nm --relative-time "$first_time" | \
        $scripts/extract_execution.py \
        > "$outdir/$file_base.profiler.csv"
fi