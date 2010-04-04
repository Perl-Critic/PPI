#!/usr/bin/perl

# Regression test of a Perl 5 grammar that exploded
# with a "98 subroutine recursion" error in 1.201

use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 9;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use PPI;

foreach my $file ( qw{
	Simple.pm
	Grammar.pm
} ) {
	my $path = catfile( qw{ t data 24_v6 }, $file );
	ok( -f $path, "Found test file $file" );

	my $doc = PPI::Document->new( $path );
	isa_ok( $doc, 'PPI::Document' );

	# Find the first Perl6 include
	my $include = $doc->find_first( 'PPI::Statement::Include::Perl6' );
	isa_ok( $include, 'PPI::Statement::Include::Perl6' );
	ok(
		scalar($include->perl6),
		'use v6 statement has a working ->perl6 method',
	);
}
