#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Interpolate

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 9;
use Test::NoWarnings;
use PPI;


STRING: {
	my $Document = PPI::Document->new( \"print qq{foo}, qq!bar!, qq <foo>;" );
	isa_ok( $Document, 'PPI::Document' );
	my $Interpolate = $Document->find('Token::Quote::Interpolate');
	is( scalar(@$Interpolate), 3, '->find returns three objects' );
	isa_ok( $Interpolate->[0], 'PPI::Token::Quote::Interpolate' );
	isa_ok( $Interpolate->[1], 'PPI::Token::Quote::Interpolate' );
	isa_ok( $Interpolate->[2], 'PPI::Token::Quote::Interpolate' );
	is( $Interpolate->[0]->string, 'foo', '->string returns as expected' );
	is( $Interpolate->[1]->string, 'bar', '->string returns as expected' );
	is( $Interpolate->[2]->string, 'foo', '->string returns as expected' );
}
