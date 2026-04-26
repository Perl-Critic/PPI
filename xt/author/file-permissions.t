#!/usr/bin/perl

# Verify that distribution metadata files do not have the executable bit set.
# See https://github.com/Perl-Critic/PPI/issues/167

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;

# Skip on Windows where file permission tests are unreliable
plan skip_all => 'File permission tests not meaningful on Windows'
  if $^O eq 'MSWin32';

my @files = grep { -e $_ } qw(
	Changes
	LICENSE
	MANIFEST
	META.yml
	META.json
	Makefile.PL
	README
	README.md
	README.pod
	cpanfile
);

plan skip_all => 'No distribution metadata files found (not running in build dir?)'
  if not @files;

plan tests => scalar @files;

TODO: {
	local $TODO = 'GH #167: file permissions not yet normalized in dist';

	for my $file (@files) {
		my $mode = (stat $file)[2] & 07777;
		ok( !($mode & 0111), "$file is not executable (mode " . sprintf('%04o', $mode) . ")" );
	}
}
