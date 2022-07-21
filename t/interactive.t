#!/usr/bin/perl

# Script used to temporarily test the most recent parser bug.
# Testing it here is much more efficient than having to trace
# down through the entire set of regression tests.

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 3 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


# Define the test code
my $code = 'sub f:f(';





#####################################################################
# Run the actual tests

my $document = eval { safe_new \$code };
$DB::single = $DB::single = 1 if $@; # Catch exceptions
is( $@, '', 'Parsed without error' );
