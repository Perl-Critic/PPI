#!/usr/bin/perl

# Script used to temporarily test the most recent parser bug.
# Testing it here is must more efficient than having to trace
# down through the entire set of regression tests.

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;

# Execute the tests
use Test::More tests => 2;

# Define the test code
my $code = 'sub f:f(';





#####################################################################
# Run the actual tests

my $document = eval { PPI::Document->new(\$code) };
$DB::single = $DB::single = 1 if $@; # Catch exceptions
is( $@, '', 'Parsed without error' );
isa_ok( $document, 'PPI::Document' );
