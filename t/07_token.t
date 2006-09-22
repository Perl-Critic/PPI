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
use Test::More tests => 41;
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
	my $T = PPI::Tokenizer->new( \'08' );
	my $token = $T->get_token();
	is("$token", '08', 'tokenize octal');
	ok($token->{_error} && $token->{_error} =~ m/octal/i,
	   'invalid octal number should trigger parse error');
}

SCOPE: {
	my $T = PPI::Tokenizer->new( \'0779' );
	my $token = $T->get_token();
	is("$token", '0779', 'tokenize octal');
	ok($token->{_error} && $token->{_error} =~ m/octal/i,
	   'invalid octal number should trigger parse error');
}

1;
