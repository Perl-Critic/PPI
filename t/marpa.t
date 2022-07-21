#!/usr/bin/perl

# Unit testing for PPI::Token::Unknown

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 69 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use B qw( perlstring );

use PPI ();
use Helper 'safe_new';

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

sub one_line_explain {
    my ( $data ) = @_;
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

sub test_statement {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $code, $expected, $msg ) = @_;
    $msg = perlstring $code if !defined $msg;

    my $d = safe_new \$code;
    my $tokens = $d->find( sub { $_[1]->significant } );
    $tokens = [ map { ref( $_ ), $_->content } @$tokens ];

    if ( $expected->[0] !~ /^PPI::Statement/ ) {
        $expected = [ 'PPI::Statement', $code, @$expected ];
    }
    my $ok = is_deeply( $tokens, $expected, main_level_line . $msg );
    if ( !$ok ) {
        diag ">>> $code -- $msg\n";
        diag "GOT: " . one_line_explain $tokens;
        diag "EXP: " . one_line_explain $expected;
    }

    return;
}
