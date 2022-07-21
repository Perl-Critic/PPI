#!/usr/bin/perl

use strict;

use lib 't/lib';
use PPI::Test::pragmas;

# Execute the tests
use Test::More tests => 7 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use lib 't/lib';
use Helper qw( check_with );

run();

sub run {
	check_with "qr{a}i", sub {
		my $qr = $_->find_first( 'Token::QuoteLike::Regexp' );
		ok $qr, 'found qr token';
		is $qr->get_match_string,      "a",   "sucessfully retrieved match string";
		is $qr->get_substitute_string, undef, "substitute string method exists but returns undef";
		ok $qr->get_modifiers->{i}, "regex modifiers can be queried";
		is( ( $qr->get_delimiters )[0], "{}", "delimiters can be retrieved" );
	};
}

1;
