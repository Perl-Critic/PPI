#!/usr/bin/perl

# Unit testing for PPI::Element

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 118 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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


INSERT_BEFORE_MULTIPLE_TOKENS: {
	local $TODO = "insert_before does not yet accept multiple elements";
	my $Document = safe_new \"print 'Hello World';";
	my $string = $Document->find_first('Token::Quote');
	my $foo = PPI::Token::Word->new('foo');
	my $bar = PPI::Token::Word->new('bar');
	my $result = $string->insert_before( $foo, $bar );
	ok( $result, 'insert_before accepts multiple tokens' );
	is( $Document->serialize, "print foobar'Hello World';",
		'insert_before inserts multiple tokens in order' );
}


INSERT_AFTER_MULTIPLE_TOKENS: {
	local $TODO = "insert_after does not yet accept multiple elements";
	my $Document = safe_new \"print 'Hello World';";
	my $string = $Document->find_first('Token::Quote');
	my $foo = PPI::Token::Word->new('foo');
	my $bar = PPI::Token::Word->new('bar');
	my $result = $string->insert_after( $foo, $bar );
	ok( $result, 'insert_after accepts multiple tokens' );
	is( $Document->serialize, "print 'Hello World'foobar;",
		'insert_after inserts multiple tokens in order' );
}


INSERT_BEFORE_MULTIPLE_STATEMENTS: {
	local $TODO = "insert_before does not yet accept multiple elements";
	my $Document = safe_new \"my \$x = 1; my \$y = 2;";
	my @stmts = $Document->schildren;
	is( scalar @stmts, 2, 'Found two statements' );
	my $new1 = PPI::Document->new(\"my \$a = 0;")->schild(0)->remove;
	my $ws   = PPI::Token::Whitespace->new(' ');
	my $result = $stmts[1]->insert_before( $new1, $ws );
	ok( $result, 'insert_before accepts multiple elements before a statement' );
	is( $Document->serialize, "my \$x = 1; my \$a = 0; my \$y = 2;",
		'insert_before inserts statement + whitespace in order' );
}


INSERT_AFTER_MULTIPLE_STATEMENTS: {
	local $TODO = "insert_after does not yet accept multiple elements";
	my $Document = safe_new \"my \$x = 1; my \$y = 2;";
	my @stmts = $Document->schildren;
	is( scalar @stmts, 2, 'Found two statements' );
	my $ws   = PPI::Token::Whitespace->new(' ');
	my $new1 = PPI::Document->new(\"my \$a = 0;")->schild(0)->remove;
	my $result = $stmts[0]->insert_after( $ws, $new1 );
	ok( $result, 'insert_after accepts multiple elements after a statement' );
	is( $Document->serialize, "my \$x = 1; my \$a = 0; my \$y = 2;",
		'insert_after inserts whitespace + statement in order' );
}


INSERT_BEFORE_STRING: {
	local $TODO = "insert_before does not yet accept strings";
	my $Document = safe_new \"my \$x = 1;";
	my $stmt = $Document->schild(0);
	my $result = $stmt->insert_before("my \$y = 2; ");
	ok( $result, 'insert_before accepts a code string' );
	is( $Document->serialize, "my \$y = 2; my \$x = 1;",
		'insert_before parses and inserts code string' );
}


INSERT_AFTER_STRING: {
	local $TODO = "insert_after does not yet accept strings";
	my $Document = safe_new \"my \$x = 1;";
	my $stmt = $Document->schild(0);
	my $result = $stmt->insert_after(" my \$y = 2;");
	ok( $result, 'insert_after accepts a code string' );
	is( $Document->serialize, "my \$x = 1; my \$y = 2;",
		'insert_after parses and inserts code string' );
}


INSERT_BEFORE_STRING_TOKEN: {
	local $TODO = "insert_before does not yet accept strings";
	my $Document = safe_new \"print 'Hello';";
	my $string = $Document->find_first('Token::Quote');
	my $result = $string->insert_before("foo ");
	ok( $result, 'insert_before accepts a code string on a token' );
	is( $Document->serialize, "print foo 'Hello';",
		'insert_before parses and inserts string before token' );
}


INSERT_AFTER_STRING_TOKEN: {
	local $TODO = "insert_after does not yet accept strings";
	my $Document = safe_new \"print 'Hello';";
	my $string = $Document->find_first('Token::Quote');
	my $result = $string->insert_after(" . 'World'");
	ok( $result, 'insert_after accepts a code string on a token' );
	is( $Document->serialize, "print 'Hello' . 'World';",
		'insert_after parses and inserts string after token' );
}


INSERT_BEFORE_FRAGMENT: {
	local $TODO = "insert_before does not yet accept fragments";
	my $Document = safe_new \"my \$x = 1;";
	my $stmt = $Document->schild(0);
	my $source = PPI::Document->new(\"my \$y = 2; ");
	my $frag = bless $source, 'PPI::Document::Fragment';
	isa_ok( $frag, 'PPI::Document::Fragment' );
	my $result = $stmt->insert_before($frag);
	ok( $result, 'insert_before accepts a Document::Fragment' );
	is( $Document->serialize, "my \$y = 2; my \$x = 1;",
		'insert_before inserts fragment children' );
}


INSERT_AFTER_FRAGMENT: {
	local $TODO = "insert_after does not yet accept fragments";
	my $Document = safe_new \"my \$x = 1;";
	my $stmt = $Document->schild(0);
	my $source = PPI::Document->new(\" my \$y = 2;");
	my $frag = bless $source, 'PPI::Document::Fragment';
	isa_ok( $frag, 'PPI::Document::Fragment' );
	my $result = $stmt->insert_after($frag);
	ok( $result, 'insert_after accepts a Document::Fragment' );
	is( $Document->serialize, "my \$x = 1; my \$y = 2;",
		'insert_after inserts fragment children' );
}


INSERT_BEFORE_UNDEF_ON_INVALID: {
	my $Document = safe_new \"print 'Hello';";
	my $string = $Document->find_first('Token::Quote');
	my $result = $string->insert_before();
	is( $result, undef, 'insert_before with no args returns undef' );
}


INSERT_AFTER_UNDEF_ON_INVALID: {
	my $Document = safe_new \"print 'Hello';";
	my $string = $Document->find_first('Token::Quote');
	my $result = $string->insert_after();
	is( $result, undef, 'insert_after with no args returns undef' );
}
