#!/usr/bin/perl

# Testing of the normalization functions.
# (only very basic at this point)

use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 14;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use PPI;





#####################################################################
# Creation and Manipulation

SCOPE: {
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
SCOPE: {
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
