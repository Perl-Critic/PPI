#!/usr/bin/perl

# Test PPI::Statement::Sub

use strict;
BEGIN {
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 113;
use Test::NoWarnings;
use PPI;


SUB_WORD_OPTIONAL: {
	foreach my $name ( qw( AUTOLOAD DESTROY ) ) {
		foreach my $sub ( '', 'sub ' ) {
			# '{}' -- function definition
			# ';' -- function declaration
			# '' -- function declaration with missing semicolon
			foreach my $followed_by ( ' {}', '{}', ';', '' ) {
				my $code = "$sub$name$followed_by";
				my $Document = PPI::Document->new( \$code );
				isa_ok( $Document, 'PPI::Document', "$code: got document" );

				my ( $sub_statement, $dummy ) = $Document->schildren();
				isa_ok( $sub_statement, 'PPI::Statement::Sub', "$code: document child is a sub" );
				isnt( ref $sub_statement, 'PPI::Statement::Scheduled', "$code: not a PPI::Statement::Scheduled" );
				is( $dummy, undef, "$code: document has exactly one child" );
				ok( $sub_statement->reserved(), "$code: is reserved" );
				is( $sub_statement->name(), $name, "$code: name() correct" );
				if ( $followed_by =~ /}/ ) {
					isa_ok( $sub_statement->block(), 'PPI::Structure::Block', "$code: has a block" );
				}
				else {
					ok( !$sub_statement->block(), "$code: has no block" );
				}
			}
		}
	}
}
