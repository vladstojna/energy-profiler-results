#!/bin/env sh

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <file> <field> <separator>"
    echo "Separator is ; by default"
    exit 1
fi

if [[ $# -gt 2 ]]; then
    separator="$3"
else
    separator=";"
fi

file="$1"
field="$2"
column="$(head -n 1 "$file" | tr , '\n' | grep -n "^${field}$" | cut -f1 -d:)"

awk -v col="$column" -F '"*,"*' '{print $col}' "$file" | tail -n +2 | paste -s -d"$separator" -
