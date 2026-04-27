#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More;
use File::Find ();

my @files;
File::Find::find(
	{ wanted => sub { push @files, $_ if /\.pm\z/ && -f }, no_chdir => 1 },
	'lib',
);
@files = sort @files;

plan tests => scalar(@files) + ($ENV{AUTHOR_TESTING} ? 1 : 0);

for my $file (@files) {
	open my $fh, '<', $file or die "Cannot open $file: $!";
	my $content = do { local $/; <$fh> };
	close $fh;

	TODO: {
		local $TODO = 'use warnings not yet added to all modules';
		like( $content, qr/^use warnings;$/m, "$file has 'use warnings'" );
	}
}
