use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my @testcasespaths = (
    ['/modules/speling/nocase/'], 
    ['/modules/speling/caseonly/'], 
);

my @testcases = (
    ## File        Test        CheckCaseOnly Off   On
    ['good.html',  "normal",                 200, 200], 
    ['god.html',   "omission",               301, 404],
    ['goood.html', "insertion",              301, 404],
    ['godo.html',  "transposition",          301, 404],
    ['go_d.html',  "wrong character",        301, 404],
    ['GOOD.html',  "case",                   301, 301],

    ['good.wrong_ext', "wrong extension",    300, 300],
    ['GOOD.wrong_ext', "NC wrong extension", 300, 300],

    ['Bad.html',  "wrong filename",          404, 404],
    ['dogo.html', "double transposition",    404, 404],
    ['XooX.html', "double wrong character",  404, 404],

    ['several0.html', "multiple choise",     300, 404],
);

plan tests => scalar @testcasespaths * scalar @testcases, need 'mod_speling';

my $r;
my $code = 2;

# disable redirect
local $Apache::TestRequest::RedirectOK = 0;

foreach my $p (@testcasespaths) {
    foreach my $t (@testcases) {
        ## 
        $r = GET($p->[0] . $t->[0]);
        print $r->content;

        # Checking for return code
        ok t_cmp($r->code, $t->[$code], "Checking " . $t->[1] . ". Expecting: ". $t->[$code]);
    }
    
    $code = $code+1;
}
