#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

if [[ -z "$EP_REPEAT_NTIMES" ]]; then
    echoerr "Environment variable EP_REPEAT_NTIMES not set"
    exit 1
fi
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
if [[ -z "$EP_CONFIG_INTERVALS" ]]; then
    echoerr "Environment variable EP_CONFIG_INTERVALS not set"
    exit 1
fi

IFS=':' read -r -a intervals <<< "$EP_CONFIG_INTERVALS"
replace_tag="$(dirname $0)/../../scripts/config_replace_tag_value.sh"

export LC_ALL='C'
perf=perf
event_pkg='power/energy-pkg/'
event_cores='power/energy-cores/'
event_ram='power/energy-ram/'

if [[ ! -z "$MKL_NUM_THREADS" ]]; then
    echo "Threads: $MKL_NUM_THREADS"
    profiled_dir="profiled_${MKL_NUM_THREADS}t"
    plain_dir="plain_${MKL_NUM_THREADS}t"
else
    echo "Threads: default"
    profiled_dir="profiled_default_threads"
    plain_dir="plain_default_threads"
fi

mkdir -p "$(dirname $0)/$plain_dir"
mkdir -p "$(dirname $0)/$profiled_dir"

for i in $(seq $EP_REPEAT_NTIMES); do
    for l in $(cat $EP_PARAMS_FILE); do
        IFS=':' read -r -a params <<< "$l"
        sample="$EP_EVAL_PREFIX/${params[1]}"
        args="${params[@]:2}"
        output="output.${params[1]//[\/]/_}.${args//[ ]/_}"
        echo "Running $sample $args"
        $sample $args > "$(dirname $0)/$plain_dir/$output.$i.csv"
    done
done

for i in $(seq $EP_REPEAT_NTIMES); do
    for x in ${intervals[@]}; do
        outdir="$(dirname $0)/$profiled_dir/$x"
        mkdir -p "$outdir"
        for l in $(cat $EP_PARAMS_FILE); do
            # sensors:
            # package + cores + dram
            IFS=':' read -r -a params <<< "$l"
            bin="$EP_PREFIX/bin/profiler"
            config="$EP_EVAL_PREFIX/profiler-config/${params[0]}"
            sample="$EP_EVAL_PREFIX/${params[1]}"
            args="${params[@]:2}"
            output="output.${params[1]//[\/]/_}.${args//[ ]/_}"

            echo "Running $perf stat -a -x ',' -e $event_pkg -e $event_cores -e $event_ram -I $x -o $outdir/$output.perf.0xb.$i.csv -- $sample $args"
            $perf stat -a -x ',' -e "$event_pkg" -e "$event_cores" -e "$event_ram" -I $x \
                -o "$outdir/$output.perf.0xb.$i.csv" \
                -- $sample $args \
                > "$outdir/$output.perf.0xb.$i.app.csv"

            echo "Running $replace_tag interval $x $config | $bin -q --cpu-sensors b -o $outdir/$output.0xb.$i.json -- $sample $args"
            $replace_tag interval "$x" "$config" | \
            $bin -q --cpu-sensors b -o "$outdir/$output.0xb.$i.json" \
                -- $sample $args \
                > "$outdir/$output.0xb.$i.csv"
        done
    done
done
