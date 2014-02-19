#!/usr/bin/perl

# Unit testing for PPI::Token::DashedWord

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
	my @pairs = (
		"-foo",        '-foo',
		"-Foo::Bar",   '-Foo::Bar',
		"-Foo'Bar",    '-Foo::Bar',
	);
	while ( @pairs ) {
		my $from  = shift @pairs;
		my $to    = shift @pairs;
		my $doc   = PPI::Document->new( \"( $from => 1 );" );
		isa_ok( $doc, 'PPI::Document' );
		my $word = $doc->find_first('Token::DashedWord');
		SKIP: {
			skip( "PPI::Token::DashedWord is deactivated", 2 );
			isa_ok( $word, 'PPI::Token::DashedWord' );
			is( $word && $word->literal, $to, "The source $from becomes $to ok" );
		}
	}
}
