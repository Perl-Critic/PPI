#!/usr/bin/perl

# Testing of the normalization functions.
# (only very basic at this point)

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 21 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI             ();
use PPI::Singletons qw( %LAYER );
use Helper 'safe_new';

#####################################################################
# Creation and Manipulation

SCOPE: {
	my $Document = safe_new \'my $foo = bar();';

	my $Normal = $Document->normalized;
	isa_ok( $Normal, 'PPI::Document::Normalized' );
	is( $Normal->version, $PPI::Normal::VERSION, '->version matches $VERSION' );
	my $functions = $Normal->functions;
	is( ref $functions, 'ARRAY', '->functions returns an array ref' );
	ok( scalar(@$functions), '->functions returns at least 1 function' );
}

#####################################################################
# Basic Empiric Tests

# Basic empiric testing
SCOPE: {
	# The following should be equivalent
	my $Document1 = safe_new \'my $foo = 1; # comment';
	my $Document2 = safe_new \'my  $foo=1 ;# different comment';
	my $Document3 = safe_new \'sub foo { print "Hello World!\n"; }';
	my $Normal1   = $Document1->normalized;
	my $Normal2   = $Document2->normalized;
	my $Normal3   = $Document3->normalized;
	isa_ok( $Normal1, 'PPI::Document::Normalized' );
	isa_ok( $Normal2, 'PPI::Document::Normalized' );
	isa_ok( $Normal3, 'PPI::Document::Normalized' );
	is( $Normal1->equal($Normal2),
		1, '->equal returns true for equivalent code' );
	is( $Normal1->equal($Normal3),
		'', '->equal returns false for different code' );
}

NO_DOUBLE_REG: {
	sub just_a_test_sub { "meep" }
	ok( PPI::Normal->register( "main::just_a_test_sub", 2 ), "can add subs" );
	is $LAYER{2}[-1], "main::just_a_test_sub", "and find subs at right layer";
	my $size = @{ $LAYER{2} };
	ok( PPI::Normal->register( "main::just_a_test_sub", 2 ),
		"can add subs again" );
	is scalar @{ $LAYER{2} }, $size, "but sub isn't added twice";
}
