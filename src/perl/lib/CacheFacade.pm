
use strict;

package CacheFacade;

use TableCache;

sub new {
    my $class = shift;
    my $cachedb = shift;
    my $queryBy = shift;
    my $values = [ @_ ];
    my $self = {};
    my $ident = "ByIdentity";

    bless($self, $class);

#print "CacheFacade: queryBy = $queryBy, values = ", join(", ", @{$values}), "\n";
    $self->{file} = TableCache->new($cachedb->{fileInfo}, $queryBy, $values);
    if (!$self->isFound()) {
        return undef;
    }

    # now, populate the related info tables with id values
    $self->{anime} =
        TableCache->new($cachedb->{animeInfo}, $ident, [ $self->animeId() ]);
    $self->{grp} =
        TableCache->new($cachedb->{grpInfo}, $ident, [ $self->grpId() ]);
    $self->{episode} =
        TableCache->new($cachedb->{epInfo}, $ident, [ $self->epId() ]);
    $self->{dir} =
        TableCache->new($cachedb->{dirInfo}, $ident, [ $self->animeId() ]);

    return $self;
}

sub isFound() {
    my ($self) = @_;
    my $id = $self->fileId();
    return defined($id);
}

sub animeYear {
    my ($self) = @_;
    return $self->{anime}->get("animeYear");
}

sub animeType {
    my ($self) = @_;
    return $self->{anime}->get("animeType");
}

sub animeEpTotal {
    my ($self) = @_;
    return $self->{anime}->get("animeEpTotal");
}

sub animeSpecialEpTotal {
    my ($self) = @_;
    return $self->{anime}->get("animeSpecialEpTotal");
}

sub animeEpHighest {
    my ($self) = @_;
    return $self->{anime}->get("animeEpHighest");
}

sub animeNameEnglish {
    my ($self) = @_;
    return $self->{anime}->get("animeNameEnglish");
}

sub animeNameRomaji {
    my ($self) = @_;
    return $self->{anime}->get("animeNameRomaji");
}

sub animeNameKanji {
    my ($self) = @_;
    return $self->{anime}->get("animeNameKanji");
}

sub animeNameOther {
    my ($self) = @_;
    return $self->{anime}->get("animeNameOther");
}

sub animeLastUpdate {
    my ($self) = @_;
    return $self->{anime}->get("animeLastUpdate");
}

sub animeLastQuery {
    my ($self) = @_;
    return $self->{anime}->get("animeLastQuery");
}

sub animeCategory {
    my ($self) = @_;
    return $self->{anime}->get("animeCategory");
}

sub mediaDir {
    my ($self) = @_;
    return $self->{dir}->get("mediaDir");
}

sub fileId {
    my ($self) = @_;
    return $self->{file}->get("fileId");
}

sub animeId {
    my ($self) = @_;
    return $self->{file}->get("animeId");
}

sub epId {
    my ($self) = @_;
    return $self->{file}->get("epId");
}

sub grpId {
    my ($self) = @_;
    return $self->{file}->get("grpId");
}

sub fsize {
    my ($self) = @_;
    return $self->{file}->get("fsize");
}

sub fduration {
    my ($self) = @_;
    return $self->{file}->get("fduration");
}

sub fcrc32 {
    my ($self) = @_;
    return $self->{file}->get("fcrc32");
}

sub fmd5 {
    my ($self) = @_;
    return $self->{file}->get("fmd5");
}

sub fed2k {
    my ($self) = @_;
    return $self->{file}->get("fed2k");
}

sub fsha256 {
    my ($self) = @_;
    return $self->{file}->get("fsha256");
}

sub fLastUpdate {
    my ($self) = @_;
    return $self->{file}->get("fLastUpdate");
}

sub epSequence {
    my ($self) = @_;
    return $self->{episode}->get("epSequence");
}

sub epAirdate {
    my ($self) = @_;
    return $self->{episode}->get("epAirdate");
}

sub epName {
    my ($self) = @_;
    return $self->{episode}->get("epName");
}

sub epNameRomaji {
    my ($self) = @_;
    return $self->{episode}->get("epNameRomaji");
}

sub epNameKanji {
    my ($self) = @_;
    return $self->{episode}->get("epNameKanji");
}

sub epLastUpdate {
    my ($self) = @_;
    return $self->{episode}->get("epLastUpdate");
}

sub grpName {
    my ($self) = @_;
    return $self->{grp}->get("grpName");
}

sub grpShortName {
    my ($self) = @_;
    return $self->{grp}->get("grpShortName");
}

1;
