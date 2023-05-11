#!/usr/bin/perl

# Standalone tests to check "foreach qw{foo} {}"

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 15 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

#use File::Spec::Functions ':ALL';
use PPI ();
use Helper 'safe_new';





#####################################################################
# Parse the canonical cases

SCOPE: {
	my $string   = 'sub{}';
	my $document = safe_new \$string;
	my $statements = $document->find('Statement::Compound');
	is( scalar(@$statements), 2, 'Found 2 statements' );
	is( $statements->[0]->type, 'foreach', '->type ok' );
	is( $statements->[1]->type, 'foreach', '->type ok' );
}

SCOPE: {
	my $string   = 'foreach qw{foo} {} foreach';
	my $document = safe_new \$string;
	my $statements = $document->find('Statement::Compound');
	is( scalar(@$statements), 2, 'Found 2 statements' );
	is( $statements->[0]->type, 'foreach', '->type ok' );
	is( $statements->[1]->type, 'foreach', '->type ok' );
}

SCOPE: {
	my $string   = 'for my $foo qw{bar} {} foreach';
	my $document = safe_new \$string;
	my $statements = $document->find('Statement::Compound');
	is( scalar(@$statements), 2, 'Found 2 statements' );
	is( $statements->[0]->type, 'foreach', '->type ok' );
	is( $statements->[1]->type, 'foreach', '->type ok' );
}

1;
