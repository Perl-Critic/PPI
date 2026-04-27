#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 2 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();

isa_ok( PPI::Exception->new("test"), 'PPI::Exception' );

# GH #143: PPI::Exception::ParserRejection is dead code.
# It adds nothing to the base class and is never thrown.
TODO: {
	local $TODO = "PPI::Exception::ParserRejection not yet removed (GH #143)";
	ok( !exists $INC{"PPI/Exception/ParserRejection.pm"},
		"PPI::Exception::ParserRejection should not be loaded by PPI" );
}
