#!/usr/bin/perl

# Testing of PPI::Document::File

use t::lib::PPI::Test::pragmas;
use Test::More tests => 5;

use File::Spec::Functions ':ALL';
use PPI::Document::File;





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
