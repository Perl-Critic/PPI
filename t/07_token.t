#!/usr/bin/perl

# Formal unit tests for specific PPI::Token classes

sub warns_on_misplaced_underscore { $] >= 5.006 and $] < 5.008 }
sub dies_on_incomplete_bx { $] >= 5.031002 }

use if !(-e 'META.yml'), "Test::InDistDir";
use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 588 + (warns_on_misplaced_underscore() ? 2 : 0 ) + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use File::Spec::Functions ':ALL';
use PPI;
use PPI::Test::Run;





#####################################################################
# Code/Dump Testing

PPI::Test::Run->run_testdir( catdir( 't', 'data', '07_token' ) );





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
		'1_0e1_0'     => '10e',
		'1e00'        => '10e',
		'1e+00'       => '10e',
		'1e-00'       => '10e',
		'1e00000'     => '10e',
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
		if ( warns_on_misplaced_underscore() and ($code eq '1_0e1_0' or $code eq '1_0' or $code eq '1_0.') ) {
			SKIP: {
				skip( 'Ignoring known-bad cases on Perl 5.6.2', 5 );
			}
			next;
		}
		my $is_exp   = $base =~ s/e//;
		my $is_float = $is_exp || $base =~ s/f//;
		my $T     = PPI::Tokenizer->new( \$code );
		my $token = $T->get_token;
		is("$token", $code, "'$code' is a single token");
		is($token->base, $base, "base of '$code' is $base");
		is($token->isa('PPI::Token::Number::Float'), $is_float,
		   "'$code' ".($is_float ? "is" : "not")." ::Float");
		is($token->isa('PPI::Token::Number::Exp'), $is_exp,
		   "'$code' ".($is_float ? "is" : "not")." ::Exp");

		next if $base == 256;

		$^W = 0;
		my $underscore_incompatible = warns_on_misplaced_underscore() && $code =~ /^1_0[.]?$/;
		my $incomplete_incompatible = dies_on_incomplete_bx() && $code =~ /^0[bx]$/;
		my $literal = eval $code;
		my $err = $@;
		$literal = undef if $underscore_incompatible || $incomplete_incompatible;
		warning_is { $literal = eval $code } "Misplaced _ in number",
			"$] warns about misplaced underscore"
			if $underscore_incompatible;
		like($err, qr/No digits found for (binary|hexadecimal) literal/,
			 "$] dies on incomplete binary/hexadecimal literals")
			if $underscore_incompatible;
		no warnings qw{ uninitialized };
		cmp_ok($token->literal, '==', $err ? undef : $literal,
			   "literal('$code'), eval error: " . ($err || "none"));
	}
}

for my $code ( '1.0._0' ) {
	my $token = PPI::Tokenizer->new( \$code )->get_token;
	isnt("$token", $code, 'tokenize bad version');
}

for my $code ( '1.0.0.0_0' ) {
	my $token = PPI::Tokenizer->new( \$code )->get_token;
	is("$token", $code, 'tokenize good version');
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
