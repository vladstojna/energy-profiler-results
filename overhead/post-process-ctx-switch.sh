#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

args=( $@ )
if [[ "${#args[@]}" -lt 2 ]]; then
    echoerr "Usage: <files> | $0 <timeprinter_start> <timeprinter_end>"
    exit 1
fi

results_scripts="$(dirname $0)/../scripts"

timeprinter_start=( ${args[0]} $((${args[0]} + 1)) )
timeprinter_end=( ${args[1]} $((${args[1]} + 1)) )

start_durations=( )
end_durations=( )
while read -r; do
    first_time=$($results_scripts/extract_time.py --count "${timeprinter_start[0]}" "$REPLY")
    second_time=$($results_scripts/extract_time.py --count "${timeprinter_start[1]}" "$REPLY")
    start_durations+=( $(( $second_time - $first_time )) )

    first_time=$($results_scripts/extract_time.py --count "${timeprinter_end[0]}" "$REPLY")
    second_time=$($results_scripts/extract_time.py --count "${timeprinter_end[1]}" "$REPLY")
    end_durations+=( $(( $second_time - $first_time )) )
done

python3 -c "lst = [int(x) for x in '${start_durations[*]}'.split(' ')]; print('start', sum(lst) / len(lst))"
python3 -c "lst = [int(x) for x in '${end_durations[*]}'.split(' ')]; print('end', sum(lst) / len(lst))"
