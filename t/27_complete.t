#!/usr/bin/perl

# Testing for the PPI::Document ->complete method

use t::lib::PPI::Test::pragmas;
use Test::More;

use File::Spec::Functions ':ALL';
use PPI;
use t::lib::PPI::Test;

# This test uses a series of ordered files, containing test code.
# The letter after the number acts as a boolean yes/no answer to
# "Is this code complete"
my @files = t::lib::PPI::Test::find_files( catdir( 't', 'data', '27_complete' ) );
my $tests = (scalar(@files) * 2) + 2;
plan( tests => $tests );





#####################################################################
# Resource Location

ok( scalar(@files), 'Found at least one ->complete test file' );
foreach my $file ( @files ) {
	# Load the document
	my $document = PPI::Document->new( $file );
	isa_ok( $document, 'PPI::Document' );

	# Test if complete or not
	my $got      = !! ($document->complete);
	my $expected = !! ($file =~ /\d+y\w+\.code$/);
	my $isnot    = ($got == $expected) ? 'is' : 'is NOT';
	is( $got, $expected, "File $file $isnot complete" );
}
