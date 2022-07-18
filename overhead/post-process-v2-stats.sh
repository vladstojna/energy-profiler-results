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
        xargs |
        python3 -c "import sys; \
            values = next(iter(sys.stdin)).split(' '); \
            print('{}\n{}\n'.format(float(values[0]) $3, float(values[1]) $3))" |
        paste -d ',' -s - |
        paste -d ',' <(echo "$1,$2") -
}

results_scripts="$(dirname $0)/../scripts"

echo 'column,unit,mean,stddev'
tee >(print_stats sample_time_delta 'ms' '/ 1000000') \
    >(print_stats overhead '%' '* 100') > \
    /dev/null
