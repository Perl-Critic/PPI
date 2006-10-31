#!/usr/bin/perl -w

# Compare a large number of specific constructs
# with the expected Lexer dumps.

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI::Lexer;
use PPI::Dumper;





#####################################################################
# Prepare

use Test::More tests => 156;
use t::lib::PPI;

#####################################################################
# Code/Dump Testing
# ntests = 2 + 11 * nfiles

t::lib::PPI->run_testdir( catdir( 't', 'data', '05_lexer_practical' ) );

exit();
