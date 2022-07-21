#!/usr/bin/perl

# Testing for the PPI::Document ->complete method

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More; # Plan comes later

use File::Spec::Functions qw( catdir );
use PPI ();
use PPI::Test qw( find_files );
use Helper 'safe_new';

# This test uses a series of ordered files, containing test code.
# The letter after the number acts as a boolean yes/no answer to
# "Is this code complete"
my @files = find_files( catdir( 't', 'data', '27_complete' ) );
my $tests = (scalar(@files) * 3) + 1 + ($ENV{AUTHOR_TESTING} ? 1 : 0);
plan( tests => $tests );





#####################################################################
# Resource Location

ok( scalar(@files), 'Found at least one ->complete test file' );
foreach my $file ( @files ) {
	# Load the document
	my $document = safe_new $file;

	# Test if complete or not
	my $got      = !! ($document->complete);
	my $expected = !! ($file =~ /\d+y\w+\.code$/);
	my $isnot    = ($got == $expected) ? 'is' : 'is NOT';
	is( $got, $expected, "File $file $isnot complete" );
}
