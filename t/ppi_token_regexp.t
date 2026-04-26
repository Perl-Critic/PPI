#!/usr/bin/perl

use strict;

use lib 't/lib';
use PPI::Test::pragmas;

# Execute the tests
use Test::More tests => 18 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use lib 't/lib';
use Helper qw( check_with );

run();

sub run {
	check_with "m{a}i", sub {
		my $qr = $_->find_first( 'Token::Regexp' );
		ok $qr, 'found qr token';
		is $qr->get_match_string,      "a",   "sucessfully retrieved match string";
		is $qr->get_substitute_string, undef, "substitute string method exists but returns undef";
		ok $qr->get_modifiers->{i}, "regex modifiers can be queried";
		is( ( $qr->get_delimiters )[0], "{}", "delimiters can be retrieved" );
	};
	check_with "s{a}{b}i", sub {
		my $qr = $_->find_first( 'Token::Regexp' );
		ok $qr, 'found qr token';
		is $qr->get_substitute_string, "b", "substitute string can be extracted";
	};

	check_with 's/a/b/ee', sub {
		my $qr = $_->find_first( 'Token::Regexp' );
		ok $qr, 'found s///ee regexp token';
		is $qr->get_match_string, "a", "s///ee match string";
		is $qr->get_substitute_string, "b", "s///ee substitute string";
		is_deeply scalar($qr->get_modifiers), { e => 2 }, "s///ee tracks repeated e modifier";
		is( ( $qr->get_delimiters )[0], "//", "s///ee delimiters" );
	};
}

1;
