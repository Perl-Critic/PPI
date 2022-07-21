#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Interpolate

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 9 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


STRING: {
	my $Document = safe_new \"print qq{foo}, qq!bar!, qq <foo>;";
	my $Interpolate = $Document->find('Token::Quote::Interpolate');
	is( scalar(@$Interpolate), 3, '->find returns three objects' );
	isa_ok( $Interpolate->[0], 'PPI::Token::Quote::Interpolate' );
	isa_ok( $Interpolate->[1], 'PPI::Token::Quote::Interpolate' );
	isa_ok( $Interpolate->[2], 'PPI::Token::Quote::Interpolate' );
	is( $Interpolate->[0]->string, 'foo', '->string returns as expected' );
	is( $Interpolate->[1]->string, 'bar', '->string returns as expected' );
	is( $Interpolate->[2]->string, 'foo', '->string returns as expected' );
}
