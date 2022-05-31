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
if [[ "${#args[@]}" -lt 3 ]]; then
    echoerr "Usage: $0 <prefixes> <intervals> <threads>"
    echoerr "prefixes, intervals and threads are colon-separated values"
    exit 1
fi

IFS=':' read -r -a prefixes <<< "${args[0]}"
IFS=':' read -r -a intervals <<< "${args[1]}"
IFS=':' read -r -a threads <<< "${args[2]}"

pp_script="$(dirname $0)/post-process.sh"

for p in ${prefixes[@]}; do
    for t in ${threads[@]}; do
        for i in ${intervals[@]}; do
            $pp_script plain_$t/$(basename $p) profiled_$t/$i/$(basename $p) "$i"
            echo "-"
        done
        echo "---"
    done
done
