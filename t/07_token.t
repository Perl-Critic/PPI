#!/usr/bin/perl -w

# Formal unit tests for specific PPI::Token classes

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;

# Execute the tests
use Test::More tests => 61;
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
	foreach my $code ( '08', '0779' ) {
		my $T = PPI::Tokenizer->new( \$code );
		my $token = $T->get_token();
		is("$token", $code, 'tokenize bad octal');
		ok($token->{_error} && $token->{_error} =~ m/octal/i,
		   'invalid octal number should trigger parse error');
	}
}

SCOPE: {
	foreach my $code ( '0b2', '0b012' ) {
		my $T = PPI::Tokenizer->new( \$code );
		my $token = $T->get_token();
		is("$token", $code, 'tokenize bad binary');
		ok($token->{_error} && $token->{_error} =~ m/binary/i,
		   'invalid binary number should trigger parse error');
	}
}


SCOPE: {
	foreach my $code ( '0xg', '0x0g' ) {
		my $T = PPI::Tokenizer->new( \$code );
		my $token = $T->get_token();
		isnt("$token", $code, 'tokenize bad hex');
		ok(!$token->{_error}, 'invalid hexadecimal digit triggers end of token');
	}
}

1;
