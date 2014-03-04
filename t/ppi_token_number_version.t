#!/usr/bin/perl

# Unit testing for PPI::Token::Number::Version

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 10;
use Test::NoWarnings;
use PPI;


LITERAL: {
	my $doc1 = new_ok( 'PPI::Document' => [ \'1.2.3.4'  ] );
	my $doc2 = new_ok( 'PPI::Document' => [ \'v1.2.3.4' ] );
	isa_ok( $doc1->child(0), 'PPI::Statement' );
	isa_ok( $doc2->child(0), 'PPI::Statement' );
	isa_ok( $doc1->child(0)->child(0), 'PPI::Token::Number::Version' );
	isa_ok( $doc2->child(0)->child(0), 'PPI::Token::Number::Version' );

	my $literal1 = $doc1->child(0)->child(0)->literal;
	my $literal2 = $doc2->child(0)->child(0)->literal;
	is( length($literal1), 4, 'The literal length of doc1 is 4' );
	is( length($literal2), 4, 'The literal length of doc1 is 4' );
	is( $literal1, $literal2, 'Literals match for 1.2.3.4 vs v1.2.3.4' );
}
