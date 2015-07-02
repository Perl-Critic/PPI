package t::lib::PPI::Test::pragmas;

=head1 NAME

PPI::Test::pragmas -- standard complier/runtime setup for PPI tests

=cut

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings', ':no_end_test';

BEGIN {
	select STDERR;  ## no critic ( InputOutput::ProhibitOneArgSelect )
	$| = 1;
	select STDOUT;  ## no critic ( InputOutput::ProhibitOneArgSelect )

	no warnings 'once';  ## no critic ( TestingAndDebugging::ProhibitNoWarnings )
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

sub import {
	strict->import();
	warnings->import();
	return;
}

END {
    Test::Warnings::had_no_warnings() if $ENV{AUTHOR_TESTING};
}

1;
