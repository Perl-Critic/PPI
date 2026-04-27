#!/usr/bin/perl

# Unit testing for PPI::Element

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 125 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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


INSERT_AFTER_RETURN_VALUES: {
	my $doc = safe_new \"my \$x = 1;";
	my $st = $doc->find_first('Statement');
	isa_ok( $st, 'PPI::Statement' );

	is( $st->insert_after(undef), undef,
		'insert_after returns undef for undef arg' );
	is( $st->insert_after('string'), undef,
		'insert_after returns undef for non-Element arg' );
	is( $st->insert_after(42), undef,
		'insert_after returns undef for numeric arg' );

	my $ws = PPI::Token::Whitespace->new(' ');
	is( $st->insert_after($ws), 1,
		'insert_after returns 1 on success' );
}


INSERT_BEFORE_RETURN_VALUES: {
	my $doc = safe_new \"my \$x = 1;";
	my $st = $doc->find_first('Statement');
	isa_ok( $st, 'PPI::Statement' );

	is( $st->insert_before(undef), undef,
		'insert_before returns undef for undef arg' );
	is( $st->insert_before('string'), undef,
		'insert_before returns undef for non-Element arg' );
	is( $st->insert_before(42), undef,
		'insert_before returns undef for numeric arg' );

	my $ws = PPI::Token::Whitespace->new(' ');
	is( $st->insert_before($ws), 1,
		'insert_before returns 1 on success' );
}


STATEMENT_INSERT_AFTER: {
	my $doc = safe_new \"my \$x = 1;";
	my $st = $doc->find_first('Statement');
	isa_ok( $st, 'PPI::Statement' );

	my $new_st = PPI::Statement->new;
	$new_st->add_element( PPI::Token::Word->new('foo') );
	is( $st->insert_after($new_st), 1,
		'Statement insert_after accepts another Statement' );

	my $ws = PPI::Token::Whitespace->new("\n");
	is( $st->insert_after($ws), 1,
		'Statement insert_after accepts non-significant Token' );

	my $word = PPI::Token::Word->new('bar');
	is( $st->insert_after($word), '',
		'Statement insert_after rejects significant Token' );

	my $struct = PPI::Structure->new( PPI::Token::Structure->new('{') );
	is( $st->insert_after($struct), '',
		'Statement insert_after rejects Structure' );
}


STATEMENT_INSERT_BEFORE: {
	my $doc = safe_new \"my \$x = 1;";
	my $st = $doc->find_first('Statement');
	isa_ok( $st, 'PPI::Statement' );

	my $new_st = PPI::Statement->new;
	$new_st->add_element( PPI::Token::Word->new('foo') );
	is( $st->insert_before($new_st), 1,
		'Statement insert_before accepts another Statement' );

	my $ws = PPI::Token::Whitespace->new("\n");
	is( $st->insert_before($ws), 1,
		'Statement insert_before accepts non-significant Token' );

	my $word = PPI::Token::Word->new('bar');
	is( $st->insert_before($word), '',
		'Statement insert_before rejects significant Token' );

	my $struct = PPI::Structure->new( PPI::Token::Structure->new('{') );
	is( $st->insert_before($struct), '',
		'Statement insert_before rejects Structure' );
}


STRUCTURE_INSERT_AFTER: {
	my $doc = safe_new \"print( 'Hello' );";
	my $struct = $doc->find_first('Structure');
	isa_ok( $struct, 'PPI::Structure' );

	my $word = PPI::Token::Word->new('foo');
	is( $struct->insert_after($word), 1,
		'Structure insert_after accepts any Token (significant)' );

	my $ws = PPI::Token::Whitespace->new(' ');
	is( $struct->insert_after($ws), 1,
		'Structure insert_after accepts non-significant Token' );

	my $struct2 = PPI::Structure->new( PPI::Token::Structure->new('(') );
	is( $struct->insert_after($struct2), 1,
		'Structure insert_after accepts another Structure' );

	my $new_st = PPI::Statement->new;
	$new_st->add_element( PPI::Token::Word->new('bar') );
	is( $struct->insert_after($new_st), '',
		'Structure insert_after rejects Statement' );
}


STRUCTURE_INSERT_BEFORE: {
	my $doc = safe_new \"print( 'Hello' );";
	my $struct = $doc->find_first('Structure');
	isa_ok( $struct, 'PPI::Structure' );

	my $word = PPI::Token::Word->new('foo');
	is( $struct->insert_before($word), 1,
		'Structure insert_before accepts any Token (significant)' );

	my $ws = PPI::Token::Whitespace->new(' ');
	is( $struct->insert_before($ws), 1,
		'Structure insert_before accepts non-significant Token' );

	my $struct2 = PPI::Structure->new( PPI::Token::Structure->new('(') );
	is( $struct->insert_before($struct2), 1,
		'Structure insert_before accepts another Structure' );

	my $new_st = PPI::Statement->new;
	$new_st->add_element( PPI::Token::Word->new('bar') );
	is( $struct->insert_before($new_st), '',
		'Structure insert_before rejects Statement' );
}


DOCUMENT_INSERT: {
	my $doc = safe_new \"my \$x = 1;";
	isa_ok( $doc, 'PPI::Document' );

	my $ws = PPI::Token::Whitespace->new(' ');
	is( $doc->insert_before($ws), undef,
		'Document insert_before always returns undef' );
	is( $doc->insert_after($ws), undef,
		'Document insert_after always returns undef' );
}


INSERT_AFTER_ACCEPTS_SINGLE_ELEMENT: {
	my $doc = safe_new \"my \$x = 1;";
	my $st = $doc->find_first('Statement');
	isa_ok( $st, 'PPI::Statement' );

	my $ws1 = PPI::Token::Whitespace->new(' ');
	my $ws2 = PPI::Token::Whitespace->new("\n");
	is( $st->insert_after($ws1, $ws2), 1,
		'insert_after with multiple args only inserts the first' );

	my $serialized = $doc->serialize;
	ok( $serialized =~ / $/, 'only first element was inserted' );
}


INSERT_BEFORE_ACCEPTS_SINGLE_ELEMENT: {
	my $doc = safe_new \"my \$x = 1;";
	my $st = $doc->find_first('Statement');
	isa_ok( $st, 'PPI::Statement' );

	my $ws1 = PPI::Token::Whitespace->new(' ');
	my $ws2 = PPI::Token::Whitespace->new("\n");
	is( $st->insert_before($ws1, $ws2), 1,
		'insert_before with multiple args only inserts the first' );

	my $serialized = $doc->serialize;
	ok( $serialized =~ /^ /, 'only first element was inserted' );
}
