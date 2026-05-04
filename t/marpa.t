#!/usr/bin/perl

# Unit testing for PPI::Token::Unknown

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 69 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use B qw( perlstring );

use PPI ();
use Helper qw( safe_new test_statement );

test_statement(
    'use v5 ;',
    [
        'PPI::Statement::Include'     => 'use v5 ;',
        'PPI::Token::Word'            => 'use',
        'PPI::Token::Number::Version' => 'v5',
        'PPI::Token::Structure'       => ';'
    ]
);

test_statement(
    'use 5 ;',
    [
        'PPI::Statement::Include' => 'use 5 ;',
        'PPI::Token::Word'        => 'use',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Structure'   => ';'
    ]
);

test_statement(
    'use 5.1 ;',
    [
        'PPI::Statement::Include'   => 'use 5.1 ;',
        'PPI::Token::Word'          => 'use',
        'PPI::Token::Number::Float' => '5.1',
        'PPI::Token::Structure'     => ';'
    ]
);

test_statement(
    'use xyz () ;',
    [
        'PPI::Statement::Include' => 'use xyz () ;',
        'PPI::Token::Word'        => 'use',
        'PPI::Token::Word'        => 'xyz',
        'PPI::Structure::List'    => '()',
        'PPI::Token::Structure'   => '(',
        'PPI::Token::Structure'   => ')',
        'PPI::Token::Structure'   => ';'
    ]
);

test_statement(
    'use v5 xyz () ;',
    [
        'PPI::Statement::Include'     => 'use v5 xyz () ;',
        'PPI::Token::Word'            => 'use',
        'PPI::Token::Number::Version' => 'v5',
        'PPI::Token::Word'            => 'xyz',
        'PPI::Structure::List'        => '()',
        'PPI::Token::Structure'       => '(',
        'PPI::Token::Structure'       => ')',
        'PPI::Token::Structure'       => ';'
    ]
);

test_statement(
    'use 5 xyz () ;',
    [
        'PPI::Statement::Include' => 'use 5 xyz () ;',
        'PPI::Token::Word'        => 'use',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Word'        => 'xyz',
        'PPI::Structure::List'    => '()',
        'PPI::Token::Structure'   => '(',
        'PPI::Token::Structure'   => ')',
        'PPI::Token::Structure'   => ';'
    ]
);

test_statement(
    'use 5.1 xyz () ;',
    [
        'PPI::Statement::Include'   => 'use 5.1 xyz () ;',
        'PPI::Token::Word'          => 'use',
        'PPI::Token::Number::Float' => '5.1',
        'PPI::Token::Word'          => 'xyz',
        'PPI::Structure::List'      => '()',
        'PPI::Token::Structure'     => '(',
        'PPI::Token::Structure'     => ')',
        'PPI::Token::Structure'     => ';'
    ]
);

test_statement(
    'use xyz v5 () ;',
    [
        'PPI::Statement::Include'     => 'use xyz v5 () ;',
        'PPI::Token::Word'            => 'use',
        'PPI::Token::Word'            => 'xyz',
        'PPI::Token::Number::Version' => 'v5',
        'PPI::Structure::List'        => '()',
        'PPI::Token::Structure'       => '(',
        'PPI::Token::Structure'       => ')',
        'PPI::Token::Structure'       => ';'
    ]
);

test_statement(
    'use xyz 5 () ;',
    [
        'PPI::Statement::Include' => 'use xyz 5 () ;',
        'PPI::Token::Word'        => 'use',
        'PPI::Token::Word'        => 'xyz',
        'PPI::Token::Number'      => '5',
        'PPI::Structure::List'    => '()',
        'PPI::Token::Structure'   => '(',
        'PPI::Token::Structure'   => ')',
        'PPI::Token::Structure'   => ';'
    ]
);

test_statement(
    'use xyz 5.1 () ;',
    [
        'PPI::Statement::Include'   => 'use xyz 5.1 () ;',
        'PPI::Token::Word'          => 'use',
        'PPI::Token::Word'          => 'xyz',
        'PPI::Token::Number::Float' => '5.1',
        'PPI::Structure::List'      => '()',
        'PPI::Token::Structure'     => '(',
        'PPI::Token::Structure'     => ')',
        'PPI::Token::Structure'     => ';'
    ]
);

test_statement(
    'use v5 xyz 5 ;',
    [
        'PPI::Statement::Include'     => 'use v5 xyz 5 ;',
        'PPI::Token::Word'            => 'use',
        'PPI::Token::Number::Version' => 'v5',
        'PPI::Token::Word'            => 'xyz',
        'PPI::Token::Number'          => '5',
        'PPI::Token::Structure'       => ';'
    ]
);

test_statement(
    'use 5 xyz 5 ;',
    [
        'PPI::Statement::Include' => 'use 5 xyz 5 ;',
        'PPI::Token::Word'        => 'use',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Word'        => 'xyz',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Structure'   => ';'
    ]
);

test_statement(
    'use 5.1 xyz 5 ;',
    [
        'PPI::Statement::Include'   => 'use 5.1 xyz 5 ;',
        'PPI::Token::Word'          => 'use',
        'PPI::Token::Number::Float' => '5.1',
        'PPI::Token::Word'          => 'xyz',
        'PPI::Token::Number'        => '5',
        'PPI::Token::Structure'     => ';'
    ]
);

test_statement(
    'use xyz v5 5 ;',
    [
        'PPI::Statement::Include'     => 'use xyz v5 5 ;',
        'PPI::Token::Word'            => 'use',
        'PPI::Token::Word'            => 'xyz',
        'PPI::Token::Number::Version' => 'v5',
        'PPI::Token::Number'          => '5',
        'PPI::Token::Structure'       => ';'
    ]
);

test_statement(
    'use xyz 5 5 ;',
    [
        'PPI::Statement::Include' => 'use xyz 5 5 ;',
        'PPI::Token::Word'        => 'use',
        'PPI::Token::Word'        => 'xyz',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Structure'   => ';'
    ]
);

test_statement(
    'use xyz 5.1 5 ;',
    [
        'PPI::Statement::Include'   => 'use xyz 5.1 5 ;',
        'PPI::Token::Word'          => 'use',
        'PPI::Token::Word'          => 'xyz',
        'PPI::Token::Number::Float' => '5.1',
        'PPI::Token::Number'        => '5',
        'PPI::Token::Structure'     => ';'
    ]
);

test_statement(
    'use v5 xyz 5,5 ;',
    [
        'PPI::Statement::Include'     => 'use v5 xyz 5,5 ;',
        'PPI::Token::Word'            => 'use',
        'PPI::Token::Number::Version' => 'v5',
        'PPI::Token::Word'            => 'xyz',
        'PPI::Token::Number'          => '5',
        'PPI::Token::Operator'        => ',',
        'PPI::Token::Number'          => '5',
        'PPI::Token::Structure'       => ';'
    ]
);

test_statement(
    'use 5 xyz 5,5 ;',
    [
        'PPI::Statement::Include' => 'use 5 xyz 5,5 ;',
        'PPI::Token::Word'        => 'use',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Word'        => 'xyz',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Operator'    => ',',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Structure'   => ';'
    ]
);

test_statement(
    'use 5.1 xyz 5,5 ;',
    [
        'PPI::Statement::Include'   => 'use 5.1 xyz 5,5 ;',
        'PPI::Token::Word'          => 'use',
        'PPI::Token::Number::Float' => '5.1',
        'PPI::Token::Word'          => 'xyz',
        'PPI::Token::Number'        => '5',
        'PPI::Token::Operator'      => ',',
        'PPI::Token::Number'        => '5',
        'PPI::Token::Structure'     => ';'
    ]
);

test_statement(
    'use xyz v5 5,5 ;',
    [
        'PPI::Statement::Include'     => 'use xyz v5 5,5 ;',
        'PPI::Token::Word'            => 'use',
        'PPI::Token::Word'            => 'xyz',
        'PPI::Token::Number::Version' => 'v5',
        'PPI::Token::Number'          => '5',
        'PPI::Token::Operator'        => ',',
        'PPI::Token::Number'          => '5',
        'PPI::Token::Structure'       => ';'
    ]
);

test_statement(
    'use xyz 5 5,5 ;',
    [
        'PPI::Statement::Include' => 'use xyz 5 5,5 ;',
        'PPI::Token::Word'        => 'use',
        'PPI::Token::Word'        => 'xyz',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Operator'    => ',',
        'PPI::Token::Number'      => '5',
        'PPI::Token::Structure'   => ';'
    ]
);

test_statement(
    'use xyz 5.1 5,5 ;',
    [
        'PPI::Statement::Include'   => 'use xyz 5.1 5,5 ;',
        'PPI::Token::Word'          => 'use',
        'PPI::Token::Word'          => 'xyz',
        'PPI::Token::Number::Float' => '5.1',
        'PPI::Token::Number'        => '5',
        'PPI::Token::Operator'      => ',',
        'PPI::Token::Number'        => '5',
        'PPI::Token::Structure'     => ';'
    ]
);

test_statement(
    'use xyz 5.1 @a ;',
    [
        'PPI::Statement::Include'   => 'use xyz 5.1 @a ;',
        'PPI::Token::Word'          => 'use',
        'PPI::Token::Word'          => 'xyz',
        'PPI::Token::Number::Float' => '5.1',
        'PPI::Token::Symbol'        => '@a',
        'PPI::Token::Structure'     => ';'
    ]
);

