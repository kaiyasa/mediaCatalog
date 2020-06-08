
use strict;

package TableCache;

use Data::Dumper;

sub new {
    my $class = shift;
    my $info = shift;
    my $qName = shift;
    my $values = shift; # array ref
    my $self = {};

    bless($self, $class);

    $self->{dbinfo} = $info;
    $self->{queryName} = $qName;
    $self->{values} = $values;
#print "TableCache, table = $self->{dbinfo}->{table}, queryBy = $self->{queryName}, values = ", join(", ", @{$self->{values}}), "\n";
    return $self;
}

sub get {
    my ($self, $colName) = @_;

    if (!defined($self->{data})) {
        $self->fetch();
    }
    return $self->{data}->{$colName};
}

sub fetch {
    my ($self) = @_;

    my $stmt = $self->{dbinfo}->{queryBy}{$self->{queryName}}{stmt};

    $self->{data} = {};
    my $rc = $stmt->execute(@{ $self->{values} });
#print "TableCache, table = $self->{dbinfo}->{table}, row count = $rc, queryBy = $self->{queryName}, values = ", join(", ", @{$self->{values}}), "\n";
    # FIXME: check for no rows
    $self->{data} = $stmt->fetchrow_hashref();
#print "TableCache, table = $self->{dbinfo}->{table}, dump\n", Dumper($self->{data}), "\n";
}

1;
