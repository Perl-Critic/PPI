#!/usr/bin/perl

use strict;

use lib 't/lib';
use PPI::Test::pragmas;
use Helper qw( check_with );

# Execute the tests
use Test::More tests => 9 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

run();

sub run {
	check_with "(1)", sub {
		my $qr = $_->find_first( 'Token::Structure' );
		ok $qr, 'found qr token';
		is $qr->snext_sibling,     "", "non-semicolon tokens shortcut to empty strong for significant siblings";
		is $qr->sprevious_sibling, "", "non-semicolon tokens shortcut to empty strong for significant siblings";
	};
	check_with "(", sub {
		my $tokens = $_->find( 'Token::Structure' );
		ok $tokens->[0], 'found qr token';
		is $tokens->[0]->next_token, '',
		  "empty string is returned as next token for an unclosed structure without children";
	};
}

1;
