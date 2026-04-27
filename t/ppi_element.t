#!/usr/bin/perl

# Unit testing for PPI::Element

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 98 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


__INSERT_AFTER: {
	my $Document = safe_new \"print 'Hello World';";
	my $string = $Document->find_first('Token::Quote');
	isa_ok( $string, 'PPI::Token::Quote' );
	is( $string->content, "'Hello World'", 'Got expected token' );
	my $foo = PPI::Token::Word->new('foo');
	isa_ok( $foo, 'PPI::Token::Word' );
	is( $foo->content, 'foo', 'Created Word token' );
	$string->__insert_after( $foo );
	is( $Document->serialize, "print 'Hello World'foo;",
		'__insert_after actually inserts' );
}


__INSERT_BEFORE: {
	my $Document = safe_new \"print 'Hello World';";
	my $semi = $Document->find_first('Token::Structure');
	isa_ok( $semi, 'PPI::Token::Structure' );
	is( $semi->content, ';', 'Got expected token' );
	my $foo = PPI::Token::Word->new('foo');
	isa_ok( $foo, 'PPI::Token::Word' );
	is( $foo->content, 'foo', 'Created Word token' );
	$semi->__insert_before( $foo );
	is( $Document->serialize, "print 'Hello World'foo;",
		'__insert_before actually inserts' );
}


ANCESTOR_OF: {
	my $Document = safe_new \'( [ thingy ] ); $blarg = 1';
	ok(
		$Document->ancestor_of($Document),
		'Document is an ancestor of itself.',
	);

	my $words = $Document->find('Token::Word');
	is(scalar @{$words}, 1, 'Document contains 1 Word.');
	my $word = $words->[0];
	ok(
		$word->ancestor_of($word),
		'Word is an ancestor of itself.',
	);
	ok(
		! $word->ancestor_of($Document),
		'Word is not an ancestor of the Document.',
	);
	ok(
		$Document->ancestor_of($word),
		'Document is an ancestor of the Word.',
	);

	my $symbols = $Document->find('Token::Symbol');
	is(scalar @{$symbols}, 1, 'Document contains 1 Symbol.');
	my $symbol = $symbols->[0];
	ok(
		! $word->ancestor_of($symbol),
		'Word is not an ancestor the Symbol.',
	);
	ok(
		! $symbol->ancestor_of($word),
		'Symbol is not an ancestor the Word.',
	);
}


COLUMN_NUMBER: {
	my $document = safe_new \<<'END_PERL';


   foo
END_PERL
	my $words = $document->find('PPI::Token::Word');
	is( scalar @{$words}, 1, 'Found expected word token.' );
	is( $words->[0]->column_number, 4, 'Got correct column number.' );
}


DESCENDANT_OF: {
	my $Document = safe_new \'( [ thingy ] ); $blarg = 1';
	ok(
		$Document->descendant_of($Document),
		'Document is a descendant of itself.',
	);

	my $words = $Document->find('Token::Word');
	is(scalar @{$words}, 1, 'Document contains 1 Word.');
	my $word = $words->[0];
	ok(
		$word->descendant_of($word),
		'Word is a descendant of itself.',
	);
	ok(
		$word->descendant_of($Document),
		'Word is a descendant of the Document.',
	);
	ok(
		! $Document->descendant_of($word),
		'Document is not a descendant of the Word.',
	);

	my $symbols = $Document->find('Token::Symbol');
	is(scalar @{$symbols}, 1, 'Document contains 1 Symbol.');
	my $symbol = $symbols->[0];
	ok(
		! $word->descendant_of($symbol),
		'Word is not a descendant the Symbol.',
	);
	ok(
		! $symbol->descendant_of($word),
		'Symbol is not a descendant the Word.',
	);
}


INSERT_AFTER: {
	my $Document = safe_new \"print 'Hello World';";
	my $string = $Document->find_first('Token::Quote');
	isa_ok( $string, 'PPI::Token::Quote' );
	is( $string->content, "'Hello World'", 'Got expected token' );
	my $foo = PPI::Token::Word->new('foo');
	isa_ok( $foo, 'PPI::Token::Word' );
	is( $foo->content, 'foo', 'Created Word token' );
	$string->insert_after( $foo );
	is( $Document->serialize, "print 'Hello World'foo;",
		'insert_after actually inserts' );
}


INSERT_BEFORE: {
	my $Document = safe_new \"print 'Hello World';";
	my $semi = $Document->find_first('Token::Structure');
	isa_ok( $semi, 'PPI::Token::Structure' );
	is( $semi->content, ';', 'Got expected token' );
	my $foo = PPI::Token::Word->new('foo');
	isa_ok( $foo, 'PPI::Token::Word' );
	is( $foo->content, 'foo', 'Created Word token' );
	$semi->insert_before( $foo );
	is( $Document->serialize, "print 'Hello World'foo;",
		'insert_before actually inserts' );
}


LINE_NUMBER: {
	my $document = safe_new \<<'END_PERL';


   foo
END_PERL
	my $words = $document->find('PPI::Token::Word');
	is( scalar @{$words}, 1, 'Found expected word token.' );
	is( $words->[0]->line_number, 3, 'Got correct line number.' );
}


LOGICAL_FILENAME: {
	# Double quoted so that we don't really have a "#line" at the beginning and
	# errors in this file itself aren't affected by this.
	my $document = safe_new \<<"END_PERL";


\#line 1 test-file
   foo
END_PERL
	my $words = $document->find('PPI::Token::Word');
	is( scalar @{$words}, 1, 'Found expected word token.' );
	is(
		$words->[0]->logical_filename,
		'test-file',
		'Got correct logical line number.',
	);
}


LOGICAL_LINE_NUMBER: {
	# Double quoted so that we don't really have a "#line" at the beginning and
	# errors in this file itself aren't affected by this.
	my $document = safe_new \<<"END_PERL";


\#line 1 test-file
   foo
END_PERL
	my $words = $document->find('PPI::Token::Word');
	is( scalar @{$words}, 1, 'Found expected word token.' );
	is( $words->[0]->logical_line_number, 1, 'Got correct logical line number.' );
}


VISUAL_COLUMN_NUMBER: {
	my $document = safe_new \<<"END_PERL";


\t foo
END_PERL
	my $tab_width = 5;
	$document->tab_width($tab_width);  # don't use a "usual" value.
	my $words = $document->find('PPI::Token::Word');
	is( scalar @{$words}, 1, 'Found expected word token.' );
	is(
		$words->[0]->visual_column_number,
		$tab_width + 2,
		'Got correct visual column number.',
	);
}


NAMESPACE: {
	# Default namespace is main
	my $doc1 = safe_new \"my \$x = 1;";
	my $sym1 = $doc1->find_first('Token::Symbol');
	is( $sym1->namespace, 'main', 'default namespace is main' );

	# Flat package
	my $doc2 = safe_new \"package Foo; my \$x = 1;";
	my $sym2 = $doc2->find_first('Token::Symbol');
	is( $sym2->namespace, 'Foo', 'flat package namespace' );

	# Multiple flat packages
	my $doc3 = safe_new \"package Foo; package Bar; my \$x = 1;";
	my $sym3 = $doc3->find_first('Token::Symbol');
	is( $sym3->namespace, 'Bar', 'later flat package overrides' );

	# Block form package
	my $doc4 = safe_new \"package Foo { my \$x = 1; }";
	my $sym4 = $doc4->find_first('Token::Symbol');
	is( $sym4->namespace, 'Foo', 'block package namespace' );

	# Block form package does not affect siblings after
	my $doc5 = safe_new \"package Foo { 1; } my \$x = 1;";
	my $sym5 = $doc5->find_first('Token::Symbol');
	is( $sym5->namespace, 'main', 'after block package reverts to main' );

	# Flat package persists past block package
	my $doc6 = safe_new \"package Foo; package Bar { 1; } my \$x = 1;";
	my $sym6 = $doc6->find_first('Token::Symbol');
	is( $sym6->namespace, 'Foo', 'flat package persists past block package' );

	# Nested block packages
	my $doc7 = safe_new \"package Foo { package Bar { my \$x = 1; } }";
	my $sym7 = $doc7->find_first('Token::Symbol');
	is( $sym7->namespace, 'Bar', 'nested block packages' );

	# Flat inside block
	my $doc8 = safe_new \"package Foo { package Bar; my \$x = 1; }";
	my $sym8 = $doc8->find_first('Token::Symbol');
	is( $sym8->namespace, 'Bar', 'flat package inside block package' );

	# Block with version
	my $doc9 = safe_new \"package Foo v1.2.3 { my \$x = 1; }";
	my $sym9 = $doc9->find_first('Token::Symbol');
	is( $sym9->namespace, 'Foo', 'block package with version' );

	# Package statement itself reports its declared namespace (existing behavior)
	my $doc10 = safe_new \"package Foo;";
	my $pkg10 = $doc10->find_first('Statement::Package');
	is( $pkg10->namespace, 'Foo', 'Package->namespace still returns declared name' );
}
