#!/usr/bin/perl -w

# Formal unit tests for specific PPI::Token classes

use strict;
use File::Spec::Functions ':ALL';
use List::MoreUtils qw();
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;

# Execute the tests
use Test::More tests => 135;
use t::lib::PPI;

#####################################################################
# Code/Dump Testing
# ntests = 2 + 12 * nfiles

t::lib::PPI->run_testdir( catdir( 't', 'data', '07_token' ) );



#####################################################################
# PPI::Token::Symbol Unit Tests
# Note: braces and the symbol() method are tested in regression.t

{
	# Test both creation methods
	my $Token = PPI::Token::Symbol->new( '$foo' );
	isa_ok( $Token, 'PPI::Token::Symbol' );
	$Token = PPI::Token->new( 'Symbol', '$foo' );
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
		# code => base
		'0'    => 10,
		'1'    => 10,
		'.0'   => 10,
		'0.'   => 10,
		'0.0'  => 10,
		'0b'   => 2,
		'0b0'  => 2,
		'0b10' => 2,
		'00'   => 8,
		'01'   => 8,
		'010'  => 8,
		'0x'   => 16,
		'0x0'  => 16,
		'0x10' => 16,
		'0.0.0'       => 256,
		'.0.0'        => 256,
		'127.0.0.1'   => 256,
		'1.1.1.1.1.1' => 256,
	);

	my $iterator = List::MoreUtils::natatime(2, @examples);
	while (my ($code, $base) = $iterator->()) {
		my $T = PPI::Tokenizer->new( \$code );
		my $token = $T->get_token();
		is("$token", $code, "'$code' is a single token");
		is($token->base(), $base, "base of '$code' is $base");

		$code =~ s/(.)/${1}__/gs;
		$T = PPI::Tokenizer->new( \$code );
		$token = $T->get_token();
		if ($code =~ m/\A\./) { # decimal point followed by underscore is not a number
			isnt("$token", $code, "'$code' is not a single token");
		} else {
			is("$token", $code, "'$code' is a single token");
			is($token->base(), $base, "base of '$code' is $base");
		}
	}
}

foreach my $code ( '08', '09', '0778', '0779' ) {
	my $T = PPI::Tokenizer->new( \$code );
	my $token = $T->get_token();
	is("$token", $code, 'tokenize bad octal');
	ok($token->{_error} && $token->{_error} =~ m/octal/i,
	   'invalid octal number should trigger parse error');
}

foreach my $code ( '0b2', '0b012' ) {
	my $T = PPI::Tokenizer->new( \$code );
	my $token = $T->get_token();
	is("$token", $code, 'tokenize bad binary');
	ok($token->{_error} && $token->{_error} =~ m/binary/i,
	   'invalid binary number should trigger parse error');
}

foreach my $code ( '0xg', '0x0g' ) {
	my $T = PPI::Tokenizer->new( \$code );
	my $token = $T->get_token();
	isnt("$token", $code, 'tokenize bad hex');
	ok(!$token->{_error}, 'invalid hexadecimal digit triggers end of token');
}

1;
