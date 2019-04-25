#!/usr/bin/perl

# This test script only tests that the tree compiles

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 9 + ($ENV{AUTHOR_TESTING} ? 1 : 0);


# Do the modules load
use_all_ok( qw{
	PPI
	PPI::Tokenizer
	PPI::Lexer
	PPI::Dumper
	PPI::Find
	PPI::Normal
	PPI::Util
	PPI::Cache
	} );

sub use_all_ok { use_ok $_ for @_ }

ok( ! $PPI::XS::VERSION, 'PPI::XS is correctly NOT loaded' );
