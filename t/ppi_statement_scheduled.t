#!/usr/bin/perl

# Test PPI::Statement::Scheduled

use strict;

BEGIN {
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 241;
use Test::NoWarnings;
use PPI;

SUB_WORD_OPTIONAL: {
	for my $name ( qw( BEGIN CHECK UNITCHECK INIT END ) ) {
		for my $sub ( '', 'sub ' ) {

			# '{}' -- function definition
			# ';' -- function declaration
			# '' -- function declaration with missing semicolon
			for my $followed_by ( ' {}', '{}', ';', '' ) {
				test_sub_as( $sub, $name, $followed_by );
			}
		}
	}
}

sub test_sub_as {
	my ( $sub, $name, $followed_by ) = @_;

	my $code     = "$sub$name$followed_by";
	my $Document = PPI::Document->new( \$code );
	isa_ok( $Document, 'PPI::Document', "$code: got document" );

	my ( $sub_statement, $dummy ) = $Document->schildren;
	isa_ok( $sub_statement, 'PPI::Statement::Scheduled', "$code: document child is a scheduled statement" );
	is( $dummy, undef, "$code: document has exactly one child" );
	ok( $sub_statement->reserved, "$code: is reserved" );
	is( $sub_statement->name, $name, "$code: name() correct" );

	if ( $followed_by =~ /}/ ) {
		isa_ok( $sub_statement->block, 'PPI::Structure::Block', "$code: has a block" );
	}
	else {
		ok( !$sub_statement->block, "$code: has no block" );
	}

	return;
}
