#!/usr/bin/perl

# Unit testing for PPI::Normal

use t::lib::PPI::Test::pragmas;
use Test::More tests => 28;

use PPI;


NEW: {
	# Check we actually set the layer at creation
	my $layer_1 = PPI::Normal->new;
	isa_ok( $layer_1, 'PPI::Normal' );
	is( $layer_1->layer, 1, '->new creates a layer 1' );
	my $layer_1a = PPI::Normal->new(1);
	isa_ok( $layer_1a, 'PPI::Normal' );
	is( $layer_1a->layer, 1, '->new(1) creates a layer 1' );
	my $layer_2 = PPI::Normal->new(2);
	isa_ok( $layer_2, 'PPI::Normal' );
	is( $layer_2->layer, 2, '->new(2) creates a layer 2' );
}


BAD: {
	# Test bad things
	is( PPI::Normal->new(3), undef, '->new only allows up to layer 2' );
	is( PPI::Normal->new(undef), undef, '->new(evil) returns undef' );
	is( PPI::Normal->new("foo"), undef, '->new(evil) returns undef' );
	is( PPI::Normal->new(\"foo"), undef, '->new(evil) returns undef' );
	is( PPI::Normal->new([]), undef, '->new(evil) returns undef' );
	is( PPI::Normal->new({}), undef, '->new(evil) returns undef' );
}


PROCESS: {
	my $doc1 = PPI::Document->new(\'print "Hello World!\n";');
	isa_ok( $doc1, 'PPI::Document' );
	my $doc2 = \'print "Hello World!\n";';
	my $doc3 = \' print  "Hello World!\n"; # comment';
	my $doc4 = \'print "Hello World!\n"';

	# Normalize them at level 1
	my $layer1 = PPI::Normal->new(1);
	isa_ok( $layer1, 'PPI::Normal' );
	my $nor11 = $layer1->process($doc1->clone);
	my $nor12 = $layer1->process($doc2);
	my $nor13 = $layer1->process($doc3);
	isa_ok( $nor11, 'PPI::Document::Normalized' );
	isa_ok( $nor12, 'PPI::Document::Normalized' );
	isa_ok( $nor13, 'PPI::Document::Normalized' );

	# The first 3 should be the same, the second not
	is_deeply( { %$nor11 }, { %$nor12 }, 'Layer 1: 1 and 2 match' );
	is_deeply( { %$nor11 }, { %$nor13 }, 'Layer 1: 1 and 3 match' );

	# Normalize them at level 2
	my $layer2 = PPI::Normal->new(2);
	isa_ok( $layer2, 'PPI::Normal' );
	my $nor21 = $layer2->process($doc1);
	my $nor22 = $layer2->process($doc2);
	my $nor23 = $layer2->process($doc3); 
	my $nor24 = $layer2->process($doc4);
	isa_ok( $nor21, 'PPI::Document::Normalized' );
	isa_ok( $nor22, 'PPI::Document::Normalized' );
	isa_ok( $nor23, 'PPI::Document::Normalized' );
	isa_ok( $nor24, 'PPI::Document::Normalized' );

	# The first 3 should be the same, the second not
	is_deeply( { %$nor21 }, { %$nor22 }, 'Layer 2: 1 and 2 match' );
	is_deeply( { %$nor21 }, { %$nor23 }, 'Layer 2: 1 and 3 match' );
	is_deeply( { %$nor21 }, { %$nor24 }, 'Layer 2: 1 and 4 match' );
}
