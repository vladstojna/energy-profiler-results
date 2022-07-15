#!/usr/bin/env bash

function echoerr
{
    printf "%s\n" "$*" >&2
}

files=( $@ )
if [[ "${#files[@]}" -lt 2 ]]; then
    echoerr "Usage: $0 <file> <file...>"
    exit 1
fi

# eliminate last line from first file
tac "${files[0]}" | tail -n +2 | tac

# eliminate first two lines and last line from intermediate files
for ix in $( seq 1 $((${#files[@]} - 2)) ); do
    f=${files[ix]}
    tail -n +3 "$f" | tac | tail -n +2 | tac
done

# eliminate first two lines from last file
tail -n +3 "${files[-1]}"
