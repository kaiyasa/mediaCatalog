#!/bin/bash

cd "${1:-.}"
find . -maxdepth 1 -iname '*.par2' -a ! -iname '*40.par2' | while read fn; do
    b=$(basename "$fn" .par2)
    if [ -e "$b" ]; then
        rp=0
        [ -e "$b.1" ] && rp=1
        if par2repair "$fn"; then
            if [ -e "$b.1" -a $rp -eq 0 ]; then
                if [ -L "$b.1" ]; then
                    echo "removing symlink & referenced file: $b.1"
                    r=$(readlink "$b.1")
                    rm -fv "$r"
                else
                    echo "removing $b.1"
                fi
                rm -fv "$b.1"
            else
                [ $rp -eq 1 ] && {
                    echo "WARNING: $b.1 pre-existed, check for a .2"
                }
            fi
        else
            echo "par2repair FAILED -- restoring, if possible"
            if [ -e "$b.1" ]; then
                if [ "$rp" -eq 0 ]; then
                    mv -iv "$b.1" "$b"
                else
                    echo "$b.1 existed before repair"
                fi
            fi
        fi
    else
        echo "WARNING: $b missing; unable to check/repair"
    fi
done
