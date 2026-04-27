#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 2 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();

isa_ok( PPI::Exception->new("test"), 'PPI::Exception' );

ok( !exists $INC{"PPI/Exception/ParserRejection.pm"},
	"PPI::Exception::ParserRejection should not be loaded by PPI" );
