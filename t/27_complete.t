#!/usr/bin/perl

# Testing for the PPI::Document ->complete method

use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use PPI;

# This test uses a series of ordered files, containing test code.
# The letter after the number acts as a boolean yes/no answer to
# "Is this code complete"
my @files = find_files( catdir( 't', 'data', '27_complete' ) );
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





#####################################################################
# Support Functions

sub find_files {
	my $testdir  = shift;
	
	# Does the test directory exist?
	-e $testdir and -d $testdir and -r $testdir or die "Failed to find test directory $testdir";
	
	# Find the .code test files
	opendir( TESTDIR, $testdir ) or die "opendir: $!";
	my @perl = map { catfile( $testdir, $_ ) } sort grep { /\.(?:code|pm|t)$/ } readdir(TESTDIR);
	closedir( TESTDIR ) or die "closedir: $!";
	return @perl;
}
