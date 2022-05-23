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
    echoerr "Usage: <file list> | $0 <section> <metafield1,metafield2,...>"
    exit 1
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $0)/../scripts"

section=${args[0]}
metafields=${args[1]}

read -r file

$scripts/compact_total_energy.py "$file" |
    $scripts/compact_extract.py -s "$section" |
    tail -n 2 |
    head -n 2 |
    paste -d ',' <(echo "$metafields" && echo "$file" | sed -nE "s/.*${section}_([^\.]+).+$/\1/p" | tr '_' ',') -

while read -r file;
do
   $scripts/compact_total_energy.py "$file" |
        $scripts/compact_extract.py -s "$section" |
        tail -1 |
        paste -d ',' <(echo "$file" | sed -nE "s/.*${section}_([^\.]+).+$/\1/p" | tr '_' ',') -
done
