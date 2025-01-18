#!/usr/bin/perl

# Test that our declared minimum Perl version matches our syntax

use strict;
BEGIN {
        $|  = 1;
        $^W = 1;
}

my @MODULES = (
	'File::Find::Rule 0.32',
	'File::Find::Rule::Perl 1.09',
	'Perl::MinimumVersion 1.25',
	'Test::MinimumVersion 0.101080',
);

# Don't run tests for installs
use Test::More;

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
    die "Failed to load required release-testing module $MODULE"
      if not eval "use $MODULE; 1";
}

all_minimum_version_from_metayml_ok( {
	paths => [
		grep
          { !/14_charsets\.t/ and !/24_v6\// and !/xt\// and !/Token\/Data\.pm/ }
          File::Find::Rule->perl_file->in('.')
	],
} );
