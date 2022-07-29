#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

args=( $@ )
if [[ "${#args[@]}" -lt 2 ]]; then
    echoerr "Usage: $0 <file> <interval>"
    exit 1
fi

file=${args[0]}
interval=${args[1]}
results_scripts="$(dirname $0)/../../scripts"

$results_scripts/perf_convert_output.py "$file" |
    tail -n +2 |
    awk -F ',' '{print $1 "," $2}' |
    tr -d "\r" |
    paste -d ',' - \
        <(echo 'sample_time_delta,overhead' && echo '0,0.0' &&
            $results_scripts/perf_convert_output.py "$file" |
            $results_scripts/csv_field_values.py --field "time" |
            $results_scripts/file_delta_of_lines.py |
            python3 -c "import sys; [print('{},{}'.format(int(x), int(x) / ($interval * 1000000) - 1)) for x in sys.stdin]")
