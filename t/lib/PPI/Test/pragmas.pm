package PPI::Test::pragmas;

=head1 NAME

PPI::Test::pragmas -- standard complier/runtime setup for PPI tests

=cut

use 5.006;
use strict;
use warnings;
use Test::NoWarnings;

BEGIN {
	$| = 1;
	select STDERR;
	$| = 1;
	select STDOUT;

	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

sub import {
	warnings->import();
	strict->import();
	Test::NoWarnings->import();
}


1;
