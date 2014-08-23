#!/usr/bin/perl

# Test PPI::Statement::Sub

use strict;
BEGIN {
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 13;
use Test::NoWarnings;
use PPI;


PROTOTYPE: {
	# Doesn't have to be as thorough as ppi_token_prototype.t, since
	# we're just making sure PPI::Token::Prototype->prototype gets
	# passed through correctly.
	for my $test (
		[ '',         undef ],
		[ '()',       '' ],
		[ '( $*Z@ )', '$*Z@' ],
	) {
		my ( $proto_text, $expected ) = @$test;

		my $Document = PPI::Document->new( \"sub foo $proto_text {}" );
		isa_ok( $Document, 'PPI::Document', "$proto_text got document" );

		my ( $sub_statement, $dummy ) = $Document->schildren();
		isa_ok( $sub_statement, 'PPI::Statement::Sub', "$proto_text document child is a sub" );
		is( $dummy, undef, "$proto_text document has exactly one child" );
		is( $sub_statement->prototype, $expected, "$proto_text: prototype matches" );
	}
}
