#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

if [[ -z "$EP_EVAL_PREFIX" ]]; then
    echoerr "Environment variable EP_EVAL_PREFIX not set"
    exit 1
fi
if [[ -z "$EP_PREFIX" ]]; then
    echoerr "Environment variable EP_PREFIX not set"
    exit 1
fi
if [[ -z "$EP_PARAMS_FILE" ]]; then
    echoerr "Environment variable EP_PARAMS_FILE not set"
    exit 1
fi
if [[ -z "$EP_THREADS" ]]; then
    echoerr "Environment variable EP_THREADS not set"
    exit 1
fi

IFS=':' read -r -a threads <<< "$EP_THREADS"
config="$(dirname $0)/config/lapacke.xml"
outdir="$(dirname $0)/output"
mkdir -p "$outdir"

for t in ${threads[@]}; do
    export MKL_NUM_THREADS="$t"
    for l in $(cat $EP_PARAMS_FILE); do
        # sensors:
        # package + cores + dram
        IFS=':' read -r -a params <<< "$l"
        bin="$EP_PREFIX/bin/profiler"
        sample="$EP_EVAL_PREFIX/${params[0]}"
        args="${params[@]:1}"
        output="output.${params[0]//[\/]/_}.${args//[ ]/_}"
        echo "Running $bin -q --cpu-sensors b -c $config -o $outdir/$output.0xb.${t}t.json -- $sample $args"
        $bin -q --cpu-sensors "b" -c "$config" -o "$outdir/$output.0xb.${t}t.json" \
            -- $sample $args \
            > "$outdir/$output.0xb.${t}t.csv"
    done
done
