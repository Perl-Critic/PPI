#!/usr/bin/perl

# Unit testing for PPI::Token::Symbol

use t::lib::PPI::Test::pragmas;
use Test::More tests => 128 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI;


my $Token = PPI::Token::Symbol->new( '$foo' );
isa_ok( $Token, 'PPI::Token::Symbol' );


TOKEN_FROM_PARSE: {
	parse_and_test( '$x',    { content => '$x',   canonical => '$x',       raw_type => '$', symbol_type => '$', symbol => '$x' } );
	parse_and_test( '$x[0]', { content => '$x',   canonical => '$x',       raw_type => '$', symbol_type => '@', symbol => '@x' } );
	parse_and_test( '$x{0}', { content => '$x',   canonical => '$x',       raw_type => '$', symbol_type => '%', symbol => '%x' } );
	parse_and_test( '$::x',  { content => '$::x', canonical => '$main::x', raw_type => '$', symbol_type => '$', symbol => '$main::x' } );
	{
		local $ENV{TODO} = 'bug in canonical';
		parse_and_test( q{$'x}, { content => q{$'x}, canonical => '$main::x', raw_type => '$', symbol_type => '$', symbol => '$main::x' } );
	}

	parse_and_test( '@x',      { content => '@x',   canonical => '@x',       raw_type => '@', symbol_type => '@', symbol => '@x' } );
	parse_and_test( '@x[0]',   { content => '@x',   canonical => '@x',       raw_type => '@', symbol_type => '@', symbol => '@x' } );
	parse_and_test( '@x[0,1]', { content => '@x',   canonical => '@x',       raw_type => '@', symbol_type => '@', symbol => '@x' } );
	parse_and_test( '@x{0}',   { content => '@x',   canonical => '@x',       raw_type => '@', symbol_type => '%', symbol => '%x' } );
	parse_and_test( '@::x',    { content => '@::x', canonical => '@main::x', raw_type => '@', symbol_type => '@', symbol => '@main::x' } );

	parse_and_test( '%x',   { content => '%x',   canonical => '%x',       raw_type => '%', symbol_type => '%', symbol => '%x' } );
	parse_and_test( '%::x', { content => '%::x', canonical => '%main::x', raw_type => '%', symbol_type => '%', symbol => '%main::x' } );

	parse_and_test( '&x',   { content => '&x',   canonical => '&x',       raw_type => '&', symbol_type => '&', symbol => '&x' } );
	parse_and_test( '&::x', { content => '&::x', canonical => '&main::x', raw_type => '&', symbol_type => '&', symbol => '&main::x' } );

	parse_and_test( '*x',   { content => '*x',   canonical => '*x',       raw_type => '*', symbol_type => '*', symbol => '*x' } );
	parse_and_test( '*::x', { content => '*::x', canonical => '*main::x', raw_type => '*', symbol_type => '*', symbol => '*main::x' } );
}


CONSTRUCT_OWN_TOKEN: {
	# Test behavior that parsing does not support as of PPI 1.220.
	test_symbol( PPI::Token::Symbol->new('$ foo'),             { content => '$ foo',             canonical => '$foo',                 raw_type => '$', symbol_type => '$', symbol => '$foo' }, '$ foo' );
	test_symbol( PPI::Token::Symbol->new('$ foo\'bar'),        { content => '$ foo\'bar',        canonical => '$foo::bar',            raw_type => '$', symbol_type => '$', symbol => '$foo::bar' }, '$ foo\'bar' );
	# example from PPI::Token::Symbol->canonical documentation
	test_symbol( PPI::Token::Symbol->new('$ ::foo\'bar::baz'), { content => '$ ::foo\'bar::baz', canonical => '$main::foo::bar::baz', raw_type => '$', symbol_type => '$', symbol => '$main::foo::bar::baz' }, '$ ::foo\'bar::baz' );
}


sub parse_and_test {
	local $Test::Builder::Level = $Test::Builder::Level+1;

	my ( $code, $symbol_expected, $msg ) = @_;
	$msg = $code if !defined $msg;

	my $Document = PPI::Document->new( \$code );
	isa_ok( $Document, 'PPI::Document', "$msg got document" );

	my $symbols = $Document->find( 'PPI::Token::Symbol') || [];
	is( scalar(@$symbols), 1, "$msg got exactly one symbol" );
	test_symbol( $symbols->[0], $symbol_expected, $msg );

	return;
}


sub test_symbol {
	local $Test::Builder::Level = $Test::Builder::Level+1;

	my ( $symbol, $symbol_expected, $msg ) = @_;

	is( $symbol->content,     $symbol_expected->{content}, "$msg: content" );
	{
	local $TODO = $ENV{TODO} if $ENV{TODO};
	is( $symbol->canonical,   $symbol_expected->{canonical}, "$msg: canonical" );
	}
	is( $symbol->raw_type,    $symbol_expected->{raw_type}, "$msg: raw_type" );
	is( $symbol->symbol_type, $symbol_expected->{symbol_type}, "$msg: symbol_type" );
	local $TODO = $ENV{TODO} if $ENV{TODO};
	is( $symbol->symbol,      $symbol_expected->{symbol}, "$msg: symbol" );

	return;
}
