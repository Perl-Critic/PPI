#!/usr/bin/perl

# Test PPI::Exception

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 9 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI::Exception ();

# Class->throw populates callers
eval { PPI::Exception->throw( 'class throw' ) };
my $e1 = $@;
isa_ok( $e1, 'PPI::Exception' );
is( $e1->message, 'class throw', 'class throw preserves message' );
my @callers1 = $e1->callers;
is( scalar @callers1, 1, 'class throw populates callers' );

# Object with no prior callers: throw should still populate callers
eval { PPI::Exception->new( 'object throw' )->throw() };
my $e2 = $@;
isa_ok( $e2, 'PPI::Exception' );
is( $e2->message, 'object throw', 'object throw preserves message' );
my @callers2 = $e2->callers;
TODO: {
	local $TODO = "throw on object with empty callers does not populate caller info";
	is( scalar @callers2, 1, 'object throw with no prior callers populates callers' );
}

# Object with existing callers: throw should append
eval { PPI::Exception->throw( 'first throw' ) };
my $e3 = $@;
eval { $e3->throw() };
$e3 = $@;
isa_ok( $e3, 'PPI::Exception' );
my @callers3 = $e3->callers;
is( scalar @callers3, 2, 'rethrown object accumulates callers' );

# Default message
eval { PPI::Exception->throw() };
my $e4 = $@;
is( $e4->message, 'Unknown Exception', 'default message is set' );
