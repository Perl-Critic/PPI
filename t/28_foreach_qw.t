#!/usr/bin/perl

# Standalone tests to check "foreach qw{foo} {}"

use t::lib::PPI::Test::pragmas;
use Test::More tests => 13;

#use File::Spec::Functions ':ALL';
use PPI;





#####################################################################
# Parse the canonical cases

SCOPE: {
	my $string   = 'for qw{foo} {} foreach';
	my $document = PPI::Document->new( \$string );
	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('Statement::Compound');
	is( scalar(@$statements), 2, 'Found 2 statements' );
	is( $statements->[0]->type, 'foreach', '->type ok' );
	is( $statements->[1]->type, 'foreach', '->type ok' );
}

SCOPE: {
	my $string   = 'foreach qw{foo} {} foreach';
	my $document = PPI::Document->new( \$string );
	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('Statement::Compound');
	is( scalar(@$statements), 2, 'Found 2 statements' );
	is( $statements->[0]->type, 'foreach', '->type ok' );
	is( $statements->[1]->type, 'foreach', '->type ok' );
}

SCOPE: {
	my $string   = 'for my $foo qw{bar} {} foreach';
	my $document = PPI::Document->new( \$string );
	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('Statement::Compound');
	is( scalar(@$statements), 2, 'Found 2 statements' );
	is( $statements->[0]->type, 'foreach', '->type ok' );
	is( $statements->[1]->type, 'foreach', '->type ok' );
}

1;
