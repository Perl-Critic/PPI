#!/usr/bin/perl

# Unit testing for PPI::Element

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 12;

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

__REPLACE_PARENT: {
	my $Document = PPI::Document->new( \"print 'Hello World';" );
	isa_ok( $Document, 'PPI::Document' );
	my $statement = $Document->find_first('Statement');
	isa_ok( $statement, 'PPI::Statement' );
	is( $statement->content, "print 'Hello World';", 'Got expected token' );

	my $doc = PPI::Document->new(\'for my $var ( @vars ) { say "foo" }');
    my $foo = $doc->find('PPI::Statement::Compound');
	isa_ok( $foo->[0], 'PPI::Statement::Compound');
	is( $foo->[0]->content, q~for my $var ( @vars ) { say "foo" }~, 'for loop');
	ok( $statement->parent->replace_child( $statement, $foo->[0] ) );
	is( $Document->serialize, 'for my $var ( @vars ) { say "foo" }', 'replace works' );
}
