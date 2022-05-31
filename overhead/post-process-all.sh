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
if [ "${args[0]}" != "cpu" ] && [ "${args[0]}" != "gpu" ]; then
    echoerr "Usage: $0 <cpu|gpu>"
    exit 1
fi

if [[ "${args[0]}" = "cpu" ]] && [[ "${#args[@]}" -lt 6 ]]; then
    echoerr "Usage: $0 cpu <prefixes> <intervals> <timeprinter_counts> <sensors> <threads>"
    echoerr "arguments are colon-separated values"
    exit 1
elif [[ "${args[0]}" = "gpu" ]] && [[ "${#args[@]}" -lt 5 ]]; then
    echoerr "Usage: $0 gpu <prefixes> <intervals> <timeprinter_counts> <sensors>"
    echoerr "arguments are colon-separated values"
    exit 1
fi

pp_script="$(dirname $0)/post-process.sh"
IFS=':' read -r -a prefixes <<< "${args[1]}"
IFS=':' read -r -a intervals <<< "${args[2]}"
IFS=':' read -r -a counts <<< "${args[3]}"
IFS=':' read -r -a sensors <<< "${args[4]}"

if [[ "${#prefixes[@]}" -ne "${#counts[@]}" ]]; then
    echoerr "Number of elements in <prefixes> must equal the number of elements of <timeprinter_counts>"
    exit 1
fi

if [ "${args[0]}" = "cpu" ]; then
    IFS=':' read -r -a threads <<< "${args[5]}"
    for ix in ${!prefixes[@]}; do
        p=${prefixes[ix]}
        tpc=${counts[ix]}
        for t in ${threads[@]}; do
            for i in ${intervals[@]}; do
                for s in ${sensors[@]}; do
                    $pp_script plain_$t/$(basename $p) profiled_$t/$i/$(basename $p) "$i" "$tpc" "$s"
                done
                echo "---"
            done
            echo "-----"
        done
    done
elif [ "${args[0]}" = "gpu" ]; then
    for ix in ${!prefixes[@]}; do
        p=${prefixes[ix]}
        tpc=${counts[ix]}
        for i in ${intervals[@]}; do
            for s in ${sensors[@]}; do
                $pp_script gpu_plain/$(basename $p) gpu/$i/$(basename $p) "$i" "$tpc" "$s"
            done
            echo "---"
        done
        echo "-----"
    done
fi
