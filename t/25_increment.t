#!/usr/bin/perl

# Given that we know the regression tests represent potentially
# broken locations in the code, process every single transitional
# state between an empty document and the entire file to make sure
# all of them parse as legal documents and don't crash the parser.

use t::lib::PPI::Test::pragmas;
use Test::More tests => 3876;

use PPI;
use t::lib::PPI;





#####################################################################
# Code/Dump Testing

t::lib::PPI->increment_testdir(qw{ t data 08_regression });
