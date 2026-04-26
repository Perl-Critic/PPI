#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Interpolate

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 9 + 11 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


GET_DELIMITERS: {
	my $Document = safe_new \"print qq{foo}, qq!bar!, qq <foo>;";
	my $Interpolate = $Document->find('Token::Quote::Interpolate');
	ok $Interpolate->[0]->can('get_delimiters'), 'get_delimiters method exists';
	is( ( $Interpolate->[0]->get_delimiters )[0], "{}", "qq{} delimiters" );
	is( ( $Interpolate->[1]->get_delimiters )[0], "!!", "qq!! delimiters" );
	is( ( $Interpolate->[2]->get_delimiters )[0], "<>", "qq<> delimiters" );
	is scalar( $Interpolate->[0]->get_delimiters ), 1, "qq returns exactly one delimiter pair";

	my $d2 = safe_new \"qq/foo/";
	my $qq = $d2->find_first('Token::Quote::Interpolate');
	ok $qq, 'found qq/.../ token';
	is( ( $qq->get_delimiters )[0], "//", "qq// delimiters" );
}

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
