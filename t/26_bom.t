#!/usr/bin/perl

use t::lib::PPI::Test::pragmas;
use Test::More tests => 20 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use t::lib::PPI::Test::Run;





#####################################################################
# Code/Dump Testing

t::lib::PPI::Test::Run->run_testdir(qw{ t data 26_bom });
