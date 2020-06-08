#!/bin/bash

tmpfile=$HOME/tmp/check-$$.sfv

getCRC() {
    echo "$1" | sed 's/.*[[(]\(........\)[])].*/\1/'
}

rc=0
for i in "$@"; do
    if [ -f "$i" ]; then
        size=$(du -s "$i")
        crc=$(getCRC "$i")

        if [ -n "$crc" -a "$i" != "$crc" ]; then
            echo "$(basename "$i") $crc" > $tmpfile
            cfv -p "$(dirname "$i")" -q -f $tmpfile 2> /dev/null && {
                echo "PASSED: $i"
            } || {
                echo "FAILED: $i"
                echo "FAILED: $i" 1>&2
                rc=1
            }
            rm $tmpfile
        fi
    else
        echo "$i is not a file"
    fi
done
exit $rc
