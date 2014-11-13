#!/usr/bin/perl

# Unit testing for PPI::Token::Operator

use t::lib::PPI::Test::pragmas;
use Test::More tests => 1147;

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
			desc => 'generic bareword with integer',  # github #133
			code => 'bareword x 3',
			expected => [
				'PPI::Token::Word' => 'bareword',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'generic bareword with integer run together',  # github #133
			code => 'bareword x3',
			expected => [
				'PPI::Token::Word' => 'bareword',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'preceding word looks like a force but is not',  # github #133
			code => '$a->package x3',
			expected => [
				'PPI::Token::Symbol' => '$a',
				'PPI::Token::Operator' => '->',
				'PPI::Token::Word' => 'package',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '3',
			],
		},
		{
			desc => 'method with integer',
			code => 'sort { $a->package cmp $b->package } ();',
			expected => [
				'PPI::Token::Word' => 'sort',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Structure::Block'=> '{ $a->package cmp $b->package }',
				'PPI::Token::Structure'=> '{',
				'PPI::Token::Whitespace'=> ' ',
				'PPI::Statement'=> '$a->package cmp $b->package',
				'PPI::Token::Symbol'=> '$a',
				'PPI::Token::Operator'=> '->',
				'PPI::Token::Word'=> 'package',
				'PPI::Token::Whitespace'=> ' ',
				'PPI::Token::Operator'=> 'cmp',
				'PPI::Token::Whitespace'=> ' ',
				'PPI::Token::Symbol'=> '$b',
				'PPI::Token::Operator'=> '->',
				'PPI::Token::Word'=> 'package',
				'PPI::Token::Whitespace'=> ' ',
				'PPI::Token::Structure'=> '}',
				'PPI::Token::Whitespace'=> ' ',
				'PPI::Structure::List'=> '()',
				'PPI::Token::Structure'=> '(',
				'PPI::Token::Structure'=> ')',
				'PPI::Token::Structure'=> ';'
			],
		},
		{
			desc => 'method with integer',
			code => 'c->d x 3',
			expected => [
				'PPI::Token::Word' => 'c',
				'PPI::Token::Operator' => '->',
				'PPI::Token::Word' => 'd',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '3',
			],
		},
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
			desc => 'x plus whitespace on the left of => that is not the first token in the doc',
			code => '1;x =>1;',
			expected => [
				'PPI::Statement' => '1;',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ';',
				'PPI::Statement' => 'x =>1;',
				'PPI::Token::Word' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ';',
			],
		},
		{
			desc => 'x on the left of => that is not the first token in the doc',
			code => '1;x=>1;',
			expected => [
				'PPI::Statement' => '1;',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ';',
				'PPI::Statement' => 'x=>1;',
				'PPI::Token::Word' => 'x',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ';',
			],
		},
		{
			desc => 'x on the left of => that is not the first token in the doc',
			code => '$hash{x}=1;',
			expected => [
				'PPI::Token::Symbol' => '$hash',
				'PPI::Structure::Subscript' => '{x}',
				'PPI::Token::Structure' => '{',
				'PPI::Statement::Expression' => 'x',
				'PPI::Token::Word' => 'x',
				'PPI::Token::Structure' => '}',
				'PPI::Token::Operator' => '=',
				'PPI::Token::Number' => '1',
				'PPI::Token::Structure' => ';',
			],
		},
		{
			desc => 'x plus whitespace on the left of => is not an operator',
			code => 'x =>1',
			expected => [
				'PPI::Token::Word' => 'x',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Number' => '1',
			],
		},
		{
			desc => 'x immediately followed by => should not be mistaken for x=',
			code => 'x=>1',
			expected => [
				'PPI::Token::Word' => 'x',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Number' => '1',
			],
		},
		{
			desc => 'xx on left of => not mistaken for an x operator',
			code => 'xx=>1',
			expected => [
				'PPI::Token::Word' => 'xx',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Number' => '1',
			],
		},
		{
			desc => 'x right of => is not an operator',
			code => '1=>x',
			expected => [
				'PPI::Token::Number' => '1',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Word' => 'x',
			],
		},
		{
			desc => 'xor right of => is an operator',
			code => '1=>xor',
			expected => [
				'PPI::Token::Number' => '1',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Operator' => 'xor',
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
			desc => 'RT 37892: x following function is operator',
			code => 'foo()x6',
			expected => [
				'PPI::Token::Word' => 'foo',
				'PPI::Structure::List' => '()',
				'PPI::Token::Structure' => '(',
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
			desc => 'x followed by sigil $ that is not also an operator',
			code => '1x$bar',
			expected => [
				'PPI::Token::Number' => '1',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Symbol' => '$bar',
			],
		},
		{
			desc => 'x followed by sigil @ that is not also an operator',
			code => '1x@bar',
			expected => [
				'PPI::Token::Number' => '1',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Symbol' => '@bar',
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
		{
			desc => 'label plus x',
			code => 'LABEL: x64',
			expected => [
				'PPI::Statement::Compound' => 'LABEL:',
				'PPI::Token::Label' => 'LABEL:',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Statement' => 'x64',
				'PPI::Token::Word' => 'x64',
			]
		},
	);

	# Exhaustively test when a preceding operator implies following
	# 'x' is word not an operator. This detects the regression in
	# which '$obj->x86_convert()' was being parsed as an x
	# operator.
	my %operators = (
		%PPI::Token::Operator::OPERATOR,
		map { $_ => 1 } qw( -r -w -x -o -R -W -X -O -e -z -s -f -d -l -p -S -b -c -t -u -g -k -T -B -M -A -C )
	);
	# Don't try to test operators for which PPI currently (1.215)
	# doesn't recognize when they're followed immediately by a word.
	# E.g.:
	#     sub x3 {15;} my $z=6; print $z&x3;
	#     sub x3 {3;} my $z=2; print $z%x3;
	delete $operators{'&'};
	delete $operators{'%'};
	delete $operators{'*'};
	foreach my $operator ( keys %operators ) {

		my $code = '';
		my @expected;

		if ( $operator =~ /^\w/ ) {
			$code .= '$a ';
			push @expected, ( 'PPI::Token::Symbol' => '$a' );
			push @expected, ( 'PPI::Token::Whitespace' => ' ' );
		}
		elsif ( $operator !~ /^-\w/ ) {  # filetest operators
			$code .= '$a';
			push @expected, ( 'PPI::Token::Symbol' => '$a' );
		}

		$code .= $operator;
		push @expected, ( ($operator eq '<>' ? 'PPI::Token::QuoteLike::Readline' : 'PPI::Token::Operator') => $operator );

		if ( $operator =~ /\w$/ || $operator eq '<<' ) {  # want << operator, not heredoc
			$code .= ' ';
			push @expected, ( 'PPI::Token::Whitespace' => ' ' );
		}
		$code .= 'x3';
		my $desc;
		if ( $operator eq '--' || $operator eq '++' || $operator eq '<>' ) {
			push @expected, ( 'PPI::Token::Operator' => 'x' );
			push @expected, ( 'PPI::Token::Number' => '3' );
			$desc = "operator $operator does not imply following 'x' is a word";
		}
		else {
			push @expected, ( 'PPI::Token::Word' => 'x3' );
			$desc = "operator $operator implies following 'x' is a word";
		}

		push @tests, { desc => $desc, code => $code, expected => \@expected };
	}


	# Test that Perl builtins known to have a null prototype do not
	# force a following 'x' to be a word.
	my %noprotos = map { $_ => 1 } qw(
		endgrent
		endhostent
		endnetent
		endprotoent
		endpwent
		endservent
		fork
		getgrent
		gethostent
		getlogin
		getnetent
		getppid
		getprotoent
		getpwent
		getservent
		setgrent
		setpwent
		time
		times
		wait
		wantarray
		__SUB__
	);
	foreach my $noproto ( keys %noprotos ) {
		my $code = "$noproto x3";
		my @expected = (
			'PPI::Token::Word' => $noproto,
			'PPI::Token::Whitespace' => ' ',
			'PPI::Token::Operator' => 'x',
			'PPI::Token::Number' => '3',
		);
		my $desc = "builtin $noproto does not force following x to be a word";
		push @tests, { desc => "builtin $noproto does not force following x to be a word", code => $code, expected => \@expected };
	}

	foreach my $test ( @tests ) {
		my $d = PPI::Document->new( \$test->{code} );
		my $tokens = $d->find( sub { 1; } );
		$tokens = [ map { ref($_), $_->content() } @$tokens ];
		my $expected = $test->{expected};
		if ( $expected->[0] !~ /^PPI::Statement/ ) {
			unshift @$expected, 'PPI::Statement', $test->{code};
		}
TODO: {
		local $TODO = $test->{code} eq "LABEL: x64" ? "known bug" : undef;
		my $ok = is_deeply( $tokens, $expected, $test->{desc} );
		if ( !$ok ) {
			diag "$test->{code} ($test->{desc})\n";
			diag explain $tokens;
			diag explain $test->{expected};
		}
}
	}
}


OPERATOR_FAT_COMMA: {
	my %known_bad = map { $_ => 1 } map { "$_=>2" } qw( default  for  foreach  given  goto  if  last  local  my  next  no  our  package  redo  require  return  state  unless  until  use  when  while );
	my @tests = (
		{
			desc => 'integer with integer',
			code => '1 => 2',
			expected => [
				'PPI::Token::Number' => '1',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '2',
			],
		},
		{
			desc => 'word with integer',
			code => 'foo => 2',
			expected => [
				'PPI::Token::Word' => 'foo',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '2',
			],
		},
		{
			desc => 'dashed word with integer',
			code => '-foo => 2',
			expected => [
				'PPI::Token::Word' => '-foo',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Whitespace' => ' ',
				'PPI::Token::Number' => '2',
			],
		},
		( map { {
			desc=>$_,
			code=>"$_=>2",
			expected=>[
				'PPI::Token::Word' => $_,
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Number' => '2',
			]
		} } keys %PPI::Token::Word::KEYWORDS ),
		( map { {
			desc=>$_,
			code=>"($_=>2)",
			expected=>[
				'PPI::Structure::List' => "($_=>2)",
				'PPI::Token::Structure' => '(',
				'PPI::Statement::Expression' => "$_=>2",
				'PPI::Token::Word' => $_,
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Number' => '2',
				'PPI::Token::Structure' => ')',
			]
		} } keys %PPI::Token::Word::KEYWORDS ),
		( map { {
			desc=>$_,
			code=>"{$_=>2}",
			expected=>[
				'PPI::Structure::Constructor' => "{$_=>2}",
				'PPI::Token::Structure' => '{',
				'PPI::Statement::Expression' => "$_=>2",
				'PPI::Token::Word' => $_,
				'PPI::Token::Operator' => '=>',
				'PPI::Token::Number' => '2',
				'PPI::Token::Structure' => '}',
			]
		} } keys %PPI::Token::Word::KEYWORDS ),
	);

	for my $test ( @tests ) {
		my $code = $test->{code};

		my $d = PPI::Document->new( \$test->{code} );
		my $tokens = $d->find( sub { 1; } );
		$tokens = [ map { ref($_), $_->content() } @$tokens ];
		my $expected = $test->{expected};
		if ( $expected->[0] !~ /^PPI::Statement/ ) {
			unshift @$expected, 'PPI::Statement', $test->{code};
		}
TODO: {
		local $TODO = $known_bad{$test->{code}} ? "known bug" : undef;
		my $ok = is_deeply( $tokens, $expected, $test->{desc} );
		if ( !$ok ) {
			diag "$test->{code} ($test->{desc})\n";
			diag explain $tokens;
			diag explain $test->{expected};
		}
}
	}
}

