#!/usr/bin/perl

# Unit testing for PPI::Element

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 100 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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


INSERT_AFTER_RETURN_VALUES: {
	my $Document = safe_new \"print 'Hello World';";
	my $string = $Document->find_first('Token::Quote');

	# undef when no argument provided
	my $result_none = $string->insert_after();
	is( $result_none, undef, 'insert_after returns undef with no args' );

	# undef when non-Element argument provided
	my $result_bad = $string->insert_after('not an element');
	is( $result_bad, undef, 'insert_after returns undef for non-Element arg' );

	# true on success
	my $foo = PPI::Token::Word->new('foo');
	my $result_ok = $string->insert_after($foo);
	ok( $result_ok, 'insert_after returns true on success' );
}


INSERT_BEFORE_RETURN_VALUES: {
	my $Document = safe_new \"print 'Hello World';";
	my $semi = $Document->find_first('Token::Structure');

	# undef when no argument provided
	my $result_none = $semi->insert_before();
	is( $result_none, undef, 'insert_before returns undef with no args' );

	# undef when non-Element argument provided
	my $result_bad = $semi->insert_before('not an element');
	is( $result_bad, undef, 'insert_before returns undef for non-Element arg' );

	# true on success
	my $foo = PPI::Token::Word->new('foo');
	my $result_ok = $semi->insert_before($foo);
	ok( $result_ok, 'insert_before returns true on success' );
}


STATEMENT_INSERT_AFTER: {
	my $Document = safe_new \"print 'Hello World'; die;";
	my $stmt = $Document->find_first('Statement');

	# Statements accept other statements
	my $donor = PPI::Document->new(\"warn;");
	my $new_stmt = $donor->find_first('Statement')->remove;
	my $result = $stmt->insert_after($new_stmt);
	ok( $result, 'Statement insert_after accepts a Statement' );

	# Statements accept non-significant tokens (whitespace)
	my $ws = PPI::Token::Whitespace->new(' ');
	$result = $stmt->insert_after($ws);
	ok( $result, 'Statement insert_after accepts non-significant Token' );

	# Statements reject significant tokens
	my $word = PPI::Token::Word->new('foo');
	$result = $stmt->insert_after($word);
	is( $result, '', 'Statement insert_after rejects significant Token' );
}


STATEMENT_INSERT_BEFORE: {
	my $Document = safe_new \"print 'Hello World'; die;";
	my @stmts = @{ $Document->find('Statement') || [] };
	my $last_stmt = $stmts[-1];

	# Statements accept other statements
	my $new_stmt = PPI::Statement->new(
		PPI::Token::Word->new('warn'),
		PPI::Token::Structure->new(';'),
	);
	my $result = $last_stmt->insert_before($new_stmt);
	ok( $result, 'Statement insert_before accepts a Statement' );

	# Statements accept non-significant tokens (whitespace)
	my $ws = PPI::Token::Whitespace->new(' ');
	$result = $last_stmt->insert_before($ws);
	ok( $result, 'Statement insert_before accepts non-significant Token' );

	# Statements reject significant tokens
	my $word = PPI::Token::Word->new('foo');
	$result = $last_stmt->insert_before($word);
	is( $result, '', 'Statement insert_before rejects significant Token' );
}


DOCUMENT_INSERT: {
	my $Document = safe_new \"print 1;";

	my $result_after = $Document->insert_after(PPI::Token::Word->new('foo'));
	is( $result_after, undef, 'Document insert_after returns undef' );

	my $result_before = $Document->insert_before(PPI::Token::Word->new('foo'));
	is( $result_before, undef, 'Document insert_before returns undef' );
}


INSERT_AFTER_ACCEPTS_SINGLE_ELEMENT: {
	# $TODO: The documentation signature says insert_after(@Elements) implying
	# multiple elements, but the method only processes a single element.
	# The docs should use $Element (singular) instead.
	my $Document = safe_new \"my \$x = 1;";
	my $number = $Document->find_first('Token::Number');

	my $foo = PPI::Token::Word->new('foo');
	my $bar = PPI::Token::Word->new('bar');
	$number->insert_after($foo, $bar);
	is( $Document->serialize, "my \$x = 1foo;",
		'insert_after only inserts the first element, ignoring extras' );
	ok( ! $bar->parent,
		'insert_after does not attach second element to any parent' );
}


INSERT_BEFORE_ACCEPTS_SINGLE_ELEMENT: {
	# $TODO: The documentation signature says insert_before(@Elements) implying
	# multiple elements, but the method only processes a single element.
	# The docs should use $Element (singular) instead.
	my $Document = safe_new \"my \$x = 1;";
	my $semi = $Document->find_first('Token::Structure');

	my $foo = PPI::Token::Word->new('foo');
	my $bar = PPI::Token::Word->new('bar');
	$semi->insert_before($foo, $bar);
	is( $Document->serialize, "my \$x = 1foo;",
		'insert_before only inserts the first element, ignoring extras' );
	ok( ! $bar->parent,
		'insert_before does not attach second element to any parent' );
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
