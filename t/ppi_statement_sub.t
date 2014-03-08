#!/usr/bin/perl

# Test PPI::Statement::Sub

use strict;

BEGIN {
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 131;
use Test::NoWarnings;
use PPI;

SUB_WORD_OPTIONAL: {
	# 'sub' is optional for these special subs. Make sure they're
	# recognized as subs and sub declarations.
	for my $name ( qw( AUTOLOAD DESTROY ) ) {
		for my $sub ( '', 'sub ' ) {

			# '{}' -- function definition
			# ';' -- function declaration
			# '' -- function declaration with missing semicolon
			for my $followed_by ( ' {}', '{}', ';', '' ) {
				test_sub_as( $sub, $name, $followed_by );
			}
		}
	}

	# Through 1.218, the PPI statement AUTOLOAD and DESTROY would
	# gobble up everything after them until it hit an explicit
	# statement terminator. Make sure statements following them are
	# not gobbled.
	my $desc = 'regression: word+block not gobbling to statement terminator';
	for my $word ( qw( AUTOLOAD DESTROY ) ) {
		my $Document = PPI::Document->new( \"$word {} sub foo {}" );
		my $statements = $Document->find('Statement::Sub') || [];
		is( scalar(@$statements), 2, "$desc for $word + sub" );
	
		$Document = PPI::Document->new( \"$word {} package;" );
		$statements = $Document->find('Statement::Sub') || [];
		is( scalar(@$statements), 1, "$desc for $word + package" );
		$statements = $Document->find('Statement::Package') || [];
		is( scalar(@$statements), 1, "$desc for $word + package" );
	}
}

PROTOTYPE: {
	# Doesn't have to be as thorough as ppi_token_prototype.t, since
	# we're just making sure PPI::Token::Prototype->prototype gets
	# passed through correctly.
	for my $test (
		[ '',         undef ],
		[ '()',       '' ],
		[ '( $*Z@ )', '$*Z@' ],
	) {
		my ( $proto_text, $expected ) = @$test;

		my $Document = PPI::Document->new( \"sub foo $proto_text {}" );
		isa_ok( $Document, 'PPI::Document', "$proto_text got document" );

		my ( $sub_statement, $dummy ) = $Document->schildren();
		isa_ok( $sub_statement, 'PPI::Statement::Sub', "$proto_text document child is a sub" );
		is( $dummy, undef, "$proto_text document has exactly one child" );
		is( $sub_statement->prototype, $expected, "$proto_text: prototype matches" );
	}
}

sub test_sub_as {
	my ( $sub, $name, $followed_by ) = @_;

	my $code     = "$sub$name$followed_by";
	my $Document = PPI::Document->new( \$code );
	isa_ok( $Document, 'PPI::Document', "$code: got document" );

	my ( $sub_statement, $dummy ) = $Document->schildren;
	isa_ok( $sub_statement, 'PPI::Statement::Sub', "$code: document child is a sub" );
	isnt( ref $sub_statement, 'PPI::Statement::Scheduled', "$code: not a PPI::Statement::Scheduled" );
	is( $dummy, undef, "$code: document has exactly one child" );
	ok( $sub_statement->reserved, "$code: is reserved" );
	is( $sub_statement->name, $name, "$code: name() correct" );

	if ( $followed_by =~ /}/ ) {
		isa_ok( $sub_statement->block, 'PPI::Structure::Block', "$code: has a block" );
	}
	else {
		ok( !$sub_statement->block, "$code: has no block" );
	}

	return;
}
