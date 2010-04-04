#!/usr/bin/perl

# Compare a large number of specific constructs
# with the expected Lexer dumps.

use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use PPI::Lexer;
use PPI::Dumper;





#####################################################################
# Prepare

use Test::More tests => 219;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use t::lib::PPI;





#####################################################################
# Code/Dump Testing
# ntests = 2 + 15 * nfiles

t::lib::PPI->run_testdir( catdir( 't', 'data', '05_lexer' ) );
