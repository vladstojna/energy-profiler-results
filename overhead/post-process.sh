#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

function average_count
{
    python3 -c "lst=[float(x) for x in '$*'.split(' ')]; print(sum(lst) / len(lst))"
}

function round
{
    if [[ "$#" -lt 2 ]]; then
        python3 -c "print(round($1))"
    else
        python3 -c "print(round($1, $2))"
    fi
}

function extract_times_from_counts
{
    local first=$($results_scripts/extract_time.py --count "$2" "$1")
    local second=$($results_scripts/extract_time.py --count "$3" "$1")
    python3 -c "print(($second - $first) / 1e9)"
}

function get_durations
{
    local counts=( $1 $2 )
    local args=( $@ )
    local duration=""
    for f in $(ls ${args[@]:2}); do
        duration+="$(extract_times_from_counts $f ${counts[0]} ${counts[1]}) "
    done
    echoerr "durations: $duration"
    echo "$duration" | xargs
}

function count_profiler_samples
{
    $results_scripts/count_samples.py $1 | awk -F ',' '{ print $5 }' | head -n 2 | tail -n +2 | tr -d "\r"
}

function count_all_profiler_samples
{
    local samples=""
    for f in $(ls $@); do
        samples+="$(count_profiler_samples $f) "
    done
    echoerr "profiler samples: $samples"
    echo "$samples" | xargs
}

function compute_overhead_profiler
{
    python3 -c "import math; print(math.ceil(float($1) / float($3) * 1000 + 1) / float($2) * 100 - 100)"
}

function compute_duration_overhead
{
    python3 -c "print((float($1) / float($2) * 100) - 100)"
}

if [[ -z "$EP_PREFIX" ]]; then
    echoerr "Environment variable EP_PREFIX not set"
    exit 1
fi

args=( $@ )
if [[ "${#args[@]}" -lt 5 ]]; then
    echoerr "Usage: $0 <plain_prefix> <profiled_prefix> <interval> <timeprinter_start-timeprinter_end> <sensors>"
    exit 1
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $0)/../scripts"

plain_prefix=${args[0]}
profiled_prefix=${args[1]}
interval=${args[2]}
IFS='-' read -r -a timeprinter_count <<< "${args[3]}"
sensors=${args[4]}

plain_duration=$(round $(average_count $(get_durations ${timeprinter_count[@]} $plain_prefix.*.csv)) 3)
profiler_duration=$(round $(average_count $(get_durations ${timeprinter_count[@]} $profiled_prefix.$sensors.*.csv)) 3)
profiler_samples=$(round $(average_count $(count_all_profiler_samples $profiled_prefix.$sensors.*.json)))

echo "$profiled_prefix $sensors $profiler_duration $profiler_samples \
    $(compute_overhead_profiler $profiler_duration $profiler_samples $interval)"
echo "$profiled_prefix $sensors $profiler_duration $plain_duration \
    $(compute_duration_overhead $profiler_duration $plain_duration)"
