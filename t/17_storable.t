#!/usr/bin/perl -w

# Test compatibility with Storable

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

# Load the code to test
BEGIN { $PPI::XS_DISABLE = 1 }
use PPI::Document ();
use Test::More    ();
use Scalar::Util  'refaddr';

# Is Storable installed?
eval { require Storable; };
if ( $@ ) {
	Test::More::plan( 'skip_all' );
	exit(0);
}
Test::More::plan( tests => 9 );




#####################################################################
# Test freeze/thaw of PPI::Document objects

{
	# Create a document with various example package statements
	my $Document = PPI::Lexer->lex_source( <<'END_PERL' );
package Foo;
@ISA = (qw/File::Spec/);

1;
END_PERL
	Test::More::isa_ok( $Document, 'PPI::Document' );
	{
	my $isa = $Document->find_first(sub { $_[1] eq '@ISA'; });
	Test::More::ok( $isa, "Found ISA var");
	Test::More::is( $isa->parent, q|@ISA = (qw/File::Spec/);|, "Got parent ok");
	}
	my $clone = Storable::dclone($Document);
	Test::More::ok($clone, "dclone ok");
	Test::More::isnt( refaddr($Document), refaddr($clone), "Not the same object" );
	Test::More::is(ref($Document), ref($clone), "Same class");
	Test::More::is_deeply( $Document, $clone, "Deeply equal" );
	{
	my $isa = $clone->find_first(sub { $_[1] eq '@ISA'; });
	Test::More::ok($isa, "Found ISA var");
	Test::More::is($isa->parent, q|@ISA = (qw/File::Spec/);|, "Got parent ok");   # <-- this one fails
	}

}

1;
