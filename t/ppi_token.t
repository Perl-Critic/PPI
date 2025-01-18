#!/usr/bin/perl

# Unit testing for PPI::Token

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 5 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI ();

MODIFICATION: {
	my $one = PPI::Token->new("");
	is $one->length, 0, "empty token has no length";
	ok $one->add_content("abcde"), "can add strings";
	is $one->length, 5, "adding actually adds";
	ok $one->set_content("abc"), "can set content";
	is $one->length, 3, "setting overwrites";
}
