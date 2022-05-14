#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

if [[ -z "$EP_PREFIX" ]]; then
    echoerr "Environment variable EP_PREFIX not set"
    exit 1
fi

mkdir -p "$(dirname $0)/../post-processed"

scripts="$EP_PREFIX/scripts"

for f in $(ls $(dirname $0)/*.json); do
    base=$(basename $f)
    no_ext="${base%.*}"
    for op in sum avg; do
        cat "$f" | \
            $scripts/remove_empty.py 2> /dev/null | \
            $scripts/compact_total_energy.py 2> /dev/null | \
            $scripts/compact_reduce_executions.py --op "$op" \
            > "$(dirname $0)/../post-processed/${no_ext}.${op}.json"
    done
done
