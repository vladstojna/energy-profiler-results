#!/usr/bin/env bash

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <new target> [config]"
    exit 1
fi

sed '/<section/s|target="[^".]*"|target="'"$1"'"|g' $2
