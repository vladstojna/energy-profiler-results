#!/usr/bin/env bash

function print_stats
{
    $results_scripts/csv_field_values.py --field "$1" |
        tail -n +2 |
        tac |
        tail -n +2 |
        tac |
        $results_scripts/file_stats_of_lines.py |
        grep 'mean\|stddev' |
        awk '{print $2}' |
        paste -d ',' -s - |
        paste -d ',' <(echo "$1") -
}

results_scripts="$(dirname $0)/../scripts"

echo 'column,mean,stddev'
tee >(print_stats sample_time_delta) >(print_stats overhead) > /dev/null
