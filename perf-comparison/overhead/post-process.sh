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

function get_durations
{
    local duration=""
    for f in $(ls $@); do
        duration+="$(sed -nE 's/^#duration,.+,(.+)$/\1/p' "$f") "
    done
    echoerr "durations: $duration"
    echo "$duration" | xargs
}

function count_perf_samples
{
    $results_scripts/perf_convert_output.py $1 | tail -n +4 | wc -l
}

function count_all_perf_samples
{
    local samples=""
    for f in $(ls $@); do
        samples+="$(count_perf_samples $f) "
    done
    echoerr "perf samples: $samples"
    echo "$samples" | xargs
}

function count_profiler_samples
{
    $results_scripts/count_samples.py $1 | awk -F ',' '{ print $5 }' | tail -n 1 | tr -d "\r"
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

function compute_overhead
{
    python3 -c "print((float($1) / float($3) * 1000 / float($2) * 100) - 100)"
}

function compute_overhead_profiler
{
    python3 -c "print(((float($1) / float($3) * 1000 + 1) / float($2) * 100) - 100)"
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
if [[ "${#args[@]}" -lt 3 ]]; then
    echoerr "Usage: $0 <plain_prefix> <profiled_prefix> <interval>"
    exit 1
fi

scripts="$EP_PREFIX/scripts"
results_scripts="$(dirname $0)/../../scripts"

plain_prefix=${args[0]}
profiled_prefix=${args[1]}
interval=${args[2]}

plain_duration=$(round $(average_count $(get_durations $plain_prefix.*.csv)) 3)

perf_duration=$(round $(average_count $(get_durations $profiled_prefix.perf.0xb.*.app.csv)) 3)
perf_samples=$(round $(average_count $(count_all_perf_samples $profiled_prefix.perf.0xb.[0-9].csv)))

profiler_duration=$(round $(average_count $(get_durations $profiled_prefix.0xb.*.csv)) 3)
profiler_samples=$(round $(average_count $(count_all_profiler_samples $profiled_prefix.0xb.*.json)))

echo "$profiled_prefix.perf $perf_duration $perf_samples \
    $(compute_overhead $perf_duration $perf_samples $interval)"
echo "$profiled_prefix.perf $perf_duration $plain_duration \
    $(compute_duration_overhead $perf_duration $plain_duration)"
echo "$profiled_prefix $profiler_duration $profiler_samples \
    $(compute_overhead_profiler $profiler_duration $profiler_samples $interval)"
echo "$profiled_prefix $profiler_duration $plain_duration \
    $(compute_duration_overhead $profiler_duration $plain_duration)"
