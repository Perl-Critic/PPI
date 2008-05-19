#!/usr/bin/perl

# code/dump-style regression tests for known lexing problems.

# Some other regressions tests are included here for simplicity.

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI::Lexer;
use PPI::Dumper;
use Params::Util '_INSTANCE';





#####################################################################
# Prepare

# For each new item in t/data/08_regression add another 14 tests

use Test::More tests => 3302;
use t::lib::PPI;





#####################################################################
# Code/Dump Testing
# ntests = 2 + 14 * nfiles

t::lib::PPI->increment_testdir(qw{ t data 08_regression });

