#!/usr/bin/perl

# Given that we know the regression tests represent potentially
# broken locations in the code, process every single transitional
# state between an empty document and the entire file to make sure
# all of them parse as legal documents and don't crash the parser.

use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 3876;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use Params::Util qw{_INSTANCE};
use PPI::Lexer;
use PPI::Dumper;
use t::lib::PPI;





#####################################################################
# Code/Dump Testing

t::lib::PPI->increment_testdir(qw{ t data 08_regression });
