
package VerifyFile;

sub new {
    my $class = shift;
    my $self  = {};

    $self->{version} = 1;
    $self->{tstamp} = 'something';
    $self->{keyedValues} = {};
    $self->{size} = 0;
    $self->{changed} = 0;
    $self->{filename} = undef;
    $self->{backingFile} = undef;

    bless($self, $class);
    return $self;
}

sub ed2k {
    my $self = shift;
    if (@_) { $self->setOption("ed2k", shift); }
    return $self->getOption("ed2k");
}

sub md5 {
    my $self = shift;
    if (@_) { $self->setOption("MD5", shift); }
    return $self->getOption("MD5");
}

sub crc32 {
    my $self = shift;
    if (@_) { $self->setOption("CRC32", shift); }
    return $self->getOption("CRC32");
}

sub version {
    my $self = shift;
    if (@_) { ($self->{version}) = shift; }
    return $self->{version};
}

sub timestamp {
    my $self = shift;
    if (@_) { ($self->{tstamp}) = shift; }
    return $self->{tstamp};
}

sub size {
    my $self = shift;
    if (@_) { ($self->{size}) = shift; }
    return $self->{size};
}

sub filename {
    my $self = shift;
    if (@_) { ($self->{filename}) = shift; }
    return $self->{filename};
}


sub hasOption {
    my ($self, $key) = @_;
    return defined($self->{keyedValues}{$key});
}

sub getOption {
    my ($self, $key) = @_;
    if (!defined($self->{keyedValues}{$key})) {
        return undef;
    }
    return $self->{keyedValues}{$key};
}

sub getOptionKeys {
    my $self = shift;
    return keys( %{ $self->{keyedValues} } );
}

sub setOption {
    my ($self, $key, $value) = @_;
    if (defined($self->{keyedValues}{$key})) {
        if ($self->{keyedValues}{$key} ne $value) {
            $self->{keyedValues}{$key} = $value;
            $self->{changed} = 1;
        }
    } else {
        $self->{keyedValues}{$key} = $value;
        $self->{changed} = 1;
    }
    return $value;
}

sub isChanged() {
    my $self = shift;
    return $self->{changed} == 1;
}

sub backingFile {
    my ($self) = @_;
    return $self->{backingFile};
}

sub load {
    my ($self, $filename) = @_;
    my $text = do { local( @ARGV, $/ ) = $filename ; <> } ;
    chomp($text);
    my @parts = split(/\|/, $text);
    
    $self->{version} = $parts[0] =~ /\w+=(\w+)/mg;
    $self->{tstamp} = $parts[1];
    %{ $self->{keyedValues} } = $parts[2] =~ /(\w+)=(\w+)/mg ;
    $self->{size} = $parts[3];
    $self->{filename} = $parts[4];
    $self->{changed} = 0;
    $self->{backingFile} = $filename;
}

# return 0 = can't save
# return 1 = saved
# return -1 = error trying to save
sub save {
    my ($self) = @_;

    if (!defined($self->{backingFile})) {
        return 0;
    }

    # build the data
    my @po;
    foreach my $key (sort keys %{$self->{keyedValues}}) {
        push(@po, "$key=$self->{keyedValues}{$key}");
    }
    my $data = "v=$self->{version}|" .
               "$self->{tstamp}|" .
               join(" ", @po) . "|" .
               "$self->{size}|" .
               "$self->{filename}";

    # crazy and semi-paranoid .ver file updating
    my $error = 0;
    open(VER, ">$self->{backingFile}.new") or $error=1;
    print VER "$data\n" or $error=1 unless $error;
    close(VER) or $error=1 unless $error;
    rename("$self->{backingFile}.new","$self->{backingFile}")
        or $error=1 unless $error;
    unlink("$self->{backingFile}.new") if $error;
    return $error ? -1 : 1;
}

1;
