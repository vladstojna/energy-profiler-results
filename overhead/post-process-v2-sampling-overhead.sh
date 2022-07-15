#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

function get_section
{
    $results_scripts/count_samples.py $1 |
        awk -F ',' '{ print $2 }' |
        head -n 2 |
        tail -n +2 |
        tr -d "\r"
}

if [[ -z "$EP_PREFIX" ]]; then
    echoerr "Environment variable EP_PREFIX not set"
    exit 1
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $0)/../scripts"

args=( $@ )
if [[ "${#args[@]}" -lt 2 ]]; then
    echoerr "Usage: $0 <file> <interval>"
    exit 1
fi

file=${args[0]}
interval=${args[1]}
section=$(get_section $file)

$scripts/extract_execution.py -s "$section" "$file" |
    $results_scripts/relative_time.py -c sample_time |
    tail -n +6 |
    awk -F ',' '{print $1 "," $2}' |
    tr -d "\r" |
    paste -d ',' - \
        <(echo 'sample_time_delta,overhead' && echo '0,0' &&
            $scripts/extract_execution.py -s "$section" "$file" |
            $results_scripts/relative_time.py -c sample_time |
            $results_scripts/csv_field_values.py --field sample_time |
            $results_scripts/file_delta_of_lines.py |
            python3 -c "import sys; [print('{},{}'.format(int(x), int(x) / ($interval * 1000000) - 1)) for x in sys.stdin]")
