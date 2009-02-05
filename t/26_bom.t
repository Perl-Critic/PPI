#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}

# For each new item in t/data/08_regression add another 14 tests
use Test::More tests => 18;
use Test::NoWarnings;
use t::lib::PPI;
use PPI;





#####################################################################
# Code/Dump Testing
# ntests = 2 + 14 * nfiles

t::lib::PPI->run_testdir(qw{ t data 26_bom });
