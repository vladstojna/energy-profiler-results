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
replace_tag="$(dirname $0)/../scripts/config_replace_tag_value.sh"

profiled_dir="gpu"
plain_dir="gpu_plain"

mkdir -p "$(dirname $0)/$profiled_dir"
mkdir -p "$(dirname $0)/$plain_dir"

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

make -C "$EP_PREFIX/nrg" clean
make -C "$EP_PREFIX/nrg" gpu=GPU_NONE cpu=CPU_NONE -j

for i in $(seq $EP_REPEAT_NTIMES); do
    for x in ${intervals[@]}; do
        outdir="$(dirname $0)/$profiled_dir/$x"
        mkdir -p "$outdir"
        for l in $(cat $EP_PARAMS_FILE); do
            IFS=':' read -r -a params <<< "$l"
            bin="$EP_PREFIX/bin/profiler"
            config="$EP_EVAL_PREFIX/profiler-config/${params[0]}"
            sample="$EP_EVAL_PREFIX/${params[1]}"
            args="${params[@]:2}"
            output="output.${params[1]//[\/]/_}.${args//[ ]/_}"
            echo "Running $replace_tag interval $x $config | $bin -q -o $outdir/$output.none.$i.json -- $sample $args"
            $replace_tag interval $x $config | \
            $bin -q -o "$outdir/$output.none.$i.json" -- $sample $args \
                > "$outdir/$output.none.$i.csv"
        done
    done
done

make -C "$EP_PREFIX/nrg" clean
make -C "$EP_PREFIX/nrg" cpu=CPU_NONE -j

for i in $(seq $EP_REPEAT_NTIMES); do
    for x in ${intervals[@]}; do
        outdir="$(dirname $0)/$profiled_dir/$x"
        mkdir -p "$outdir"
        for l in $(cat $EP_PARAMS_FILE); do
            IFS=':' read -r -a params <<< "$l"
            bin="$EP_PREFIX/bin/profiler"
            config="$EP_EVAL_PREFIX/profiler-config/${params[0]}"
            sample="$EP_EVAL_PREFIX/${params[1]}"
            args="${params[@]:2}"
            output="output.${params[1]//[\/]/_}.${args//[ ]/_}"
            echo "Running $replace_tag interval $x $config | $bin -q -o $outdir/$output.board.$i.json -- $sample $args"
            $replace_tag interval "$x" "$config" | \
            $bin -q -o "$outdir/$output.board.$i.json" \
                -- $sample $args \
                > "$outdir/$output.board.$i.csv"
        done
    done
done
