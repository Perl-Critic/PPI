#!/usr/bin/perl

# Unit testing for PPI::Token::Whitespace

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 6 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI;

TIDY: {
	my $ws1 = PPI::Token::Whitespace->new( "   " );
	is $ws1->length, "3";
	ok $ws1->tidy;
	is $ws1->length, "3";
	my $ws2 = PPI::Token::Whitespace->new( "   \n" );
	is $ws2->length, "4";
	ok $ws2->tidy;
	is $ws2->length, "0";
}
