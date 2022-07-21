#!/usr/bin/perl

# Testing of readonly functionality

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 12 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI::Document ();
use Helper 'safe_new';





#####################################################################
# Creating Documents

SCOPE: {
	# Blank document	
	my $empty = safe_new;
	is( $empty->readonly, '', '->readonly is false for blank' );

	# From source
	my $source = 'print "Hello World!\n"';
	my $doc1 = safe_new \$source;
	is( $doc1->readonly, '', '->readonly is false by default' );

	# With explicit false
	my $doc2 = safe_new \$source, readonly => undef;
	is( $doc2->readonly, '', '->readonly is false for explicit false' );

	# With explicit true
	my $doc3 = safe_new \$source, readonly => 2;
	is( $doc3->readonly, 1, '->readonly is true for explicit true' );
}
