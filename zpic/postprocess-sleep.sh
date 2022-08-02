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
    echoerr "Usage: $0 <sleep file> <sleep duration in s>"
    exit 1
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $0)/../scripts"
post_processed="$(dirname $0)/../post-processed/zpic"

file=${args[0]}
duration=${args[1]}

factor=$(
    $scripts/compact_total_energy.py "$file" 2> /dev/null |
        $scripts/compact_extract.py |
        tail -n +6 |
        awk -F, '{ print $3 }' |
        {
            read -r execution_time
            python -c "print($execution_time / $duration)"
        }
)

$scripts/compact_total_energy.py "$file" 2> /dev/null |
        $scripts/compact_extract.py |
        tail -n +5 | {
            while read -r row; do
                echo "$row"
                while IFS=',' read -r -a row; do
                    values=( ${row[0]} ${row[1]} )
                    for x in ${row[@]:2}; do
                        values+=( $(python3 -c "print($x / $factor)") )
                    done
                    (IFS=','; echo "${values[*]}")
                done
            done
        } |
        cut -d, -f 3-
