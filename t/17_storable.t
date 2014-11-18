#!/usr/bin/perl

# Test compatibility with Storable

use t::lib::PPI::Test::pragmas;
use Test::More;
BEGIN {
	# Is Storable installed?
	if ( eval { require Storable; 1 } ) {
		plan( tests => 10 );
	} else {
		plan( 'skip_all' );
		exit(0);
	}
}

use Scalar::Util  'refaddr';
use PPI;





#####################################################################
# Test freeze/thaw of PPI::Document objects

SCOPE: {
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
