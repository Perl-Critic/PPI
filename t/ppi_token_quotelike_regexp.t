#!/usr/bin/perl

use strict;
use File::Spec::Functions ':ALL';

use t::lib::PPI::Test::pragmas;
use PPI;

# Execute the tests
use Test::More;

use lib 't/lib';
use Helper 'check_with';

run();
done_testing;

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
