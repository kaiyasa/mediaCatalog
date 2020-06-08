
dbname=$1

[ -f "$dbname" ] || {
    echo "no such file: $dbname"
    exit 1
}

# add info for the multiple episode files for
# improved warnings about missing eps
fixmultis() {
    local sql="select epSequence, fileid from episode e, mediafile m where e.epid = m.epid and epSequence like '%-%';"
    while IFS='-' read s e fid; do
        fmt="%0${#s}g"
        for ep in $(seq -f "$fmt" $s $e); do
            echo "INSERT OR REPLACE INTO mediaepisodes (fileId, epSequence) VALUES ($fid, '$ep');"
        done
    done < <(sqlite3 "$dbname" "$sql" | tr \| -)
}

sqlite3 "$dbname" <<SQL
DROP TABLE IF EXISTS nomediafile;
DROP TABLE IF EXISTS medianofile;
DROP TABLE IF EXISTS mediaepisodes;

CREATE TABLE medianofile (
    animeId INTEGER,
    grpId INTEGER,
    epSequence VARCHAR2,
    PRIMARY KEY (animeId, grpId, epSequence)
);

CREATE TABLE mediaepisodes (
    fileId INTEGER,
    epSequence VARCHAR2,
    PRIMARY KEY (fileId, epSequence)
);

$(fixmultis)
SQL

