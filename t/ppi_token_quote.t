#!/usr/bin/perl

# Unit testing for PPI::Token::Quote

use t::lib::PPI::Test::pragmas;
use Test::More tests => 5;

use t::lib::PPI::Test::Cmp;


STRING: {
	# Prove what we say in the ->string docs
	cmp_element( "'foo'",    { isa=>'PPI::Token::Quote', string=>'foo' } );
	cmp_element( '"foo"',    { isa=>'PPI::Token::Quote', string=>'foo' } );
	cmp_element( 'q{foo}',   { isa=>'PPI::Token::Quote', string=>'foo' } );
	cmp_element( 'qq <foo>', { isa=>'PPI::Token::Quote', string=>'foo' } );
}
