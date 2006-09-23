#!/usr/bin/perl -w

# Testing of PPI::Document::File

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI::Document::File;
use Test::More tests => 4;





#####################################################################
# Creating Documents

SCOPE: {
	# From a specific file
	my $file = catfile('t', 'data', 'basic.pl');
	ok( -f $file, 'Found test file' );

	# Load from the file
	my $doc = PPI::Document::File->new( $file );
	isa_ok( $doc, 'PPI::Document::File' );
	isa_ok( $doc, 'PPI::Document'       );
	is( $doc->filename, $file, '->filename ok' );
}

exit(0);
