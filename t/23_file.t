#!/usr/bin/perl

# Testing of PPI::Document::File

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 4 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use File::Spec::Functions qw( catfile );
use PPI::Document::File ();





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
