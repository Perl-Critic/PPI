#!/usr/bin/perl

# Compare a large number of specific code samples (.code)
# with the expected Lexer dumps (.dump).

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 218 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use File::Spec::Functions ':ALL';
use PPI::Lexer;
use PPI::Test::Run;

#####################################################################
# Code/Dump Testing

PPI::Test::Run->run_testdir( catdir( 't', 'data', '05_lexer' ) );
