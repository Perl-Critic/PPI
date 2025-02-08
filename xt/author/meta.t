#!/usr/bin/perl

# Test that our META.yml file matches the current specification.

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

my $MODULE = 'Test::CPAN::Meta 0.17';

# Don't run tests for installs
use Test::More;

# Load the testing module
die "Failed to load required release-testing module $MODULE"
  if not eval "use $MODULE; 1";

meta_yaml_ok();
