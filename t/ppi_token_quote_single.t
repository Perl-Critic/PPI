#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Single

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 35 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


STRING: {
	my $Document = safe_new \"print 'foo';";
	my $Single = $Document->find_first('Token::Quote::Single');
	isa_ok( $Single, 'PPI::Token::Quote::Single' );
	is( $Single->string, 'foo', '->string returns as expected' );
}


INTERPOLATIONS: {
	local $TODO = 'interpolations not yet implemented on Single';
	my $Document = safe_new \"print 'foo';";
	my $Single = $Document->find_first('Token::Quote::Single');
	is( eval { $Single->interpolations }, '', 'Single quotes have no interpolations' );
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
		my $doc   = safe_new \"print $from;";
		my $quote = $doc->find_first('Token::Quote::Single');
		isa_ok( $quote, 'PPI::Token::Quote::Single' );
		is( $quote->literal, $to, "The source $from becomes $to ok" );
	}
}
