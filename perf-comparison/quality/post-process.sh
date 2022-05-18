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
if [[ "${#args[@]}" -lt 1 ]]; then
    echoerr "Usage: $0 <output_dir> [section]"
    exit 1
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $0)/../../scripts"

outdir=${args[0]}
section=${args[1]}

read -r file_prefix
first_time=$(head -n 1 "$file_prefix.perf.0xb.csv" | cut -c2-)
file_base=$(basename "$file_prefix")

if [[ -z "$section" ]]; then
    $scripts/filter_duplicates.py "$file_prefix.0xb.json" | \
        $scripts/convert_representation.py -e nm --relative-time "$first_time" | \
        $scripts/extract_execution.py \
        > "$outdir/$file_base.profiler.csv"

    $results_scripts/perf_convert_output.py "$file_prefix.perf.0xb.csv" | \
        $results_scripts/perf_filter_duplicates.py \
        > "$outdir/$file_base.perf.csv"

    $results_scripts/relative_time.py \
        --amount "$first_time" \
        "$file_prefix.0xb.csv" \
        > "$outdir/$file_base.timeprinter.csv"
else
    $scripts/filter_duplicates.py "$file_prefix.0xb.json" | \
        $scripts/convert_representation.py -e nm --relative-time "$first_time" | \
        $scripts/extract_execution.py -s "$section" \
        > "$outdir/$file_base.$section.profiler.csv"

    $results_scripts/perf_convert_output.py "$file_prefix.perf.0xb.csv" | \
        $results_scripts/perf_filter_duplicates.py \
        > "$outdir/$file_base.$section.perf.csv"

    $results_scripts/relative_time.py \
        --amount "$first_time" \
        "$file_prefix.0xb.csv" \
        > "$outdir/$file_base.$section.timeprinter.csv"
fi