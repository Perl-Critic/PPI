#!/usr/bin/perl

# Given that we know the regression tests represent potentially
# broken locations in the code, process every single transitional
# state between an empty document and the entire file to make sure
# all of them parse as legal documents and don't crash the parser.

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 8998 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI::Test::Run ();





#####################################################################
# Code/Dump Testing

PPI::Test::Run->increment_testdir(qw{ t data 08_regression });
