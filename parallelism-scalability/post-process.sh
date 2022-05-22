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
    echoerr "Usage: <file list> | $0 <section> <field1,field2,...>"
    exit 1
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $0)/../scripts"

section=${args[0]}
fields=${args[1]}

tmp_file=$(mktemp)

read -r file
$scripts/compact_total_energy.py "$file" | \
    $scripts/compact_extract.py -s "$section" | \
    tail -n 2 | \
    head -n 2 \
    > "$tmp_file"

files=( "$file" )
while read -r file;
do
   $scripts/compact_total_energy.py "$file" | \
        $scripts/compact_extract.py -s "$section" | \
        tail -1 \
        >> "$tmp_file"
    files+=( "$file" )
done

head -n 2 "$tmp_file" | awk '{print "#" $0}'

$results_scripts/csv_column_operation2.py \
    --fields "$fields" \
    --operation div \
    --operand left \
    "$tmp_file" |
    paste -d ',' <(echo 'threads' && seq ${#files[@]}) -