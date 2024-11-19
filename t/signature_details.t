#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 16 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use B 'perlstring';

use PPI ();
use PPI::Dumper;

sub test_document;

BASE_SIGNATURE_EXAMPLE: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($left, $right) {}
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

UNNAMED_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($first, $, $third) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($first, $, $third) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($first, $, $third)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$first, $, $third',
		'PPI::Token::Symbol',         '$first',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$third',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "unnamed argument";
}

POSITIONAL_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($left, $right = 0) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($left, $right = 0) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($left, $right = 0)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$left, $right = 0',
		'PPI::Token::Symbol',         '$left',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$right',
		'PPI::Token::Operator',       '=',
		'PPI::Token::Number',         '0',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "positional argument";
}

INCREMENT_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($thing, $id = $auto_id++) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($thing, $id = $auto_id++) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($thing, $id = $auto_id++)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$thing, $id = $auto_id++',
		'PPI::Token::Symbol',         '$thing',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$id',
		'PPI::Token::Operator',       '=',
		'PPI::Token::Symbol',         '$auto_id',
		'PPI::Token::Operator',       '++',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "increment argument";
}

DEFAULT_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($first_name, $surname, $nickname = $first_name) {}
END_PERL
	  [
		'PPI::Statement::Sub' =>
		  'sub foo ($first_name, $surname, $nickname = $first_name) {}',    #
		'PPI::Token::Word', 'sub',
		'PPI::Token::Word', 'foo',
		'PPI::Structure::Signature' =>
		  '($first_name, $surname, $nickname = $first_name)',
		'PPI::Token::Structure', '(',
		'PPI::Statement::Expression' =>
		  '$first_name, $surname, $nickname = $first_name',
		'PPI::Token::Symbol',    '$first_name',
		'PPI::Token::Operator',  ',',
		'PPI::Token::Symbol',    '$surname',
		'PPI::Token::Operator',  ',',
		'PPI::Token::Symbol',    '$nickname',
		'PPI::Token::Operator',  '=',
		'PPI::Token::Symbol',    '$first_name',
		'PPI::Token::Structure', ')',
		'PPI::Structure::Block', '{}',
		'PPI::Token::Structure', '{',
		'PPI::Token::Structure', '}',
	  ],
	  "default argument";
}

UNDEF_DEFAULT_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($name //= "world") {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($name //= "world") {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($name //= "world")',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$name //= "world"',
		'PPI::Token::Symbol',         '$name',
		'PPI::Token::Operator',       '//=',
		'PPI::Token::Quote::Double',  '"world"',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "undef default argument";
}

OR_DEFAULT_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($name ||= "world") {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($name ||= "world") {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($name ||= "world")',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$name ||= "world"',
		'PPI::Token::Symbol',         '$name',
		'PPI::Token::Operator',       '||=',
		'PPI::Token::Quote::Double',  '"world"',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "or default argument";
}

NAMELESS_OPTIONAL_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($thing, $ = 1) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($thing, $ = 1) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($thing, $ = 1)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$thing, $ = 1',
		'PPI::Token::Symbol',         '$thing',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Cast',           '$',
		'PPI::Token::Operator',       '=',
		'PPI::Token::Number',         '1',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "nameless optional argument";
}

VALUELESS_OPTIONAL_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($thing, $=) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($thing, $=) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($thing, $=)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$thing, $=',
		'PPI::Token::Symbol',         '$thing',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$',
		'PPI::Token::Operator',       '=',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "valueless optional argument";
}

SLURPY_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($filter, @inputs) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($filter, @inputs) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($filter, @inputs)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$filter, @inputs',
		'PPI::Token::Symbol',         '$filter',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '@inputs',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "slurpy argument";
}

NAMELESS_SLURPY_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($thing, @) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($thing, @) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($thing, @)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$thing, @',
		'PPI::Token::Symbol',         '$thing',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '@',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "nameless slurpy argument";
}

SLURPY_HASH_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($filter, %inputs) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($filter, %inputs) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($filter, %inputs)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$filter, %inputs',
		'PPI::Token::Symbol',         '$filter',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '%inputs',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "slurpy hash argument";
}

NAMELESS_SLURPY_HASH_ARGUMENT: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo ($thing, %) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub foo ($thing, %) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($thing, %)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$thing, %',
		'PPI::Token::Symbol',         '$thing',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '%',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "nameless slurpy hash argument";
}

EMPTY_SIGNATURE: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo () {}
END_PERL
	  [
		'PPI::Statement::Sub',       'sub foo () {}',
		'PPI::Token::Word',          'sub',
		'PPI::Token::Word',          'foo',
		'PPI::Structure::Signature', '()',
		'PPI::Token::Structure',     '(',
		'PPI::Token::Structure',     ')',
		'PPI::Structure::Block',     '{}',
		'PPI::Token::Structure',     '{',
		'PPI::Token::Structure',     '}',
	  ],
	  "empty signature";
}

PROTOTYPE_SIGNATURE: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo :prototype($$) ($left, $right) {}
END_PERL
	  [
		'PPI::Statement::Sub',   'sub foo :prototype($$) ($left, $right) {}',  #
		'PPI::Token::Word',      'sub',
		'PPI::Token::Word',      'foo',
		'PPI::Token::Operator',  ':',
		'PPI::Token::Attribute', 'prototype($$)',
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
	  "prototype signature";
}

COMPLEX_SIGNATURE_EXAMPLE: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub foo :lvalue ($x, $y = 1, @z) { ... }
END_PERL
	  [
		'PPI::Statement::Sub',   'sub foo :lvalue ($x, $y = 1, @z) { ... }',   #
		'PPI::Token::Word',      'sub',
		'PPI::Token::Word',      'foo',
		'PPI::Token::Operator',  ':',
		'PPI::Token::Attribute', 'lvalue',
		'PPI::Structure::Signature',  '($x, $y = 1, @z)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$x, $y = 1, @z',
		'PPI::Token::Symbol',         '$x',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$y',
		'PPI::Token::Operator',       '=',
		'PPI::Token::Number',         '1',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '@z',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{ ... }',
		'PPI::Token::Structure',      '{',
		'PPI::Statement',             '...',
		'PPI::Token::Operator',       '...',
		'PPI::Token::Structure',      '}',
	  ],
	  "complex signature example";
}

### TODO from ppi_token_unknown.t , deduplicate

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
