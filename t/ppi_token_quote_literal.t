#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Literal

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 13;
use Test::NoWarnings;
use PPI;


STRING: {
	my $Document = PPI::Document->new( \"print q{foo}, q!bar!, q <foo>;" );
	isa_ok( $Document, 'PPI::Document' );
	my $literal = $Document->find('Token::Quote::Literal');
	is( scalar(@$literal), 3, '->find returns three objects' );
	isa_ok( $literal->[0], 'PPI::Token::Quote::Literal' );
	isa_ok( $literal->[1], 'PPI::Token::Quote::Literal' );
	isa_ok( $literal->[2], 'PPI::Token::Quote::Literal' );
	is( $literal->[0]->string, 'foo', '->string returns as expected' );
	is( $literal->[1]->string, 'bar', '->string returns as expected' );
	is( $literal->[2]->string, 'foo', '->string returns as expected' );
}


LITERAL: {
	my $Document = PPI::Document->new( \"print q{foo}, q!bar!, q <foo>;" );
	isa_ok( $Document, 'PPI::Document' );
	my $literal = $Document->find('Token::Quote::Literal');
	is( $literal->[0]->literal, 'foo', '->literal returns as expected' );
	is( $literal->[1]->literal, 'bar', '->literal returns as expected' );
	is( $literal->[2]->literal, 'foo', '->literal returns as expected' );
}
