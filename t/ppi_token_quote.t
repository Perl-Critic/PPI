#!/usr/bin/perl

# Unit testing for PPI::Token::Quote

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 5 + ($ENV{AUTHOR_TESTING} ? 1 : 0);
use PPI::Test::Cmp;


STRING: {
	# Prove what we say in the ->string docs
	cmp_element( "'foo'",    { isa=>'PPI::Token::Quote', string=>'foo' } );
	cmp_element( '"foo"',    { isa=>'PPI::Token::Quote', string=>'foo' } );
	cmp_element( 'q{foo}',   { isa=>'PPI::Token::Quote', string=>'foo' } );
	cmp_element( 'qq <foo>', { isa=>'PPI::Token::Quote', string=>'foo' } );
}
