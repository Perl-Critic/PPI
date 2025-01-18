#!/usr/bin/perl

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

my $MODULE = 'Test::Pod 1.44';

# Don't run tests for installs
use Test::More;

# Load the testing module
die "Failed to load required release-testing module $MODULE"
  if not eval "use $MODULE; 1";

all_pod_files_ok();
