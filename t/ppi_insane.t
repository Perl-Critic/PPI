#!/usr/bin/perl

use strict;

use Test::InDistDir;
use lib 't/lib';
use PPI::Test::pragmas;

# Execute the tests
use Test::More tests => 7 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use lib 't/lib';
use Helper qw( check_with );

run();

sub run {
	check_with "hello \x1c\0\0\0\0\x1c;\n", sub {
		my $qr = $_->find_first( 'Token::QuoteLike::Regexp' );
		ok $qr, 'found qr token';
	};
}

1;
