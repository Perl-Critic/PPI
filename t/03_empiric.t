#!/usr/bin/perl

# Formal testing for PPI

# This does an empiric test that when we try to parse something,
# something ( anything ) comes out the other side.

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;

# Execute the tests
use Test::More tests => 3;

my $testdir = catdir( 't', 'data', '03_empiric' );



# Get the lexer
my $Lexer = PPI::Lexer->new;
ok( $Lexer, 'PPI::Lexer->new() returns true' );
isa_ok( $Lexer, 'PPI::Lexer' );

# Parse a file
my $Document = $Lexer->lex_file( catfile( $testdir, 'test.dat' ) );
isa_ok( $Document, 'PPI::Document' );

1;
