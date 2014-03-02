#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	select STDERR;
	$| = 1;
	select STDOUT;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 299;
use Test::NoWarnings;
use PPI;


FIND_ONE_OP: {
	my $source = '$a = .987;';
	my $doc = PPI::Document->new( \$source );
	isa_ok( $doc, 'PPI::Document', "parsed '$source'" );
	my $ops = $doc->find( 'Token::Number::Float' );
	is( ref $ops, 'ARRAY', "found number" );
	is( @$ops, 1, "number found exactly once" );
	is( $ops->[0]->content(), '.987', "text matches" );

	$ops = $doc->find( 'Token::Operator' );
	is( ref $ops, 'ARRAY', "operator = found operators in number test" );
	is( @$ops, 1, "operator = found exactly once in number test" );
}


HEREDOC: {
	my $source = '$a = <<PERL_END;' . "\n" . 'PERL_END';
	my $doc = PPI::Document->new( \$source );
	isa_ok( $doc, 'PPI::Document', "parsed '$source'" );
	my $ops = $doc->find( 'Token::HereDoc' );
	is( ref $ops, 'ARRAY', "found heredoc" );
	is( @$ops, 1, "heredoc found exactly once" );

	$ops = $doc->find( 'Token::Operator' );
	is( ref $ops, 'ARRAY', "operator = found operators in heredoc test" );
	is( @$ops, 1, "operator = found exactly once in heredoc test" );
}


PARSE_ALL_OPERATORS: {
	foreach my $op ( sort keys %PPI::Token::Operator::OPERATOR ) {
		my $source = $op eq '<>' ? '<>;' : "\$foo $op 2;";
		my $doc = PPI::Document->new( \$source );
		isa_ok( $doc, 'PPI::Document', "operator $op parsed '$source'" );
		my $ops = $doc->find( $op eq '<>' ? 'Token::QuoteLike::Readline' : 'Token::Operator' );
		is( ref $ops, 'ARRAY', "operator $op found operators" );
		is( @$ops, 1, "operator $op found exactly once" );
		is( $ops->[0]->content(), $op, "operator $op operator text matches" );
	}
}


OPERATOR_X: {
	my @tests = (
		{
			desc => 'integer with integer',
			code => '1 x 3',
			expected => [
				'PPI::Token::Number' => '1',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'string with integer',
			code => '"y" x 3',
			expected => [
				'PPI::Token::Quote::Double' => '"y"',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'string with integer',
			code => 'qq{y} x 3',
			expected => [
				'PPI::Token::Quote::Interpolate' => 'qq{y}',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'string no whitespace with integer',
			code => '"y"x 3',
			expected => [
				'PPI::Token::Quote::Double' => '"y"',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'variable with integer',
			code => '$a x 3',
			expected => [
				'PPI::Token::Symbol' => '$a',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'variable with no whitespace integer',
			code => '$a x3',
			expected => [
				'PPI::Token::Symbol' => '$a',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'variable, post ++, x, no whitespace anywhere',
			code => '$a++x3',
			expected => [
				'PPI::Token::Symbol' => '$a',
				'PPI::Token::Operator' => '++',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'double quote, no whitespace',
			code => '"y"x 3',
			expected => [
				'PPI::Token::Quote::Double' => '"y"',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'single quote, no whitespace',
			code => "'y'x 3",
			expected => [
				'PPI::Token::Quote::Single' => "'y'",
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'parens, no whitespace, number',
			code => "(5)x 3",
			expected => [
				'PPI::Structure::List' => '(5)',
				'PPI::Token::Structure' => '(',
				'PPI::Statement::Expression' => '5',
				'PPI::Token::Number' => '5',
				'PPI::Token::Structure' => ')',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'number following x is hex',
			code => "1x0x1",
			expected => [
				'PPI::Token::Number' => '1',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number::Hex' => '0x1',
			],
		},
		{
			desc => 'x followed by symbol',
			code => '1 x$y',
			expected => [
				'PPI::Token::Number' => '1',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Symbol' => '$y',
			],
		},
		{
			desc => 'x= with no trailing whitespace, symbol',
			code => '$z x=3',
			expected => [
				'PPI::Token::Symbol' => '$z',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x=',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'x= with no trailing whitespace, symbol',
			code => '$z x=$y',
			expected => [
				'PPI::Token::Symbol' => '$z',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x=',
				'PPI::Token::Symbol' => '$y',
			],
		},
		{
			desc => 'x followed by => should not be mistaken for x=',
			code => 'x=>$x',
			expected => [
				'PPI::Token::Word' => 'x',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Symbol' => '$x',
			],
		},
		{
			desc => 'xx not mistaken for an x operator',
			code => 'xx=>$x',
			expected => [
				'PPI::Token::Word' => 'xx',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Symbol' => '$x',
			],
		},
		{
			desc => 'RT 37892: list as arg to x operator 1',
			code => '(1) x 6',
			expected => [
				'PPI::Structure::List' => '(1)',
				'PPI::Token::Structure' => '(',
				'PPI::Statement::Expression' => '1',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ')',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '6',
			],
		},
		{
			desc => 'RT 37892: list as arg to x operator 2',
			code => '(1) x6',
			expected => [
				'PPI::Structure::List' => '(1)',
				'PPI::Token::Structure' => '(',
				'PPI::Statement::Expression' => '1',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ')',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '6',
			],
		},
		{
			desc => 'RT 37892: list as arg to x operator 3',
			code => '(1)x6',
			expected => [
				'PPI::Structure::List' => '(1)',
				'PPI::Token::Structure' => '(',
				'PPI::Statement::Expression' => '1',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ')',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '6',
			],
		},
		{
			desc => 'RT 37892: list as arg to x operator 4',
			code => 'qw(1)x6',
			expected => [
				'PPI::Token::QuoteLike::Words' => 'qw(1)',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '6',
			],
		},
		{
			desc => 'RT 37892: list as arg to x operator 5',
			code => 'qw<1>x6',
			expected => [
				'PPI::Token::QuoteLike::Words' => 'qw<1>',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '6',
			],
		},
		{
			desc => 'RT 37892: listref as arg to x operator 6',
			code => '[1]x6',
			expected => [
				'PPI::Structure::Constructor' => '[1]',
				'PPI::Token::Structure' => '[',
				'PPI::Statement' => '1',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ']',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '6',
			],
		},
		{
			desc => 'sub name /^x/',
			code => 'sub xyzzy : _5x5 {1;}',
			expected => [
				'PPI::Statement::Sub' => 'sub xyzzy : _5x5 {1;}',
				'PPI::Token::Word' => 'sub',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Word' => 'xyzzy',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => ':',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Attribute' => '_5x5',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Structure::Block' => '{1;}',
				'PPI::Token::Structure' => '{',
				'PPI::Statement' => '1;',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ';',
				'PPI::Token::Structure' => '}',
			]
		},
	);
	foreach my $test ( @tests ) {
		my $code = $test->{code};

		my $d = PPI::Document->new( \$test->{code} );
		my $tokens = $d->find( sub { 1; } );
		$tokens = [ map { ref($_), $_->content() } @$tokens ];
		my $expected = $test->{expected};
		if ( $expected->[0] !~ /^PPI::Statement::/ ) {
			unshift @$expected, 'PPI::Statement', $test->{code};
		}
		my $ok = is_deeply( $tokens, $expected, $test->{desc} );
		if ( !$ok ) {
			diag "$test->{code} ($test->{desc})\n";
			diag explain $tokens;
			diag explain $test->{expected};
		}
	}
}

