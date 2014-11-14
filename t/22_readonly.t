#!/usr/bin/perl

# Testing of readonly functionality

use t::lib::PPI::Test::pragmas;
use Test::More tests => 9;

use PPI::Document;





#####################################################################
# Creating Documents

SCOPE: {
	# Blank document	
	my $empty = PPI::Document->new;
	isa_ok( $empty, 'PPI::Document' );
	is( $empty->readonly, '', '->readonly is false for blank' );

	# From source
	my $source = 'print "Hello World!\n"';
	my $doc1 = PPI::Document->new( \$source );
	isa_ok( $doc1, 'PPI::Document' );
	is( $doc1->readonly, '', '->readonly is false by default' );

	# With explicit false
	my $doc2 = PPI::Document->new( \$source,
		readonly => undef,
		);
	isa_ok( $doc2, 'PPI::Document' );
	is( $doc2->readonly, '', '->readonly is false for explicit false' );

	# With explicit true
	my $doc3 = PPI::Document->new( \$source,
		readonly => 2,
		);
	isa_ok( $doc3, 'PPI::Document' );
	is( $doc3->readonly, 1, '->readonly is true for explicit true' );
}
