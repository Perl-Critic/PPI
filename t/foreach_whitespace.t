#!/usr/bin/perl

BEGIN { chdir ".." if -d "../t" and -d "../lib" }
use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 8 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use B 'perlstring';

use PPI ();
use PPI::Dumper;

sub test_document;

BASE_SPACE_SYMBOL: {
	test_document    #
	  '$ s',         #
	  [
		'PPI::Statement',     '$ s',    #
		'PPI::Token::Symbol', '$ s',
	  ],
	  "base space symbol example";
}

FOR_LOOP: {
	test_document
	  'for my $ s ( qw( a b ) ) { say $s }',
	  [
		'PPI::Statement::Compound',     'for my $ s ( qw( a b ) ) { say $s }',
		'PPI::Token::Word',             'for',
		'PPI::Token::Word',             'my',
		'PPI::Token::Symbol',           '$ s',
		'PPI::Structure::List',         '( qw( a b ) )',
		'PPI::Token::Structure',        '(',
		'PPI::Statement',               'qw( a b )',
		'PPI::Token::QuoteLike::Words', 'qw( a b )',
		'PPI::Token::Structure',        ')',
		'PPI::Structure::Block',        '{ say $s }',
		'PPI::Token::Structure',        '{',
		'PPI::Statement',               'say $s',
		'PPI::Token::Word',             'say',
		'PPI::Token::Symbol',           '$s',
		'PPI::Token::Structure',        '}',
	  ],
	  "space symboln in for loop";
}

SIGIL_WITH_TRASH: {
	test_document
	  '$ \"8;b',
	  [
		'PPI::Statement',            '$ \\"8;b',
		'PPI::Token::Cast',          '$',
		'PPI::Token::Cast',          '\\',
		'PPI::Token::Quote::Double', '"8;b',
	  ],
	  "sigil with a space and trash that is NOT a symbol";
}

SIGIL_WITH_TABS_AND_TRAIL: {
	test_document    #
	  '$ 	 b 	 ',    #
	  [              #
		'PPI::Statement',     "\$ \t b",
		'PPI::Token::Symbol', "\$ \t b",
	  ],
	  "sigil with tabs and trailing space";
}

sub one_line_explain {
	my ($data) = @_;
	my @explain = explain $data;
	s/\n//g for @explain;
	return join "", @explain;
}

sub main_level_line {
	return "" if not $TODO;
	my @outer_final;
	my $level = 0;
	while ( my @outer = caller( $level++ ) ) {
		@outer_final = @outer;
	}
	return "l $outer_final[2] - ";
}

sub test_document {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $args = ref $_[0] eq "ARRAY" ? shift : [];
	my ( $code, $expected, $msg ) = @_;
	$msg = perlstring $code if !defined $msg;

	my $d = PPI::Document->new( \$code, @{$args} ) or do {
		diag explain $@;
		fail "PPI::Document->new failed";
		fail "code round trips";
		return;
	};
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref($_), $_->content } @$tokens ];

	is $d->serialize, $code, "code round trips";

	return if    #
	  is_deeply( $tokens, $expected, main_level_line . $msg );

	diag ">>> $code -- $msg\n";
	diag( PPI::Dumper->new($d)->string );
	diag one_line_explain $tokens;
	diag one_line_explain $expected;

	return;
}
