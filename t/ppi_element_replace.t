#!/usr/bin/perl

# Unit testing for PPI::Element

use lib 't/lib';
use PPI::Test::pragmas;

use PPI::Document ();
use Test::More tests => ($ENV{AUTHOR_TESTING} ? 1 : 0) + 20 ;

__REPLACE_METH: {
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

__REPLACE_CHILD_METH: {
	my $Document = PPI::Document->new( \"print 'Hello World';" );
	isa_ok( $Document, 'PPI::Document' );
	my $statement = $Document->find_first('Statement');
	isa_ok( $statement, 'PPI::Statement' );
	is( $statement->content, "print 'Hello World';", 'Got expected token' );

	my $doc = PPI::Document->new(\'for my $var ( @vars ) { say "foo" }');
	my $foo = $doc->find('PPI::Statement::Compound');
	isa_ok( $foo->[0], 'PPI::Statement::Compound');
	is( $foo->[0]->content, q~for my $var ( @vars ) { say "foo" }~, 'for loop');
	ok( $statement->parent->replace_child( $statement, $foo->[0] ), 'replace_child success' );
	is( $Document->serialize, 'for my $var ( @vars ) { say "foo" }', 'replace works' );

	{
		my $doc = PPI::Document->new(\'if ($foo) { ... }');
		my $compound = $doc->find('PPI::Statement::Compound');
		my $old_child = $compound->[0]->child(2);
		is( $compound->[0]->child(2), '($foo)', 'found child');

		my $replacement = PPI::Token->new('($bar)');
		my $statement = $doc->find_first('Statement');
		my $success = $statement->replace_child($old_child,$replacement);
		ok( $success, 'replace_child returns success' );

		is( $compound->[0]->child(2), '($bar)', 'child has been replaced');
		is( $doc->content, 'if ($bar) { ... }', 'document updated');
	}

	{
		my $text = 'if ($foo) { ... }';

		my $doc = PPI::Document->new(\$text);
		my $compound = $doc->find('PPI::Statement::Compound');
		is( $compound->[0]->child(2), '($foo)', 'found child');

		my $replacement = PPI::Token->new('($bar)');
		my $statement = $doc->find_first('Statement');

		# Try to replace a child which does not exist.
		my $success = $statement->replace_child($replacement,$replacement);
		ok( !$success, 'replace_child returns failure' );
		is( $doc->content, $text, 'document not updated');
	}
}
