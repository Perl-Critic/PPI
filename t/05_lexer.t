#!/usr/bin/perl

# Compare a large number of specific code samples (.code)
# with the expected Lexer dumps (.dump).

use t::lib::PPI::Test::pragmas;
use Test::More tests => 219;

use File::Spec::Functions ':ALL';
use PPI::Lexer;
use t::lib::PPI;

#####################################################################
# Code/Dump Testing

t::lib::PPI->run_testdir( catdir( 't', 'data', '05_lexer' ) );
