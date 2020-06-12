#!/bin/bash
function cleanUp() {
    echo "Aborting..."
    if [ -n "$tempFile" -a -f "$tempFile" ]; then
        rm "$tempFile"
    fi
    exit 1
}

# On typical signals, let us clean up our temp files
trap cleanUp INT
trap cleanUp HUP

for dir in "$@"; do
    logFile="logs/${dir}.log"
    tempFile="$logFile.$$"
    if [ -d "$dir" -a ! -f "$logFile" ]; then
        echo "Verifying $dir"
        verifymedia "$dir" > "$tempFile" 2>&1
        mv "$tempFile" "$logFile"
    fi
    if [ -f "$logFile" ]; then
        errs="$(egrep 'WARNING:|MISSING:|MISMATCH:' "$logFile")" && echo "Errors in $dir: $errs"
    fi
done
echo "finished"
