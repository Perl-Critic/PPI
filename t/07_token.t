#!/usr/bin/perl

# Formal unit tests for specific PPI::Token classes

use strict;
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}

# Execute the tests
use Test::More tests => 299;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use List::MoreUtils ();
use t::lib::PPI;
use PPI;





#####################################################################
# Code/Dump Testing
# ntests = 2 + 12 * nfiles

t::lib::PPI->run_testdir( catdir( 't', 'data', '07_token' ) );





#####################################################################
# PPI::Token::Symbol Unit Tests
# Note: braces and the symbol() method are tested in regression.t

SCOPE: {
	# Test both creation methods
	my $Token = PPI::Token::Symbol->new( '$foo' );
	isa_ok( $Token, 'PPI::Token::Symbol' );
	
	# Check the creation of a number of different values
	my @symbols = (
		'$foo'       => '$foo',
		'@foo'       => '@foo',
		'$ foo'      => '$foo',
		'$::foo'     => '$main::foo',
		'@::foo'     => '@main::foo',
		'$foo::bar'  => '$foo::bar',
		'$ foo\'bar' => '$foo::bar',
		);
	while ( @symbols ) {
		my ($value, $canon) = ( shift(@symbols), shift(@symbols) );
		my $Symbol = PPI::Token::Symbol->new( $value );
		isa_ok( $Symbol, 'PPI::Token::Symbol' );
		is( $Symbol->content,   $value, "Symbol '$value' returns ->content   '$value'" );
		is( $Symbol->canonical, $canon, "Symbol '$value' returns ->canonical '$canon'" );
	}
}


#####################################################################
# PPI::Token::Number Unit Tests

SCOPE: {
	my @examples = (
		# code => base | '10f' | '10e'
		'0'           => 10,
		'1'           => 10,
		'10'          => 10,
		'1_0'         => 10,
		'.0'          => '10f',
		'.0_0'        => '10f',
		'-.0'         => '10f',
		'0.'          => '10f',
		'0.0'         => '10f',
		'0.0_0'       => '10f',
		'1_0.'        => '10f',
		'.0e0'        => '10e',
		'-.0e0'       => '10e',
		'0.e1'        => '10e',
		'0.0e-1'      => '10e',
		'0.0e+1'      => '10e',
		'0.0e-10'     => '10e',
		'0.0e+10'     => '10e',
		'0.0e100'     => '10e',
		'1_0e1_0'     => '10e', # Known to fail on 5.6.2
		'0b'          => 2,
		'0b0'         => 2,
		'0b10'        => 2,
		'0b1_0'       => 2,
		'00'          => 8,
		'01'          => 8,
		'010'         => 8,
		'01_0'        => 8,
		'0x'          => 16,
		'0x0'         => 16,
		'0x10'        => 16,
		'0x1_0'       => 16,
		'0.0.0'       => 256,
		'.0.0'        => 256,
		'127.0.0.1'   => 256,
		'1.1.1.1.1.1' => 256,
	);

	while ( @examples ) {
		my $code  = shift @examples;
		my $base  = shift @examples;
		if ( $] >= 5.006 and $] < 5.008 and $code eq '1_0e1_0' ) {
			SKIP: {
				skip( 'Ignoring known-bad case on Perl 5.6.2', 5 );
			}
			next;
		}
		my $exp   = $base =~ s/e//;
		my $float = $exp || $base =~ s/f//;
		my $T     = PPI::Tokenizer->new( \$code );
		my $token = $T->get_token;
		is("$token", $code, "'$code' is a single token");
		is($token->base, $base, "base of '$code' is $base");
		if ($float) {
			ok($token->isa('PPI::Token::Number::Float'), "'$code' is ::Float");
		} else {
			ok(!$token->isa('PPI::Token::Number::Float'), "'$code' not ::Float");
		}
		if ($exp) {
			ok($token->isa('PPI::Token::Number::Exp'), "'$code' is ::Exp");
		} else {
			ok(!$token->isa('PPI::Token::Number::Exp'), "'$code' not ::Exp");
		}

		if ($base != 256) {
			$^W = 0;
			my $literal = eval $code;
			if ($@) {
				is($token->literal, undef, "literal('$code'), $@");
			} else {
				cmp_ok($token->literal, '==', $literal, "literal('$code')");
			}
		}
	}
}

foreach my $code ( '1.0._0', '1.0.0.0_0' ) {
	my $T = PPI::Tokenizer->new( \$code );
	my $token = $T->get_token;
	isnt("$token", $code, 'tokenize bad version');
}


foreach my $code ( '08', '09', '0778', '0779' ) {
	my $T = PPI::Tokenizer->new( \$code );
	my $token = $T->get_token;
	isa_ok($token, 'PPI::Token::Number::Octal');
	is("$token", $code, "tokenize bad octal '$code'");
	ok($token->{_error} && $token->{_error} =~ m/octal/i,
	   'invalid octal number should trigger parse error');
	is($token->literal, undef, "literal('$code') is undef");
}

foreach my $code ( '0b2', '0b012' ) {
	my $T = PPI::Tokenizer->new( \$code );
	my $token = $T->get_token;
	isa_ok($token, 'PPI::Token::Number::Binary');
	is("$token", $code, "tokenize bad binary '$code'");
	ok($token->{_error} && $token->{_error} =~ m/binary/i,
	   'invalid binary number should trigger parse error');
	is($token->literal, undef, "literal('$code') is undef");
}

foreach my $code ( '0xg', '0x0g' ) {
	my $T = PPI::Tokenizer->new( \$code );
	my $token = $T->get_token;
	isa_ok($token, 'PPI::Token::Number::Hex');
	isnt("$token", $code, "tokenize bad hex '$code'");
	ok(!$token->{_error}, 'invalid hexadecimal digit triggers end of token');
	is($token->literal, 0, "literal('$code') is 0");
}
