#!/usr/bin/perl

# Unit testing for PPI::Element

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 6;

use PPI;


__REPLACE: {
	my $Document = PPI::Document->new( \"print 'Hello World';" );
	isa_ok( $Document, 'PPI::Document' );
	my $string = $Document->find_first('Token::Quote');
	isa_ok( $string, 'PPI::Token::Quote' );
	is( $string->content, "'Hello World'", 'Got expected token' );
	my $foo = PPI::Token::Quote::Single->new("'foo'");
	isa_ok( $foo, 'PPI::Token::Quote::Single' );
	is( $foo->content, "'foo'", 'Created Quote token' );
	$string->replace( $foo );
	is( $Document->serialize, "print 'foo';", 'replace works' );
}
