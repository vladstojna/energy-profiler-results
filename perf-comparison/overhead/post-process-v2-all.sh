#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

args=( $@ )
if [[ "${#args[@]}" -lt 4 ]]; then
    echoerr "Usage: $0 <output_dir> <prefixes> <intervals> <threads>"
    echoerr "arguments are colon-separated values"
    exit 1
fi

pp_script_perf="$(dirname $0)/post-process-v2-sampling-overhead.sh"
pp_script="$(dirname $0)/../../overhead/post-process-v2-sampling-overhead.sh"
pp_script_join="$(dirname $0)/../../overhead/post-process-v2-join-files.sh"
pp_script_stats="$(dirname $0)/../../overhead/post-process-v2-stats.sh"

IFS=':' read -r -a output_dir <<< "${args[0]}"
IFS=':' read -r -a prefixes <<< "${args[1]}"
IFS=':' read -r -a intervals <<< "${args[2]}"
IFS=':' read -r -a threads <<< "${args[3]}"

sensors="0xb"

for t in ${threads[@]}; do
    for i in ${intervals[@]}; do
        for p in ${prefixes[@]}; do
            # post process perf output
            if find $(dirname $0) -name "$(basename $p).perf.$sensors.*[^.app].csv" | grep "profiled_$t/$i/"; then
                outdir="$output_dir/perf/$t/$i"
                mkdir -p "$outdir"
                files2join=( )
                for file in $(find . -name "$(basename $p).perf.$sensors.*[^.app].csv" | grep "profiled_$t/$i/"); do
                    output_file="$outdir/$(basename -s .csv $file).csv"
                    files2join+=( "$output_file" )
                    $pp_script_perf "$file" "$i" > "$output_file"
                done
                $pp_script_join ${files2join[@]} |
                    $pp_script_stats |
                    column -t -s ',' > "$outdir/$(basename $p).$sensors.stats.txt"
            fi
            # post process profiler output
            if ls profiled_$t/$i/$(basename $p).$sensors.*.json > /dev/null; then
                outdir="$output_dir/profiler/$t/$i"
                mkdir -p "$outdir"
                files2join=( )
                for file in $(ls profiled_$t/$i/$(basename $p).$sensors.*.json); do
                    output_file="$outdir/$(basename -s .json $file).csv"
                    files2join+=( "$output_file" )
                    $pp_script "$file" "$i" > "$output_file"
                done
                $pp_script_join ${files2join[@]} |
                    $pp_script_stats |
                    column -t -s ',' > "$outdir/$(basename $p).$sensors.stats.txt"
            fi
        done
    done
done
