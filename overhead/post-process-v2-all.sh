#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

pp_script="$(dirname $0)/post-process-v2-sampling-overhead.sh"
pp_script_join="$(dirname $0)/post-process-v2-join-files.sh"
pp_script_stats="$(dirname $0)/post-process-v2-stats.sh"

args=( $@ )
if [ "${args[0]}" != "cpu" ] && [ "${args[0]}" != "gpu" ]; then
    echoerr "Usage: $0 <cpu|gpu>"
    exit 1
fi

if [[ "${args[0]}" = "cpu" ]] && [[ "${#args[@]}" -lt 6 ]]; then
    echoerr "Usage: $0 cpu <output_dir> <prefixes> <intervals> <sensors> <threads>"
    echoerr "arguments are colon-separated values"
    exit 1
elif [[ "${args[0]}" = "gpu" ]] && [[ "${#args[@]}" -lt 5 ]]; then
    echoerr "Usage: $0 gpu <output_dir> <prefixes> <intervals> <sensors>"
    echoerr "arguments are colon-separated values"
    exit 1
fi

IFS=':' read -r -a output_dir <<< "${args[1]}"
IFS=':' read -r -a prefixes <<< "${args[2]}"
IFS=':' read -r -a intervals <<< "${args[3]}"
IFS=':' read -r -a sensors <<< "${args[4]}"

if [ "${args[0]}" = "cpu" ]; then
    IFS=':' read -r -a threads <<< "${args[5]}"
    for t in ${threads[@]}; do
        for s in ${sensors[@]}; do
            for i in ${intervals[@]}; do
                mkdir -p "$output_dir/cpu/$t/$s/$i"
                for p in ${prefixes[@]}; do
                    if ls profiled_$t/$i/$(basename $p).$s.*.json > /dev/null; then
                        files2join=( )
                        for file in $(ls profiled_$t/$i/$(basename $p).$s.*.json); do
                            output_file="$output_dir/cpu/$t/$s/$i/$(basename -s .json $file).csv"
                            files2join+=( "$output_file" )
                            $pp_script "$file" "$i" > "$output_file"
                        done
                        $pp_script_join ${files2join[@]} |
                            $pp_script_stats |
                            column -t -s ',' > "$output_dir/cpu/$t/$s/$i/$(basename $p).$s.stats.txt"
                    fi
                done
            done
        done
    done
elif [ "${args[0]}" = "gpu" ]; then
    for s in ${sensors[@]}; do
        for i in ${intervals[@]}; do
            mkdir -p "$output_dir/gpu/$s/$i"
            for p in ${prefixes[@]}; do
                if ls gpu/$i/$(basename $p).$s.*.json > /dev/null; then
                    files2join=( )
                    for file in $(ls gpu/$i/$(basename $p).$s.*.json); do
                        output_file="$output_dir/gpu/$s/$i/$(basename -s .json $file).csv"
                        files2join+=( "$output_file" )
                        $pp_script "$file" "$i" > "$output_file"
                    done
                    $pp_script_join ${files2join[@]} |
                        $pp_script_stats |
                        column -t -s ',' > "$output_dir/gpu/$s/$i/$(basename $p).$s.stats.txt"
                fi
            done
        done
    done
fi
