#!/usr/bin/perl

# Unit testing for PPI::Token::QuoteLike::Command

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 21 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper qw( safe_new check_with );

GET_DELIMITERS: {
	local $TODO = "get_delimiters not yet implemented for QuoteLike::Command";
	check_with 'qx{ls}', sub {
		my $qx = $_->find_first( 'Token::QuoteLike::Command' );
		ok $qx, 'found qx token with braces';
		ok $qx->can('get_delimiters'), 'get_delimiters method exists';
		is( ( eval { $qx->get_delimiters } )[0], "{}", "qx{} delimiters" );
	};
	check_with 'qx(ls)', sub {
		my $qx = $_->find_first( 'Token::QuoteLike::Command' );
		is( ( eval { $qx->get_delimiters } )[0], "()", "qx() delimiters" );
	};
	check_with 'qx/ls/', sub {
		my $qx = $_->find_first( 'Token::QuoteLike::Command' );
		is( ( eval { $qx->get_delimiters } )[0], "//", "qx// delimiters" );
	};
	check_with 'qx!ls!', sub {
		my $qx = $_->find_first( 'Token::QuoteLike::Command' );
		is( ( eval { $qx->get_delimiters } )[0], "!!", "qx!! delimiters" );
	};
	check_with 'qx[ls]', sub {
		my $qx = $_->find_first( 'Token::QuoteLike::Command' );
		is( ( eval { $qx->get_delimiters } )[0], "[]", "qx[] delimiters" );
	};
	check_with 'my $out = qx<ls -la>;', sub {
		my $qx = $_->find_first( 'Token::QuoteLike::Command' );
		is( ( eval { $qx->get_delimiters } )[0], "<>", "qx<> delimiters in statement" );
		is scalar( eval { $qx->get_delimiters } ), 1, "qx returns exactly one delimiter pair";
	};
}

1;
