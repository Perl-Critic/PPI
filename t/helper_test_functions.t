#!/usr/bin/perl

# Test that Helper.pm exports generalized test_document and test_statement

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 7 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI ();

TODO: {
	local $TODO = "test_document and test_statement not yet in Helper";

	ok eval { require Helper; Helper->import('test_document'); 1 },
	  "Helper exports test_document";
	ok eval { require Helper; Helper->import('test_statement'); 1 },
	  "Helper exports test_statement";
	ok eval { require Helper; Helper->import('test_document', 'test_statement'); 1 },
	  "Helper exports both together";

	# test_statement: simple expression
	eval { Helper->import('test_statement') };
	SKIP: {
		skip "test_statement not available", 2 if !Helper->can('test_statement');
		# These call test_statement which internally runs is_deeply
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
		test_statement(
			'my $x = 1;',
			[
				'PPI::Token::Word'      => 'my',
				'PPI::Token::Symbol'    => '$x',
				'PPI::Token::Operator'  => '=',
				'PPI::Token::Number'    => '1',
				'PPI::Token::Structure' => ';',
			],
			"test_statement auto-wraps in PPI::Statement"
		);
	}

	# test_document: multi-statement document
	eval { Helper->import('test_document') };
	SKIP: {
		skip "test_document not available", 2 if !Helper->can('test_document');
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
		# test_document with PPI::Document options passed as first arrayref
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
	}
}
