

makeVerifyLine() {
    local fn=$1
    shift
    local hashes="$@"
    local size=$(du -bL "$fn" | cut -f1)
    local tstamp=$(date -r "$fn" -Iseconds)

    echo "v=1|$tstamp|$hashes|$size|"
}

getVerifyHash() {
    local hash=$1
    local verify=$2
    local hashes=$(echo "$2" | cut -d\| -f3)
    set -- $hashes
    local nr=$#

    while [ $nr -gt 0 ]; do
        local name=$(echo $1 | cut -d= -f1)
        if [ "$hash" = "$name" ]; then
            echo $1 | cut -d= -f2
            return 0
        fi
        shift
        ((--nr))
    done
    echo NONE
    return 1
}

setVerifyHash() {
    local hash=$1
    local value=$2
    local verify=$3

    local hashes
    local found=0

    set -- $(echo "$verify" | cut -d\| -f3)
    local nr=$#

    while [ $nr -gt 0 ]; do
        local name=$(echo $1 | cut -d= -f1)
        if [ "$hash" = "$name" ]; then
            hashes="$hashes ${hash}=$value"
            found=1
        else
            hashes="$hashes $1"
        fi
        ((--nr))
        shift
    done
    if [ $found -eq 0 ]; then
       hashes="$hashes ${hash}=$value"
    fi

    local tstamp=$(echo "$verify" | cut -d\| -f2)
    local fsize=$(echo "$verify" | cut -d\| -f4)
    echo "v=1|$tstamp|"${hashes}"|$fsize"
}


getPAR2ls() {
    [ -f "$1.par2" ] && {
        par2ls -v "$1.par2"
    }
}

getPAR2md5() {
    local fn=$1
    local bn=$(basename "$1")

    while read line; do
        if [ "$line" = "name=$bn" ]; then
            while read line; do
                if [ "${line:0:4}" = "md5=" ]; then
                    tr 'a-z' 'A-Z' <<<"${line:4}"
                    return
                fi
            done
        fi
    done < <(getPAR2ls "$fn" | grep -A5 "File Description packet")
}

makeHashes() {
    local fn=$1
    local size=$(du -bL "$fn" | cut -f1)
    local quick

    local hashes=$(jacksum -X -a crc32+md5+ed2k -F "CRC32=#CHECKSUM{0} MD5=#CHECKSUM{1} ed2k=#CHECKSUM{2}" "$fn")
    if [ "$size" -gt 16384 ]; then
        quick=$(dd if="$fn" bs=16k count=1 2> /dev/null | md5sum - | cut -c1-32 | tr '[a-z]' '[A-Z]')
        hashes="$hashes MD5_16k=$quick"
    fi
    echo $hashes
}

makeVerifyFile() {
    local fn=$1
    local md5

    # if file exists with no verify counterpart
    if [ -f "$fn" -a ! -f "$fn.ver" ]; then
        # create the verify line itself
        verify=$(makeVerifyLine "$fn" $(makeHashes "$fn"))
        md5=$(getVerifyHash MD5 "$verify")

        # fetch the MD5 in its par2 file
        if [ -f "$fn.par2" ]; then
            local par2md5=$(getPAR2md5 "$fn") && {

            # sanity check catch any corruption
            if [ "$md5" != "$par2md5" ]; then
                echo "WARNING: MD5/PAR2 mismatch: $fn"
                verify=$(setVerifyHash MD5 $par2md5 "$verify")
            fi
        }
        fi

        echo "$verify" > "$fn.ver"
    fi
}



getCRC() {
    echo "$1" | sed 's/.*[[(]\([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]\)[])].*/\1/'
}

makeRecoveryFile() {
    local b=$(rev <<<"$1" | cut -d. -f2- | rev)
    local GLOBIGNORE='*.ver:*.par2'
    par2create -q -q -b4000 -r1 -n1 "$1".par2 "$b"*
}

checkCRC() {
    local fn=$1
    local expect=$2

    makeVerifyFile "$i"
    local verify=$(cat "$fn.ver")
    local crc=$(getVerifyHash CRC32 "$verify")

    [ "$crc" = "$expect" ]
}

checkMD5s() {
    local fn=$1
    local verify=$(cat "$fn.ver")
    local par2md5=$(getPAR2md5 "$fn")
    local md5=$(getVerifyHash MD5 "$verify")

    if [ "$md5" != "$par2md5" ]; then
        echo "WARNING: MD5/par2 mismatch"
        return 1
    fi
    return 0
}

getFilesWithCRC() {
    local fn

    for fn in "$@"; do
        crc=$(getCRC "$fn")
        if [ -n "$crc" -a "$crc" != "$fn" ]; then
            echo -en $crc"\t"
            echo "$fn"
        else
            echo "No CRC, skipping $fn"
        fi
    done
}


getSFVMappings() {
    for sfv in *{SFV,sfv}; do
        [ -f "$sfv" ] && {
            echo "Processing $sfv" 1>&2
            grep -v \; "$sfv" | sed 's///g' | while read line; do
                l=$(expr $(expr length "$line") - 7)
                crc=$(echo -n "$line" | cut -c${l}-$(expr $l + 7))
                fn=$(echo -n "$line" | cut -c1-$(expr $l - 2))
                ofn=$fn
                # is it not present?
                if [ ! -f "$fn" ]; then
                    # change spaces to underscore and try again
                    fn=$(echo "$fn" | sed 's/ /_/g')
                    if [ ! -f "$fn" ]; then
                        # change uppercase to lowercase and try again
                        fn=$(echo "$ofn" | tr '[a-z]' '[A-Z]')
                        if [ ! -f "$fn" ]; then
                            # combine the two previous checks and try again
                            fn=$(echo "$fn" | sed 's/ /_/g')
                            if [ ! -f "$fn" ]; then
                                # screw it! it isn't a typical mangling
                                continue
                            fi
                        fi
                    fi
                fi
                echo -en $crc"\t"
                echo "$fn"
            done
        }
    done
}


rc=0
for i in "$@"; do
    if [ -f "$i" ]; then
        echo -ne "hashing : $i\r"
        makeVerifyFile "$i"
        echo     "par2gen : $i"
        makeRecoveryFile "$i" && {
            checkMD5s "$i" || rc=1
        }
    fi
done
exit $rc
