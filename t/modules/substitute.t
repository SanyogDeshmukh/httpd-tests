use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil qw(t_write_file);

Apache::TestRequest::user_agent(keep_alive => 1);

my $debug = 0;
my $url = '/modules/substitue/test.txt';

# mod_bucketeer control chars
my $B = chr(0x02);
my $F = chr(0x06);
my $P = chr(0x10);

my @test_cases = (
    [ "f${B}o${P}ofoo" => 's/foo/bar/' ],
    [ "f${B}o${P}ofoo" => 's/fo/fa/', 's/fao/bar/' ],
    [ "foofoo"         => 's/Foo/bar/' ],
    [ "fo${F}ofoo"     => 's/Foo/bar/i' ],
    [ "foOFoo"         => 's/OF/of/', 's/foo/bar/' ],
    [ "fofooo"         => 's/(.)fo/$1of/', 's/foo/bar/' ],
    [ "foof\noo"       => 's/f.oo/bar/' ],
    [ "xfooo"          => 's/foo/fo/' ],
    [ "xfoo" x 4000    => 's/foo/bar/', 's/FOO/BAR/' ],
    [ "foox\n" x 4000  => 's/foo/bar/', 's/FOO/BAR/' ],
);

plan tests => scalar @test_cases,
              need need_lwp,
              need_module('mod_substitute'),
              need_module('mod_bucketeer');

foreach my $t (@test_cases) {
    my ($content, @rules) = @{$t};

    write_testfile($content);
    write_htaccess(@rules);

    # We assume that perl does the right thing (TM) and compare that with
    # mod_substitute's result.
    my $expect = $content;
    $expect =~ s/[$B$F$P]+//g;
    foreach my $rule (@rules) {
        $rule .= "g";   # mod_substitute always does global search & replace
        eval "\$expect =~ $rule\n";
    }

    my $response = GET('/modules/substitute/test.txt');
    my $rc = $response->code;
    my $got = $response->content;
    my $ok = ($rc == 200) && ($got eq $expect);
    print "got $rc '$got'", ($ok ? ": OK\n" : ", expected '$expect'\n");

    ok($ok);
}

exit 0;

### sub routines
sub write_htaccess
{
    my @rules = @_;
    my $file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'htdocs',
                                   'modules', 'substitute', '.htaccess');
    my $content = "SetOutputFilter BUCKETEER;SUBSTITUTE\n";
    $content .= "Substitute $_\n" for @rules;
    t_write_file($file, $content);
    print "$content<===\n" if $debug;
}

sub write_testfile
{
    my $content = shift;
    my $file = File::Spec->catfile(Apache::Test::vars('serverroot'), 'htdocs',
                                   'modules', 'substitute', 'test.txt');
    t_write_file($file, $content);
    print "$content<===\n" if $debug;
}