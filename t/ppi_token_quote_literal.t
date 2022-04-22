#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Literal

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 14 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use B qw( perlstring );

use PPI ();


STRING: {
	my $Document = PPI::Document->new( \"print q{foo}, q!bar!, q <foo>;" );
	isa_ok( $Document, 'PPI::Document' );
	my $literal = $Document->find('Token::Quote::Literal');
	is( scalar(@$literal), 3, '->find returns three objects' );
	isa_ok( $literal->[0], 'PPI::Token::Quote::Literal' );
	isa_ok( $literal->[1], 'PPI::Token::Quote::Literal' );
	isa_ok( $literal->[2], 'PPI::Token::Quote::Literal' );
	is( $literal->[0]->string, 'foo', '->string returns as expected' );
	is( $literal->[1]->string, 'bar', '->string returns as expected' );
	is( $literal->[2]->string, 'foo', '->string returns as expected' );
}


LITERAL: {
	my $Document = PPI::Document->new( \"print q{foo}, q!bar!, q <foo>;" );
	isa_ok( $Document, 'PPI::Document' );
	my $literal = $Document->find('Token::Quote::Literal');
	is( $literal->[0]->literal, 'foo', '->literal returns as expected' );
	is( $literal->[1]->literal, 'bar', '->literal returns as expected' );
	is( $literal->[2]->literal, 'foo', '->literal returns as expected' );
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

	my $d = PPI::Document->new( \$code );
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref( $_ ), $_->content } @$tokens ];

	if ( $expected->[0] !~ /^PPI::Statement/ ) {
		$expected = [ 'PPI::Statement', $code, @$expected ];
	}
	my $ok = is_deeply( $tokens, $expected, main_level_line . $msg );
	if ( !$ok ) {
		diag ">>> $code -- $msg\n";
		diag one_line_explain $tokens;
		diag one_line_explain $expected;
	}

	return;
}
