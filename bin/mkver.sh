

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
    local md5=NONE

    getPAR2ls "$fn" | grep -A5 -n "File Description packet" |
        sort -n |
        grep -v -- '--' |
        grep -v -- "    id=" |
        sed 's/[0-9]*[-:]//' |
        sed 's/^.*PAR 2.0 FileDesc.*$/FILE_PACKET/' |
        (
            while read line; do
                case "$line" in
                    md5=*) echo $line | cut -c5- | tr '[a-z]' '[A-Z]';;
                esac
            done
        )
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

for f in "$@"; do
    echo "Processing $f"
    makeVerifyFile "$f"
done
