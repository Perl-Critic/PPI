#!/usr/bin/perl

# Test that Helper.pm exports generalized test_document and test_statement

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 8 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use Helper qw( test_document test_statement );
use PPI ();

# test_statement: with explicit Statement class in expected
test_statement(
	'my $x = 1;',
	[
		'PPI::Statement::Variable' => 'my $x = 1;',
		'PPI::Token::Word'         => 'my',
		'PPI::Token::Symbol'       => '$x',
		'PPI::Token::Operator'     => '=',
		'PPI::Token::Number'       => '1',
		'PPI::Token::Structure'    => ';',
	],
	"test_statement with explicit Statement in expected"
);

# test_statement: auto-wraps in PPI::Statement when no Statement prefix
test_statement(
	'print 1;',
	[
		'PPI::Token::Word'      => 'print',
		'PPI::Token::Number'    => '1',
		'PPI::Token::Structure' => ';',
	],
	"test_statement auto-wraps in PPI::Statement"
);

# test_document: simple variable declaration
test_document(
	'my $x = 1;',
	[
		'PPI::Statement::Variable', 'my $x = 1;',
		'PPI::Token::Word',         'my',
		'PPI::Token::Symbol',       '$x',
		'PPI::Token::Operator',     '=',
		'PPI::Token::Number',       '1',
		'PPI::Token::Structure',    ';',
	],
	"test_document with simple variable declaration"
);

# test_document: with PPI::Document options passed as first arrayref
test_document(
	[ feature_mods => { signatures => 1 } ],
	'sub foo ($x) {}',
	[
		'PPI::Statement::Sub',        'sub foo ($x) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'foo',
		'PPI::Structure::Signature',  '($x)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$x',
		'PPI::Token::Symbol',         '$x',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	],
	"test_document with feature_mods option"
);
