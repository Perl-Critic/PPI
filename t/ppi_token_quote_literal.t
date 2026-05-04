#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Literal

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 23 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use B qw( perlstring );

use PPI ();
use Helper qw( safe_new test_statement );

STRING: {
	my $Document = safe_new \"print q{foo}, q!bar!, q <foo>, q((foo));";
	my $literal = $Document->find('Token::Quote::Literal');
	is( scalar(@$literal), 4, '->find returns three objects' );
	isa_ok( $literal->[0], 'PPI::Token::Quote::Literal' );
	isa_ok( $literal->[1], 'PPI::Token::Quote::Literal' );
	isa_ok( $literal->[2], 'PPI::Token::Quote::Literal' );
	isa_ok( $literal->[3], 'PPI::Token::Quote::Literal' );
	is( $literal->[0]->string, 'foo',   '->string returns as expected' );
	is( $literal->[1]->string, 'bar',   '->string returns as expected' );
	is( $literal->[2]->string, 'foo',   '->string returns as expected' );
	is( $literal->[3]->string, '(foo)', '->string returns as expected' );
}

LITERAL: {
	my $Document = safe_new \"print q{foo}, q!bar!, q <foo>, q((foo));";
	my $literal = $Document->find('Token::Quote::Literal');
	is( $literal->[0]->literal, 'foo',   '->literal returns as expected' );
	is( $literal->[1]->literal, 'bar',   '->literal returns as expected' );
	is( $literal->[2]->literal, 'foo',   '->literal returns as expected' );
	is( $literal->[3]->literal, '(foo)', '->literal returns as expected' );
}

test_statement(
	"use 'SomeModule';",
	[
		'PPI::Statement::Include'   => "use 'SomeModule';",
		'PPI::Token::Word'          => 'use',
		'PPI::Token::Quote::Single' => "'SomeModule'",
		'PPI::Token::Structure'     => ';',
	]
);

test_statement(
	"use q{OtherModule.pm};",
	[
		'PPI::Statement::Include'     => 'use q{OtherModule.pm};',
		'PPI::Token::Word'            => 'use',
		'PPI::Token::Word'            => 'q',
		'PPI::Structure::Constructor' => '{OtherModule.pm}',
		'PPI::Token::Structure'       => '{',
		'PPI::Statement'              => 'OtherModule.pm',
		'PPI::Token::Word'            => 'OtherModule',
		'PPI::Token::Operator'        => '.',
		'PPI::Token::Word'            => 'pm',
		'PPI::Token::Structure'       => '}',
		'PPI::Token::Structure'       => ';',
	],
	"invalid syntax is identified correctly",
);

