package SQLColumnJoin;

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    $self->{values} = {};
    return $self;
}

sub step {
    my ($self, $value) = @_;
    $self->{values}->{$value} = 1;
}
sub finalize {
    my $self = shift;
    return join(", ", keys(%{$self->{values}}));
}

1;
