
use strict;
use SQLite;
use CacheFacade;


package CacheDB;

use Data::Dumper;

sub new {
    my ($class, $dbfile) = @_;
    my $self = {};
    my $createFlag = 0;

    if ( ! -f $dbfile ) {
        $createFlag = 1;
    }
    if ($self->{dbh} = SQLite->connect( "dbi:SQLite:dbname=$dbfile", '', '',
            { RaiseError  => 0, PrintError  => 0, })
        ) {
    } else {
        die "unable to connect/create SQLite database: $dbfile";
    }

    bless($self, $class);

    if ($createFlag) {
        $self->createTables();
    }
    $self->createStatements();
    return $self;
}

sub findByFid {
    my ($self, $key) = @_;
    if (!defined($key)) { return undef; }
#print "by fid = $key\n";
    return CacheFacade->new($self, "ByIdentity", $key);
}

sub findByMD5 {
    my ($self, $key) = @_;
    if (!defined($key)) { return undef; }
#print "by md5 = $key\n";
    return CacheFacade->new($self, "ByMD5", $key);
}

sub findByCRC32 {
    my ($self, $key, $size) = @_;
    if (!defined($key) || !defined($size)) { return undef; }
#print "by crc32 = $key, size = $size\n";
    return CacheFacade->new($self, "ByCRC32", $key, $size);
}

sub findDirName {
    my ($self, $key) = @_;
    my $tc = TableCache->new($self->{dirInfo}, "ByIdentity", [ $key ] );
    return $tc->get("mediaDir");
}

sub findGroupName {
    my ($self, $key) = @_;
    my $tc = TableCache->new($self->{grpInfo}, "ByIdentity", [ $key ] );
    return $tc->get("grpShortName");
}

sub findMissingFilesByGroup {
    my ($self, $animeId, $grpId, $maxEpNo) = @_;

    my $stmt = $self->{findMissingFilesByGroup};
    if (!defined($stmt)) {
        my $sqlStmt = "
SELECT value
  FROM numberSequence LEFT OUTER JOIN (
    SELECT e.epSequence AS epSequence
      FROM mediafile m, episode e
     WHERE m.epId = e.epId
           AND m.animeId = ?
           AND m.grpId = ?
   UNION
    SELECT e.epSequence AS epSequence
      FROM mediafile m, mediaepisodes e
     WHERE m.fileId = e.fileId
           AND m.animeId = ?
           AND m.grpId = ?
   UNION
    SELECT m.epSequence AS epSequence
      FROM medianofile m
     WHERE m.animeId = ?
           AND m.grpId = ?
  ) feps
    ON numberSequence.value = feps.epSequence
     WHERE numberSequence.value <= ?
           AND feps.epSequence is NULL;
";
        $stmt = $self->{dbh}->prepare($sqlStmt) or die "findMissing failed: $!";
        $self->{findMissingFilesByGroup} = $stmt;
    }

    my $data = [];
    my $value;
    $stmt->execute($animeId, $grpId, $animeId, $grpId,
                   $animeId, $grpId, $maxEpNo);
    while ($value = $stmt->fetchrow_arrayref()) {
        push(@{$data}, @{$value}[0]);
    }
    return $data;
}

sub createTables() {
    my $self = shift;

    my $sqlStmt = "
CREATE TABLE anime (
    animeId INTEGER PRIMARY KEY,
    animeYear VARCHAR2,
    animeType VARCHAR2,
    animeEpTotal INTEGER,
    animeSpecialEpTotal INTEGER,
    animeEpHighest INTEGER,
    animeNameEnglish VARCHAR2,
    animeNameRomaji VARCHAR2,
    animeNameKanji VARCHAR2,
    animeNameOther VARCHAR2,
    animeLastUpdate INTEGER,
    animeLastQuery INTEGER,
    animeCategory VARCHAR2 
);
";
    $self->{dbh}->do($sqlStmt) or die;

    $sqlStmt = "
CREATE TABLE dirname (
    animeId INTEGER PRIMARY KEY,
    mediaDir VARCHAR2
);
";
    $self->{dbh}->do($sqlStmt) or die;

    $sqlStmt = "
CREATE TABLE mediafile (
    fileId INTEGER PRIMARY KEY,
    animeId INTEGER,
    epId INTEGER,
    grpId INTEGER,
    fsize INTEGER,
    fduration INTEGER,
    fcrc32 VARCHAR2,
    fmd5 VARCHAR2,
    fed2k VARCHAR2,
    fsha256 VARCHAR2,
    fLastUpdate INTEGER
);
";
    $self->{dbh}->do($sqlStmt) or die;

    $sqlStmt = "
CREATE TABLE episode (
    epId INTEGER PRIMARY KEY,
    animeId INTEGER,
    epSequence VARCHAR2,
    epAirdate INTEGER,
    epName VARCHAR2,
    epNameRomaji VARCHAR2,
    epNameKanji VARCHAR2,
    epLastUpdate INTEGER
);
";
    $self->{dbh}->do($sqlStmt) or die;

    $sqlStmt = "
CREATE TABLE grp (
    grpId INTEGER PRIMARY KEY,
    grpName VARCHAR2,
    grpShortName VARCHAR2
);
";
    $self->{dbh}->do($sqlStmt) or die;

    $sqlStmt = "
CREATE TABLE NumberSequence (
    value INTEGER PRIMARY KEY
);
";
    $self->{dbh}->do($sqlStmt) or die;
    # now, populate it up to 1000
    foreach my $i (1..1000) {
        $self->{dbh}->do("INSERT INTO NumberSequence VALUES ($i);") or die;
    }

    $sqlStmt = "
CREATE TABLE medianofile (
    animeId INTEGER,
    grpId INTEGER,
    epSequence VARCHAR2,
    PRIMARY KEY (animeId, grpId, epSequence)
);
";
    $self->{dbh}->do($sqlStmt) or die;

    $sqlStmt = "
CREATE TABLE mediaepisodes (
    fileId INTEGER,
    epSequence VARCHAR2,
    PRIMARY KEY (fileId, epSequence)
);
";
    $self->{dbh}->do($sqlStmt) or die;
}

sub createStatements {
    my ($self) = @_;

    $self->{grpInfo} = {
          table => 'grp',
         idExpr => 'grpId = ?',
        columns => ['grpName', 'grpShortName'],
           keys => ['grpId'],
        queryBy => {}
    };
    $self->{grpInfo}->{select} = $self->generateSelectStmt($self->{grpInfo});
    $self->{grpInfo}->{insert} = $self->generateInsertStmt($self->{grpInfo});
    $self->{grpInfo}->{update} = $self->generateUpdateStmt($self->{grpInfo});
    $self->generateQueryByStmts($self->{grpInfo});

    $self->{animeInfo} = {
          table => 'anime',
         idExpr => 'animeId = ?',
        columns => ['animeYear', 'animeType', 'animeEpTotal', 'animeEpHighest',
                    'animeNameRomaji', 'animeNameKanji', 'animeNameEnglish',
                    'animeNameOther', 'animeLastUpdate', 'animeCategory'],
           keys => ['animeId'],
        queryBy => {}
    };
    $self->{animeInfo}->{select} = $self->generateSelectStmt($self->{animeInfo});
    $self->{animeInfo}->{insert} = $self->generateInsertStmt($self->{animeInfo});
    $self->{animeInfo}->{update} = $self->generateUpdateStmt($self->{animeInfo});
    $self->generateQueryByStmts($self->{animeInfo});

    $self->{dirInfo} = {
          table => 'dirname',
         idExpr => 'animeId = ?',
        columns => ['mediaDir'],
           keys => ['animeId'],
        queryBy => {}
    };
    $self->{dirInfo}->{select} = $self->generateSelectStmt($self->{dirInfo});
    $self->{dirInfo}->{insert} = $self->generateInsertStmt($self->{dirInfo});
    $self->{dirInfo}->{update} = $self->generateUpdateStmt($self->{dirInfo});
    $self->generateQueryByStmts($self->{dirInfo});

    $self->{fileInfo} = {
          table => 'mediafile',
         idExpr => 'fileId = ?',
        columns => ['animeId', 'epId', 'grpId', 'fsize', 'fduration',
                    'fcrc32', 'fmd5', 'fed2k', 'fsha256', 'fLastUpdate'],
           keys => ['fileId'],
        queryBy => { ByMD5    => { columns => 'fmd5',
                                      expr => 'fmd5 = ?' },
                     ByED2K   => { columns => 'fed2k fsize',
                                      expr => 'fed2k = ? AND fsize = ?' },
                     ByCRC32  => { columns => 'fcrc32 fsize',
                                      expr => 'fcrc32 = ? AND fsize = ?' },
                     BySHA256 => { columns => 'fsha256',
                                      expr => 'fsha256 = ?' }
                   }
    };
    $self->{fileInfo}->{select} = $self->generateSelectStmt($self->{fileInfo});
    $self->{fileInfo}->{insert} = $self->generateInsertStmt($self->{fileInfo});
    $self->{fileInfo}->{update} = $self->generateUpdateStmt($self->{fileInfo});
    $self->generateQueryByStmts($self->{fileInfo});

    $self->{epInfo} = {
          table => 'episode',
         idExpr => 'epId = ?',
        columns => ['animeId', 'epSequence', 'epAirdate',
                    'epName', 'epNameRomaji', 'epNameKanji', 'epLastUpdate'],
           keys => ['epId'],
        queryBy => {}
    };
    $self->{epInfo}->{select} = $self->generateSelectStmt($self->{epInfo});
    $self->{epInfo}->{insert} = $self->generateInsertStmt($self->{epInfo});
    $self->{epInfo}->{update} = $self->generateUpdateStmt($self->{epInfo});
    $self->generateQueryByStmts($self->{epInfo});
}

sub generateInsertStmt {
    my ($self, $info) = @_;
    my @columns = ( @{$info->{columns}}, @{$info->{keys}} );

    my $markers = "?";
    for (2..@columns) {
        $markers = "${markers}, ?";
    }
    my $list = join(", ", @columns);
    my $sql = sprintf("INSERT INTO %s (%s) VALUES (%s)",
                       $info->{table}, $list, $markers);

#print "INSERT = $sql\n";
    my $stmt = $self->{dbh}->prepare($sql) or die
        or die "db prepare failed: ", $self->{dbh}->errstr();
    return $stmt;
}

sub generateUpdateStmt {
    my ($self, $info) = @_;

    my $list = join(" = ?, ", @{ $info->{columns} });
    my $sql = sprintf("UPDATE %s SET %s = ? WHERE %s",
                       $info->{table}, $list, $info->{idExpr});
#print "UPDATE = $sql\n";
    my $stmt = $self->{dbh}->prepare($sql) or die
        or die "db prepare failed: ", $self->{dbh}->errstr();
    return $stmt;
}

sub generateSelectStmt {
    my ($self, $info) = @_;
    my @columns = ( @{$info->{keys}}, @{$info->{columns}} );

    my $list = join(", ", @columns);
    my $sql = sprintf("SELECT %s FROM %s WHERE %s",
                      $list, $info->{table}, $info->{idExpr});
#print "SELECT = $sql\n";
    my $stmt = $self->{dbh}->prepare($sql)
        or die "db prepare failed: ", $self->{dbh}->errstr();
    return $stmt;
}

sub generateQueryByStmts {
    my ($self, $info) = @_;

    # build the rest of the queries
    my @names = keys( %{$info->{queryBy}} );
    my @columns = ( @{$info->{keys}}, @{$info->{columns}} );
    my $list = join(", ", @columns);
    my $table = $info->{table};

    foreach my $query (@names) {
        my $sql = sprintf("SELECT %s FROM %s WHERE %s",
                          $list, $table, $info->{queryBy}{$query}{expr});
#print "QueryBy SELECT ($query) = $sql\n";
        $info->{queryBy}{$query}{stmt} = $self->{dbh}->prepare($sql)
            or die "db prepare failed for $query: ", $self->{dbh}->errstr();
    
    } # build the 'identity' on from table info
    $info->{queryBy}{ByIdentity} = {};
    $info->{queryBy}{ByIdentity}{columns} = $info->{keys};
    $info->{queryBy}{ByIdentity}{expr} = $info->{idExpr};
    $info->{queryBy}{ByIdentity}{stmt} = $info->{select};
    $info->{queryBy}{ByIdentity}{stmt}->execute(1);
}

sub addAniDBFile() {
    my ($self, $record) = @_;
    my $fields = $self->parseAniDBFile($record);
    $self->addAnime($fields);
    $self->addGroup($fields);
    $self->addEpisode($fields);
    $self->addFile($fields);
    return $fields->{fileId};
}

sub parseAniDBFile() {
    my ($self, $record) = @_;
    my @keys = (
        "fileId", "animeId", "epId", "grpId", "fsize",
        "fed2k", "fmd5", "fsha256", "fcrc32", "fduration",
        "epAirdate", "animeEpTotal", "animeEpHighest", "animeYear",
        "animeType", "animeCategory", "animeNameRomaji",
        "animeNameKanji", "animeNameEnglish", "animeNameOther",
        "epSequence", "epName", "epNameRomaji", "epNameKanji",
        "grpName", "grpShortName", "animeLastUpdate"
    );

    my @cleanUpKeys = (
        "animeNameRomaji", "animeNameEnglish", "epName", "epNameRomaji",
        "animeNameKanji", "epNameKanji", "grpShortName"
    );

    my @normalizeKeys = (
        "fed2k", "fmd5", "fsha256", "fcrc32"
    );

    my @values = split(/\|/, $record);
    my $fields = {};
    
    my $i = 0;
    foreach my $key (@keys) {
        if ($values[$i] eq "") {
            $fields->{$key} = undef;
        } else {
            $fields->{$key} = $values[$i];
        }
        ++$i;
    }

    foreach my $key (@cleanUpKeys) {
        $fields->{$key} =~ s/`/'/g
            if defined($fields->{$key});
    }
    foreach my $key (@normalizeKeys) {
        $fields->{$key} = uc $fields->{$key}
            if defined($fields->{$key});
    }
    return $fields;
}

sub addRecord {
    my ($self, $dbinfo, $data) = @_;
    my @columns = ( @{$dbinfo->{columns}}, @{$dbinfo->{keys}} );

    my @values = ();
    foreach my $key (@columns) {
        push(@values, $data->{$key});
    }

    $dbinfo->{insert}->execute(@values)
                or $dbinfo->{update}->execute(@values);
}

sub addAnime {
    my ($self, $data) = @_;
    return $self->addRecord($self->{animeInfo}, $data);
}

sub addGroup {
    my ($self, $data) = @_;
    return $self->addRecord($self->{grpInfo}, $data);
}

sub addEpisode {
    my ($self, $data) = @_;

    if ($data->{epSequence} =~ /^[0-9]+-[0-9]+/) {
        my @r = split('-', $data->{epSequence});
        $self->addFileEpisodes($r[0], $r[1], $data);
    }
    return $self->addRecord($self->{epInfo}, $data);
}

sub addFileEpisodes {
    my ($self, $begin, $end, $data) = @_;

    my $stmt = $self->{insertFileEpisodes};
    if (!defined($stmt)) {
        my $sqlStmt = "
INSERT OR REPLACE INTO mediaepisodes
    (fileId, epSequence) VALUES (?, ?);
}
";
        $stmt = $self->{dbh}->prepare($sqlStmt) or die;
        $self->{insertFileEpisodes} = $stmt;
    }

    #my $w = length($begin) < length($end) ? length($end) : length($begin);
    my $w = length($begin);
    if ($begin < $end) {
        foreach my $ep (${begin}..${end}) {
            my $fep = sprintf("%0${w}g", $ep);
            print "$data->{fileId}, $fep -- $begin, $end\n";
            $stmt->execute($data->{fileId}, $fep) or die;
        }
    }
}

sub addFile {
    my ($self, $data) = @_;
    return $self->addRecord($self->{fileInfo}, $data);
}

# FIXME: change all add<X> to accept an array (ordered: keys+columns) or hash
sub addDirName {
    my ($self, $id, $dir) = @_;
    my $data = { animeId => $id, mediaDir => $dir };
    return $self->addRecord($self->{dirInfo}, $data);
}

1;
