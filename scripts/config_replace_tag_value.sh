#!/usr/bin/env bash

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <tag> <new value> [config]"
    exit 1
fi

sed 's|<'"$1"'>.*</'"$1"'>|<'"$1"'>'"$2"'</'"$1"'>|g' $3
