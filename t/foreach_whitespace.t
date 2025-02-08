#!/usr/bin/perl

BEGIN { chdir ".." if -d "../t" and -d "../lib" }
use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 1 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use B 'perlstring';

use PPI ();
use PPI::Dumper;

sub test_document;

BASE_SIGNATURE_EXAMPLE: {
	local $TODO = "crashes";
	test_document
	  <<'END_PERL',
		for my $ s ( qw( a b ) ) { say $s }
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($left, $right) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($left, $right)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$left, $right',
		'PPI::Token::Symbol',         '$left',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$right',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "base signature example";
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
		return;
	};
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref($_), $_->content } @$tokens ];

	return if    #
	  is_deeply( $tokens, $expected, main_level_line . $msg );

	diag ">>> $code -- $msg\n";
	diag( PPI::Dumper->new($d)->string );
	diag one_line_explain $tokens;
	diag one_line_explain $expected;

	return;
}
