#!/usr/bin/perl -w

# Formal testing for PPI

# This does an empiric test that when we try to parse something,
# something ( anything ) comes out the other side.


use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

# Load the API to test
BEGIN { $PPI::XS_DISABLE = 1 }
use PPI;

# Execute the tests
use Test::More tests => 3;

my $testdir = catdir( 't.data', '03_empiric' );



# Get the lexer
my $Lexer = PPI::Lexer->new;
ok( $Lexer, 'PPI::Lexer->new() returns true' );
isa_ok( $Lexer, 'PPI::Lexer' );

# Parse a file
my $Document = $Lexer->lex_file( catfile( $testdir, 'test.dat' ) );
isa_ok( $Document, 'PPI::Document' );

1;
