
use strict;

package AniDBRequest;

use POSIX qw(floor);

sub new {
    my ($class, $user, $passwd, $options) = @_;
    my $self = {};

    bless($self, $class);
    $self->{userid} = $user;
    $self->{passwd} = $passwd;
    $self->{delay} = 0;
    $self->{lastRequestTime} = 0;
    $self->{requestCount} = 0;
    $self->{blast} = 1;
    $self->{fake} = 1;
    $self->{anidbClient} = "java -jar anidbClient.jar";
    $self->{hostname} = "api.anidb.info";
    $self->{port} = "9000";
    $self->{localport} = "45678";
    $self->{interrupt} = 0;

    if (defined($options)) {
        while (my ($key, $value) = each(%{$options})) {
            $self->{$key} = $value;
        }
    }
    return $self;
}

sub interrupt {
    my ($self) = @_;
    $self->{interrupt} = 1;
}

sub login {
    my ($self) = @_;

    ++$self->{login_attempt};
    my $client="kenokitools";
    my $clientver="001";
    my $request="AUTH user=$self->{userid}&pass=$self->{passwd}&protover=3&client=${client}&clientver=${clientver}&enc=utf8";

    if ($self->waitTime() == 0) {
        print "\nLogging into AniDB\n\n";
    }
    my ($code, $msg, $data) = $self->sendRequest($request, "Logging In");
    if ($code >= 200 && $code < 300) {
        my ($value, $rmsg) = $msg =~ /(\w+) (.*)/mg;
        $self->session($value);
        print "  AniDB: INFO- $rmsg ($code, s=$value)\n";
    } else {
        die "Login failed: $msg (code = $code)\n";
    }
    --$self->{login_attempt};
    if ($self->{delay} == 0 && !$self->{blast}) {
        $self->waitTime(4);
    }
}

sub logout {
    my ($self) = @_;
    my $session = $self->session();

    if (!defined($session)) {
        return;
    }

    print "Logging out of AniDB\n\n";
    if (!$self->{blast}) {
        $self->waitTime(2);
    }
    my $request = "LOGOUT ";
    my ($code, $msg, $data) = $self->sendRequest($request, "Logging out");
    if ($code >= 200 && $code < 300) {
        print "\n  AniDB: INFO- $msg ($code, s=$session)\n";
    } else {
        print "\n  AniDB: ERROR- $msg ($code)\n";
    }
}

sub session {
    my $self = shift;
    if (@_) { ($self->{sessionId}) = shift; }
#print "session value = $self->{sessionId}\n";
    return $self->{sessionId};
}

sub sendRequest {
    my ($self, $request, $stMsg) = @_;
    my ($code, $msg, $data);
    my $session;

    foreach my $retry (1..5) {
        # add session info to request
        $self->preSend($stMsg);

        if ($self->isLoggedIn()) {
            $session = "s=".$self->session();
            if ( $request =~ m/=/ ) {
                $session = "&".${session};
            }
        }

        ($code, $msg, $data) = $self->anidbUDPCall("${request}${session}");
        $self->postSend();

        if ($code == 501 || $code == 506) {
            print "  ERROR: retry $retry; $msg ($code)\n";
            # seems we got booted
            $self->session(undef);
            next;
        } elsif ($code == 399 || $code == 649) {
            print "  ERROR: retry $retry; $msg ($code)\n";
            next;
        } else {
            return ($code, $msg, $data);
        }
    }

    # complete failure, report last known error
    return ($code, $msg, $data);
}

sub preSend() {
    my ($self, $msg) = @_;

    if (!$self->isLoggedIn()) {
        $self->login() unless $self->{login_attempt};
    }

    $msg = "Querying AniDB" unless defined($msg);
    if (!$self->{blast}) {
        my @remaining = (0..$self->waitTime());
        while (@remaining > 0 && !$self->{interrupt}) {
            $self->progress($msg, pop(@remaining));
            sleep(1);
        }
    }
}

sub postSend() {
    my $self = shift;

    $self->{lastRequestTime} = time();
    ++$self->{requestCount};
    if (!$self->{blast} && $self->{requestCount} > 16) {
        $self->waitTime( $self->{delay} + 2);
    }
}

sub progress {
    local $| = 1;
    my $self = shift;
    my ($msg, $secs) = @_;

    my $s = "   $msg - Throttling anidb for $secs seconds \r";
    if ($secs eq 0) {
        foreach my $i (1..length($s)) {
            print " ";
        }
        print "\r";
    } else {
        print "$s";
    }
}

sub anidbUDPCall {
    my ($self, $request) = @_;

print "req = $request\n";
    if (!$self->{blast} && time() - $self->{lastRequestTime} < 2) {
        foreach my $secs (2, 1, 0) {
            $self->progress("Flood protection", $secs);
            sleep(1);
        }
    }

    my @lines;
    if (!$self->{fake}) {
        @lines = `$self->{anidbClient} $self->{hostname} $self->{port} $self->{localport} utf-8 "$request"`;
    } else {
        @lines = `./fakeClient "$request"`;
    }
    $self->{lastRequestTime} = time();
    chomp(@lines);

#print join("\nrep = ", @lines), "\n";

    my $response = shift(@lines);
    my ($code, $msg) = $response =~ /([0-9]+) (.*)/mg;
    return ($code, $msg, \@lines);
}

sub waitTime {
    my ($self, $value) = @_;

    if (defined($value)) {
        $value = 2 if $value < 2;
        $value = 30 if $value > 30;
        $self->{delay} = $value;
    }

    my $secs = ($self->{lastRequestTime} + $self->{delay}) - time();
    return $secs < 0 ? 0 : $secs;
}

sub isLoggedIn {
    my ($self) = @_;
    return defined($self->session());
}

sub findFileByFid {
    my ($self, $key, $finfo) = @_;
}

sub findFileByED2K {
    my ($self, $key, $size) = @_;
    $key = uc($key);
    my $request = "FILE size=${size}&ed2k=${key}&fmask=70F80028&amask=F2F0F0C1";

    my ($code, $msg, $data) = $self->sendRequest($request, "FILE Query");

    if ($code >= 200 && $code < 300) {
        return @{$data}[0];
    } elsif  ($code < 500) {
        print "  AniDB: INFO- $msg ($code)\n";
    } else {
        die "FATAL: $code $msg\n";
    }
    return undef;

#    my ($self, $key, $size) = @_;
#    $key = uc($key);
#    my $text = do { local( @ARGV, $/ ) = "fids/ed2k.$key" ; <> } ;
#    chomp($text);
#    return $text;
}

1;
