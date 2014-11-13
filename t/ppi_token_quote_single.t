#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Single

use t::lib::PPI::Test::pragmas;
use Test::More tests => 25;

use PPI;


STRING: {
	my $Document = PPI::Document->new( \"print 'foo';" );
	isa_ok( $Document, 'PPI::Document' );
	my $Single = $Document->find_first('Token::Quote::Single');
	isa_ok( $Single, 'PPI::Token::Quote::Single' );
	is( $Single->string, 'foo', '->string returns as expected' );
}


LITERAL: {
	my @pairs = (
		"''",          '',
		"'f'",         'f',
		"'f\\'b'",     "f\'b",
		"'f\\nb'",     "f\\nb",
		"'f\\\\b'",    "f\\b",
		"'f\\\\\\b'", "f\\\\b",
		"'f\\\\\\\''", "f\\'",
	);
	while ( @pairs ) {
		my $from  = shift @pairs;
		my $to    = shift @pairs;
		my $doc   = PPI::Document->new( \"print $from;" );
		isa_ok( $doc, 'PPI::Document' );
		my $quote = $doc->find_first('Token::Quote::Single');
		isa_ok( $quote, 'PPI::Token::Quote::Single' );
		is( $quote->literal, $to, "The source $from becomes $to ok" );
	}
}
