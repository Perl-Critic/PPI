#!/usr/bin/perl

# Compare a large number of specific constructs
# with the expected Lexer dumps.

use strict;
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI::Lexer;
use PPI::Dumper;





#####################################################################
# Prepare

use Test::More tests => (3 + 15 * 12);
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use t::lib::PPI;





#####################################################################
# Code/Dump Testing
# ntests = 2 + 15 * nfiles

t::lib::PPI->run_testdir( catdir( 't', 'data', '05_lexer' ) );
