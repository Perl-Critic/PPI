#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 7 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use B 'perlstring';

use PPI ();
use PPI::Dumper;

sub test_document;

SIMPLE_BLOCK_KEYWORD: {
	local $TODO = "custom_keywords not yet implemented";
	test_document
	  [ custom_keywords => { defer => {} } ],
	  <<'END_PERL',
		defer { say "cleanup" }
END_PERL
	  [
		'PPI::Statement::Compound',   'defer { say "cleanup" }',
		'PPI::Token::Word',           'defer',
		'PPI::Structure::Block',      '{ say "cleanup" }',
		'PPI::Token::Structure',      '{',
		'PPI::Statement',             'say "cleanup"',
		'PPI::Token::Word',           'say',
		'PPI::Token::Quote::Double',  '"cleanup"',
		'PPI::Token::Structure',      '}',
	  ],
	  "custom keyword 'defer' parsed as compound statement with block";
}

KEYWORD_WITH_CONTINUATION: {
	local $TODO = "custom_keywords not yet implemented";
	test_document
	  [ custom_keywords => { try => { continuation => ['catch', 'finally'] } } ],
	  <<'END_PERL',
		try { risky() } catch { recover() } finally { cleanup() }
END_PERL
	  [
		'PPI::Statement::Compound',  'try { risky() } catch { recover() } finally { cleanup() }',
		'PPI::Token::Word',          'try',
		'PPI::Structure::Block',     '{ risky() }',
		'PPI::Token::Structure',     '{',
		'PPI::Statement',            'risky()',
		'PPI::Token::Word',          'risky',
		'PPI::Structure::List',      '()',
		'PPI::Token::Structure',     '(',
		'PPI::Token::Structure',     ')',
		'PPI::Token::Structure',     '}',
		'PPI::Token::Word',          'catch',
		'PPI::Structure::Block',     '{ recover() }',
		'PPI::Token::Structure',     '{',
		'PPI::Statement',            'recover()',
		'PPI::Token::Word',          'recover',
		'PPI::Structure::List',      '()',
		'PPI::Token::Structure',     '(',
		'PPI::Token::Structure',     ')',
		'PPI::Token::Structure',     '}',
		'PPI::Token::Word',          'finally',
		'PPI::Structure::Block',     '{ cleanup() }',
		'PPI::Token::Structure',     '{',
		'PPI::Statement',            'cleanup()',
		'PPI::Token::Word',          'cleanup',
		'PPI::Structure::List',      '()',
		'PPI::Token::Structure',     '(',
		'PPI::Token::Structure',     ')',
		'PPI::Token::Structure',     '}',
	  ],
	  "custom keyword 'try' with catch/finally continuations";
}

CONTINUATION_WITH_PARENS: {
	local $TODO = "custom_keywords not yet implemented";
	test_document
	  [ custom_keywords => { try => { continuation => ['catch'] } } ],
	  <<'END_PERL',
		try { die "oops" } catch ($e) { warn $e }
END_PERL
	  [
		'PPI::Statement::Compound',   'try { die "oops" } catch ($e) { warn $e }',
		'PPI::Token::Word',           'try',
		'PPI::Structure::Block',      '{ die "oops" }',
		'PPI::Token::Structure',      '{',
		'PPI::Statement::Break',      'die "oops"',
		'PPI::Token::Word',           'die',
		'PPI::Token::Quote::Double',  '"oops"',
		'PPI::Token::Structure',      '}',
		'PPI::Token::Word',           'catch',
		'PPI::Structure::List',       '($e)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$e',
		'PPI::Token::Symbol',         '$e',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{ warn $e }',
		'PPI::Token::Structure',      '{',
		'PPI::Statement',             'warn $e',
		'PPI::Token::Word',           'warn',
		'PPI::Token::Symbol',         '$e',
		'PPI::Token::Structure',      '}',
	  ],
	  "custom keyword continuation with round parens";
}

KEYWORD_FOLLOWED_BY_NORMAL: {
	local $TODO = "custom_keywords not yet implemented";
	test_document
	  [ custom_keywords => { defer => {} } ],
	  <<'END_PERL',
		defer { 1 }
		my $x = 2;
END_PERL
	  [
		'PPI::Statement::Compound',   'defer { 1 }',
		'PPI::Token::Word',           'defer',
		'PPI::Structure::Block',      '{ 1 }',
		'PPI::Token::Structure',      '{',
		'PPI::Statement',             '1',
		'PPI::Token::Number',         '1',
		'PPI::Token::Structure',      '}',
		'PPI::Statement::Variable',   'my $x = 2;',
		'PPI::Token::Word',           'my',
		'PPI::Token::Symbol',         '$x',
		'PPI::Token::Operator',       '=',
		'PPI::Token::Number',         '2',
		'PPI::Token::Structure',      ';',
	  ],
	  "custom keyword block ends before next statement";
}

ENV_CUSTOM_KEYWORDS: {
	local $TODO = "custom_keywords not yet implemented";
	local $ENV{PPI_CUSTOM_KEYWORDS} = 'defer: {}';
	test_document
	  <<'END_PERL',
		defer { 1 }
END_PERL
	  [
		'PPI::Statement::Compound', 'defer { 1 }',
		'PPI::Token::Word',         'defer',
		'PPI::Structure::Block',    '{ 1 }',
		'PPI::Token::Structure',    '{',
		'PPI::Statement',           '1',
		'PPI::Token::Number',       '1',
		'PPI::Token::Structure',    '}',
	  ],
	  "PPI_CUSTOM_KEYWORDS env var";
}

CUSTOM_INCLUDE_ENABLES_KEYWORD: {
	local $TODO = "custom_keywords not yet implemented";
	test_document
	  [ custom_feature_includes =>
		  { 'Syntax::Keyword::Defer' =>
			  { custom_keywords => { defer => {} } } } ],
	  <<'END_PERL',
		use Syntax::Keyword::Defer;
		defer { 1 }
END_PERL
	  [
		'PPI::Statement::Include',  'use Syntax::Keyword::Defer;',
		'PPI::Token::Word',         'use',
		'PPI::Token::Word',         'Syntax::Keyword::Defer',
		'PPI::Token::Structure',    ';',
		'PPI::Statement::Compound', 'defer { 1 }',
		'PPI::Token::Word',         'defer',
		'PPI::Structure::Block',    '{ 1 }',
		'PPI::Token::Structure',    '{',
		'PPI::Statement',           '1',
		'PPI::Token::Number',       '1',
		'PPI::Token::Structure',    '}',
	  ],
	  "custom_feature_includes activates custom keyword";
}

CUSTOM_CB_ENABLES_KEYWORD: {
	local $TODO = "custom_keywords not yet implemented";
	test_document
	  [
		custom_feature_include_cb => sub {
			my ($inc) = @_;
			return { custom_keywords => { defer => {} } }
			  if $inc->module eq 'Syntax::Keyword::Defer';
			return;
		}
	  ],
	  <<'END_PERL',
		use Syntax::Keyword::Defer;
		defer { 1 }
END_PERL
	  [
		'PPI::Statement::Include',  'use Syntax::Keyword::Defer;',
		'PPI::Token::Word',         'use',
		'PPI::Token::Word',         'Syntax::Keyword::Defer',
		'PPI::Token::Structure',    ';',
		'PPI::Statement::Compound', 'defer { 1 }',
		'PPI::Token::Word',         'defer',
		'PPI::Structure::Block',    '{ 1 }',
		'PPI::Token::Structure',    '{',
		'PPI::Statement',           '1',
		'PPI::Token::Number',       '1',
		'PPI::Token::Structure',    '}',
	  ],
	  "custom_feature_include_cb activates custom keyword";
}

### helpers from feature_tracking.t

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

	my $d      = PPI::Document->new( \$code, @{$args} ) or die explain $@;
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref($_), $_->content } @$tokens ];

	my $ok = is_deeply( $tokens, $expected, main_level_line . $msg );
	if ( !$ok ) {
		diag ">>> $code -- $msg\n";
		diag( PPI::Dumper->new($d)->string );
		diag one_line_explain $tokens;
		diag one_line_explain $expected;
	}

	return;
}
