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

if [[ ! -z "$MKL_NUM_THREADS" ]]; then
    # export OpenMP threads for when sample uses OpenMP
    export OMP_NUM_THREADS="$MKL_NUM_THREADS"
    echo "Threads: $MKL_NUM_THREADS"
    profiled_dir="output_${MKL_NUM_THREADS}t"
else
    echo "Threads: default"
    profiled_dir="output_default_threads"
fi

outdir="$(dirname $0)/$profiled_dir"
mkdir -p "$outdir"

export LC_ALL='C'
perf=perf
event_pkg='power/energy-pkg/'
event_cores='power/energy-cores/'
event_ram='power/energy-ram/'

for l in $(cat $EP_PARAMS_FILE); do
    # sensors:
    # package + cores + dram
    IFS=':' read -r -a params <<< "$l"
    bin="$EP_PREFIX/bin/profiler"
    config="$EP_EVAL_PREFIX/profiler-config/${params[0]}"
    sample="$EP_EVAL_PREFIX/${params[1]}"
    args="${params[@]:2}"
    output="output.${params[1]//[\/]/_}.${args//[ ]/_}"

    echo "Running SECTION $bin -q --cpu-sensors b -c $config -o $outdir/$output.0xb.json -- $sample $args"
    mkdir -p "$outdir/section"
    touch "$outdir/section/$output.perf.0xb.csv"
    date +#%s%N > "$outdir/section/$output.perf.0xb.csv" && \
        $perf stat -a -x ',' -e "$event_pkg" -e "$event_cores" -e "$event_ram" -I 100 --append \
            -o "$outdir/section/$output.perf.0xb.csv" -- \
            $bin -q --cpu-sensors "b" -c "$config" -o "$outdir/section/$output.0xb.json" \
                -- $sample $args \
                > "$outdir/section/$output.0xb.csv"

    echo "Running MAIN $bin -q --cpu-sensors b -c $config -o $outdir/$output.0xb.json -- $sample $args"
    config="$(dirname $0)/config/main.xml"
    mkdir -p "$outdir/main"
    touch "$outdir/main/$output.perf.0xb.csv"
    date +#%s%N > "$outdir/main/$output.perf.0xb.csv" && \
        $perf stat -a -x ',' -e "$event_pkg" -e "$event_cores" -e "$event_ram" -I 100 --append \
            -o "$outdir/main/$output.perf.0xb.csv" -- \
            $bin -q --cpu-sensors "b" -c "$config" -o "$outdir/main/$output.0xb.json" \
                -- $sample $args \
                > "$outdir/main/$output.0xb.csv"
done
