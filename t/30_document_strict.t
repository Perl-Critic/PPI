#!/usr/bin/perl

# Testing PPI::Document::Strict

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 21 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use PPI::Document::Strict ();

sub exception_message {
	my $err = shift;
	return ref $err && $err->can('message') ? $err->message : "$err";
}

#####################################################################
# Successful parsing of valid code

VALID_CODE: {
	my $doc = eval { PPI::Document::Strict->new( \"my \$x = 1;" ) };
	is( $@, '', 'valid code does not throw' );
	isa_ok( $doc, 'PPI::Document::Strict' );
	isa_ok( $doc, 'PPI::Document' );
	ok( $doc->complete, 'valid document is complete' );
}

VALID_MULTI_STATEMENT: {
	my $doc = eval { PPI::Document::Strict->new( \"use strict;\nmy \$x = 1;\n" ) };
	is( $@, '', 'multi-statement valid code does not throw' );
	isa_ok( $doc, 'PPI::Document::Strict' );
}

#####################################################################
# Parse failure should die

UNDEF_INPUT: {
	my $doc = eval { PPI::Document::Strict->new(undef) };
	ok( !defined $doc, 'undef input returns undef/throws' );
	like( exception_message($@), qr/PPI::Document::Strict:/, 'undef input throws with prefix' );
}

#####################################################################
# Unmatched braces should die

UNMATCHED_CLOSE_BRACE: {
	my $doc = eval { PPI::Document::Strict->new( \"my \$x = 1; }" ) };
	ok( !defined $doc, 'unmatched closing brace throws' );
	like( exception_message($@), qr/UnmatchedBrace/, 'error mentions UnmatchedBrace' );
}

UNMATCHED_CLOSE_PAREN: {
	my $doc = eval { PPI::Document::Strict->new( \"my \$x = 1; )" ) };
	ok( !defined $doc, 'unmatched closing paren throws' );
	like( exception_message($@), qr/UnmatchedBrace/, 'error mentions UnmatchedBrace' );
}

#####################################################################
# Incomplete structures should die

UNCLOSED_BRACE: {
	my $doc = eval { PPI::Document::Strict->new( \"sub foo {" ) };
	ok( !defined $doc, 'unclosed brace throws' );
	like( exception_message($@), qr/incomplete/i, 'error mentions incomplete' );
}

UNCLOSED_PAREN: {
	my $doc = eval { PPI::Document::Strict->new( \"my \$x = (" ) };
	ok( !defined $doc, 'unclosed paren throws' );
	like( exception_message($@), qr/incomplete/i, 'error mentions incomplete' );
}

#####################################################################
# Constructor attributes pass through

READONLY_ATTR: {
	my $doc = eval { PPI::Document::Strict->new( \"my \$x = 1;", readonly => 1 ) };
	is( $@, '', 'readonly attr does not throw' );
	isa_ok( $doc, 'PPI::Document::Strict' );
	ok( $doc->readonly, 'readonly attribute is set' );
}

#####################################################################
# Empty document

EMPTY_DOC: {
	my $doc = eval { PPI::Document::Strict->new( \"" ) };
	is( $@, '', 'empty document does not throw' );
	isa_ok( $doc, 'PPI::Document::Strict' );
}
