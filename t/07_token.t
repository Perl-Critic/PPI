#!/usr/bin/perl

# Formal unit tests for specific PPI::Token classes

use t::lib::PPI::Test::pragmas;
use Test::More tests => 447;

use File::Spec::Functions ':ALL';
use PPI;
use t::lib::PPI::Test::Run;





#####################################################################
# Code/Dump Testing

t::lib::PPI::Test::Run->run_testdir( catdir( 't', 'data', '07_token' ) );





#####################################################################
# PPI::Token::Symbol Unit Tests
# Note: braces and the symbol() method are tested in 08_regression.t

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

BINARY: {
	my @tests = (
		# Good binary numbers
		{ code => '0b0',        error => 0, value => 0 },
		{ code => '0b1',        error => 0, value => 1 },
		{ code => '0B1',        error => 0, value => 1 },
		{ code => '0b101',      error => 0, value => 5 },
		{ code => '0b1_1',      error => 0, value => 3 },
		{ code => '0b1__1',     error => 0, value => 3 },  # perl warns, but parses it
		{ code => '0b1__1_',    error => 0, value => 3 },  # perl warns, but parses it
		# Bad binary numbers
		{ code => '0b2',        error => 1, value => 0 },
		{ code => '0B2',        error => 1, value => 0 },
		{ code => '0b012',      error => 1, value => 0 },
		{ code => '0B012',      error => 1, value => 0 },
		{ code => '0B0121',     error => 1, value => 0 },
        );
	foreach my $test ( @tests ) {
		my $code = $test->{code};
		my $T = PPI::Tokenizer->new( \$code );
		my $token = $T->get_token;
		isa_ok($token, 'PPI::Token::Number::Binary');
                if ( $test->{error} ) {
                    ok($token->{_error} && $token->{_error} =~ m/binary/i,
                       'invalid binary number should trigger parse error');
                    is($token->literal, undef, "literal('$code') is undef");
                }
                else {
                    ok(!$token->{_error}, "no error for '$code'");
                    is($token->literal, $test->{value}, "literal('$code') is $test->{value}");
                }
                is($token->content, $code, "parsed everything");
	}
}

HEX: {
	my @tests = (
		# Good hex numbers--entire thing goes in the token
		{ code => '0x0',        parsed => '0x0', value => 0 },
		{ code => '0X1',        parsed => '0X1', value => 1 },
		{ code => '0x1',        parsed => '0x1', value => 1 },
		{ code => '0x_1',       parsed => '0x_1', value => 1 },
		{ code => '0x__1',      parsed => '0x__1', value => 1 },  # perl warns, but parses it
		{ code => '0x__1_',     parsed => '0x__1_', value => 1 },  # perl warns, but parses it
		{ code => '0X1',        parsed => '0X1', value => 1 },
		{ code => '0xc',        parsed => '0xc', value => 12 },
		{ code => '0Xc',        parsed => '0Xc', value => 12 },
		{ code => '0XC',        parsed => '0XC', value => 12 },
		{ code => '0xbeef',     parsed => '0xbeef', value => 48879 },
		{ code => '0XbeEf',     parsed => '0XbeEf', value => 48879 },
		{ code => '0x0e',       parsed => '0x0e', value => 14 },
		{ code => '0x00000e',   parsed => '0x00000e', value => 14 },
		{ code => '0x000_00e',  parsed => '0x000_00e', value => 14 },
		{ code => '0x000__00e', parsed => '0x000__00e', value => 14 },  # perl warns, but parses it
		# Bad hex numbers--tokenizing stops when bad digit seen
		{ code => '0x',    parsed => '0x', value => 0 },
		{ code => '0X',    parsed => '0X', value => 0 },
		{ code => '0xg',   parsed => '0x', value => 0 },
		{ code => '0Xg',   parsed => '0X', value => 0 },
		{ code => '0XG',   parsed => '0X', value => 0 },
		{ code => '0x0g',  parsed => '0x0', value => 0 },
		{ code => '0X0g',  parsed => '0X0', value => 0 },
		{ code => '0X0G',  parsed => '0X0', value => 0 },
		{ code => '0x1g',  parsed => '0x1', value => 1 },
		{ code => '0x1g2', parsed => '0x1', value => 1 },
		{ code => '0x1_g', parsed => '0x1_', value => 1 },
	);
	foreach my $test ( @tests ) {
		my $code = $test->{code};
		my $T = PPI::Tokenizer->new( \$code );
		my $token = $T->get_token;
		isa_ok($token, 'PPI::Token::Number::Hex');
		ok(!$token->{_error}, "no error for '$code' even on invalid digits");
		is($token->content, $test->{parsed}, "correctly parsed everything expected");
                is($token->literal, $test->{value}, "literal('$code') is $test->{value}");
	}
}
