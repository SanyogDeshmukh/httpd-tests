package Apache::TestHarness;

use strict;
use warnings FATAL => 'all';

use Test::Harness ();
use Apache::TestSort ();
use Apache::TestTrace;
use File::Spec::Functions qw(catfile);
use File::Find qw(finddepth);

sub chdir_t {
    chdir 't' if -d 't';
#Apache::TestConfig->new takes care of @INC
#    inc_fixup();
}

sub inc_fixup {
    # use blib
    unshift @INC, map "blib/$_", qw(lib arch);

    # fix all relative library locations
    for (@INC) {
        $_ = "../$_" unless m,^(/)|([a-f]:),i;
    }
}

#skip tests listed in t/SKIP
sub skip {
    my($self, $file) = @_;
    $file ||= 'SKIP';

    return unless -e $file;

    open my $fh, $file or die "open $file: $!";
    my @skip;
    local $_;

    while (<$fh>) {
        chomp;
        s/^\s+//; s/\s+$//; s/^\#.*//;
        next unless $_;
        s/\*/.*/g;
        push @skip, $_;
    }

    close $fh;
    return join '|', @skip;
}

sub run {
    my $self = shift;
    my $args = shift || {};
    my @tests = ();

    chdir_t();

    $Test::Harness::verbose ||= $args->{verbose};
    my $ts = $args->{tests} || [];

    if (@$ts) {
	for (@$ts) {
	    if (-d $_) {
		push(@tests, sort <$_/*.t>);
	    }
	    else {
		$_ .= ".t" unless /\.t$/;
		push(@tests, $_);
	    }
	}
    }
    else {
        if ($args->{tdirs}) {
            push @tests, map { sort <$_/*.t> } @{ $args->{tdirs} };
        }
        else {
            finddepth(sub {
                          return unless /\.t$/;
                          my $t = catfile $File::Find::dir, $_;
                          my $dotslash = catfile '.', "";
                          $t =~ s:^$dotslash::;
                          push @tests, $t
                      }, '.');
            @tests = sort @tests;
        }
    }

    if (my $skip = $self->skip) {
        @tests = grep { not /(?:$skip)/ } @tests;
    }

    Apache::TestSort->run(\@tests, $args);

    Test::Harness::runtests(@tests);
}

1;
