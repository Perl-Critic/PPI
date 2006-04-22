#!/usr/bin/perl -w

# Testing of the normalization functions.
# (only very basic at this point)

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

# Load the code to test
BEGIN { $PPI::XS_DISABLE = 1 }
use PPI;
use Test::More tests => 13;




#####################################################################
# Creation and Manipulation

{
	my $Document = PPI::Document->new(\'my $foo = bar();');
	isa_ok( $Document, 'PPI::Document' );

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
{
	# The following should be equivalent
	my $Document1 = PPI::Document->new( \'my $foo = 1; # comment' );
	my $Document2 = PPI::Document->new( \'my  $foo=1 ;# different comment' );
	my $Document3 = PPI::Document->new( \'sub foo { print "Hello World!\n"; }' );
	isa_ok( $Document1, 'PPI::Document' );
	isa_ok( $Document2, 'PPI::Document' );
	isa_ok( $Document3, 'PPI::Document' );
	my $Normal1 = $Document1->normalized;
	my $Normal2 = $Document2->normalized;
	my $Normal3 = $Document3->normalized;
	isa_ok( $Normal1, 'PPI::Document::Normalized' );
	isa_ok( $Normal2, 'PPI::Document::Normalized' );
	isa_ok( $Normal3, 'PPI::Document::Normalized' );
	is( $Normal1->equal( $Normal2 ), 1, '->equal returns true for equivalent code' );
	is( $Normal1->equal( $Normal3 ), '', '->equal returns false for different code' );
}


1;

