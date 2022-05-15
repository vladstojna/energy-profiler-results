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

bin="$EP_PREFIX/bin/profiler"
config="$(dirname $0)/config/cusolver.xml"
outdir="$(dirname $0)/output"
mkdir -p "$outdir"

make -C "$EP_EVAL_PREFIX/cusolver" USE_ITERATIONS=1 DO_COMPUTATION=1 remake
echo "Running USE_ITERATIONS=1 DO_COMPUTATION=1"
for l in $(cat $EP_PARAMS_FILE); do
    # sensors:
    # package + cores + dram
    IFS=':' read -r -a params <<< "$l"
    sample="$EP_EVAL_PREFIX/${params[0]}"
    args="${params[@]:1}"
    output="output.${params[0]//[\/]/_}.${args//[ ]/_}"
    echo "Running $bin -q -c $config -o $outdir/$output.0xb.json -- $sample $args"
    # $bin -q -c "$config" -o "$outdir/$output.0xb.json" \
    #     -- $sample $args \
    #     > "$outdir/$output.0xb.csv"
done

outdir="${outdir}_noop"
mkdir -p "$outdir"

make -C "$EP_EVAL_PREFIX/cusolver" USE_ITERATIONS=1 remake
echo "Running USE_ITERATIONS=1"
for l in $(cat $EP_PARAMS_FILE); do
    # sensors:
    # package + cores + dram
    IFS=':' read -r -a params <<< "$l"
    sample="$EP_EVAL_PREFIX/${params[0]}"
    args="${params[@]:1}"
    output="output.${params[0]//[\/]/_}.${args//[ ]/_}"
    echo "Running $bin -q -c $config -o $outdir/$output.0xb.json -- $sample $args"
    # $bin -q -c "$config" -o "$outdir/$output.0xb.json" \
    #     -- $sample $args \
    #     > "$outdir/$output.0xb.csv"
done
