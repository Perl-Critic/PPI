#!/usr/bin/perl

# Unit testing for PPI::Element

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 58;
use Test::NoWarnings;
use PPI;


__INSERT_AFTER: {
	my $Document = PPI::Document->new( \"print 'Hello World';" );
	isa_ok( $Document, 'PPI::Document' );
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
	my $Document = PPI::Document->new( \"print 'Hello World';" );
	isa_ok( $Document, 'PPI::Document' );
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
	my $Document = PPI::Document->new( \'( [ thingy ] ); $blarg = 1' );
	isa_ok( $Document, 'PPI::Document' );
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
	my $document = PPI::Document->new(\<<'END_PERL');


   foo
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $words = $document->find('PPI::Token::Word');
	is( scalar @{$words}, 1, 'Found expected word token.' );
	is( $words->[0]->column_number, 4, 'Got correct column number.' );
}


DESCENDANT_OF: {
	my $Document = PPI::Document->new( \'( [ thingy ] ); $blarg = 1' );
	isa_ok( $Document, 'PPI::Document' );
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
	my $Document = PPI::Document->new( \"print 'Hello World';" );
	isa_ok( $Document, 'PPI::Document' );
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
	my $Document = PPI::Document->new( \"print 'Hello World';" );
	isa_ok( $Document, 'PPI::Document' );
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
	my $document = PPI::Document->new(\<<'END_PERL');


   foo
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $words = $document->find('PPI::Token::Word');
	is( scalar @{$words}, 1, 'Found expected word token.' );
	is( $words->[0]->line_number, 3, 'Got correct line number.' );
}


LOGICAL_FILENAME: {
	# Double quoted so that we don't really have a "#line" at the beginning and
	# errors in this file itself aren't affected by this.
	my $document = PPI::Document->new(\<<"END_PERL");


\#line 1 test-file
   foo
END_PERL

	isa_ok( $document, 'PPI::Document' );
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
	my $document = PPI::Document->new(\<<"END_PERL");


\#line 1 test-file
   foo
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $words = $document->find('PPI::Token::Word');
	is( scalar @{$words}, 1, 'Found expected word token.' );
	is( $words->[0]->logical_line_number, 1, 'Got correct logical line number.' );
}


VISUAL_COLUMN_NUMBER: {
	my $document = PPI::Document->new(\<<"END_PERL");


\t foo
END_PERL

	isa_ok( $document, 'PPI::Document' );
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
