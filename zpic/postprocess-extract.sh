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
    echoerr "Usage: $0 <post-processed JSON> [original JSON]"
    exit 1
fi
if [[ "${#args[@]}" -lt 2 ]]; then
    echoerr "Warning: original JSON not provided, number of executions will always be 1"
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $)/../scripts"
post_processed="$(dirname $0)/../post-processed/zpic"
file=${args[0]}
orig_file=${args[1]:-$file}

tail_n="+5"
"$results_scripts/count_executions.py" "$orig_file" |
    tail -n +2 |
    tr -d '\r' |
    grep -v '.*,0$' |
    awk -F, '{print $1"|"$2"|"$3}' |
    while IFS="|" read -r -a labels; do
        group="${labels[0]}"
        section="${labels[1]}"
        execs="${labels[2]}"
        "$scripts/compact_extract.py" -g "$group" -s "$section" "$file" |
            tail -n "$tail_n" |
            if [ "$tail_n" = "+5" ]; then
                cut -d, -f "3-" |
                paste -d, <(echo -e -n "group,section,executions\n\"$group\",\"$section\",$execs\n") -
            else
                cut -d, -f "3-" |
                paste -d, <(echo \"$group\",\"$section\",$execs) -
            fi
        tail_n="+6"
    done
