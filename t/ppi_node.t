#!/usr/bin/perl

# Unit testing for PPI::Node

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 3;
use Test::NoWarnings;
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
