use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 1, have_module 'php4';

# Regression test for http://bugs.php.net/bug.php?id=19840

ok t_cmp("GET",
         GET_BODY "/php/getenv.php",
         "getenv(REQUEST_METHOD)"
);