#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 20 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI::Test::Run ();

#####################################################################
# Code/Dump Testing

PPI::Test::Run->run_testdir(qw{ t data 26_bom });
