#!/usr/bin/perl

# Test the various PPI::Statement packages

use t::lib::PPI::Test::pragmas;
use Test::More tests => 6;

use PPI;





#####################################################################
# Basic subroutine test

SCOPE: {
	my $doc = PPI::Document->new( \"sub foo { 1 }" );
	isa_ok( $doc, 'PPI::Document' );
	isa_ok( $doc->child(0), 'PPI::Statement::Sub' );
}





#####################################################################
# Regression test, make sure utf8 is a pragma

SCOPE: {
	my $doc = PPI::Document->new( \"use utf8;" );
	isa_ok( $doc, 'PPI::Document' );
	isa_ok( $doc->child(0), 'PPI::Statement::Include' );
	is( $doc->child(0)->pragma, 'utf8', 'use utf8 is a pragma' );
}
