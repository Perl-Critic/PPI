#!/usr/bin/perl

# Unit testing for PPI::Node

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 9 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


PRUNE: {
	# Avoids a bug in old Perls relating to the detection of scripts
	# Known to occur in ActivePerl 5.6.1 and at least one 5.6.2 install.
	my $hashbang = reverse 'lrep/nib/rsu/!#'; 

	my $document = safe_new \<<"END_PERL";
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
	ok( defined($document->prune ('PPI::Statement::Sub')),
		'Pruned multiple subs ok' );
}

REMOVE_CHILD: {
	my $document = safe_new \"1, 2, 3,";
	eval { $document->child };
	like $@->message, qr/method child\(\) needs an index/;
	undef $@;
	eval { $document->child("a") };
	like $@->message, qr/method child\(\) needs an index/;
	my $node = $document->child(0);
	my $del1 = $node->child(7);
	is $node->remove_child($del1), $del1;
	my $fake = bless { content => 3 }, "PPI::Token::Number";
	is $node->remove_child($fake), undef;
}
