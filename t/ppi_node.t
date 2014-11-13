#!/usr/bin/perl

# Unit testing for PPI::Node

use t::lib::PPI::Test::pragmas;
use Test::More tests => 3;

use PPI;


PRUNE: {
	# Avoids a bug in old Perls relating to the detection of scripts
	# Known to occur in ActivePerl 5.6.1 and at least one 5.6.2 install.
	my $hashbang = reverse 'lrep/nib/rsu/!#'; 

	my $document = PPI::Document->new( \<<"END_PERL" );
$hashbang

use strict;

sub one { 1 }
sub two { 2 }
sub three { 3 }

print one;
print "\n";
print three;
print "\n";

exit;
END_PERL

	isa_ok( $document, 'PPI::Document' );
	ok( defined($document->prune ('PPI::Statement::Sub')),
		'Pruned multiple subs ok' );
}
