#!/usr/bin/perl

use strict;
use File::Spec::Functions ':ALL';

BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use PPI;

# Execute the tests
use Test::More;

use lib 't/lib';
use Helper 'check_with';

run();
done_testing;

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
