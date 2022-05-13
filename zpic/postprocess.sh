#!/usr/bin/env bash

mkdir -p "$(dirname $0)/../post-processed"

scripts="$EP_PREFIX/scripts"

for f in $(ls *.json); do
    base="${f%.*}"
    for op in sum avg; do
        cat "$f" | \
            $scripts/remove_empty.py 2> /dev/null | \
            $scripts/compact_total_energy.py 2> /dev/null | \
            $scripts/compact_reduce_executions.py --op "$op" \
            > "$(dirname $0)/../post-processed/${base}.${op}.json"
    done
done
