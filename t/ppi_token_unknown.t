#!/usr/bin/perl

# Unit testing for PPI::Token::Unknown

use t::lib::PPI::Test::pragmas;
use Test::More tests => 133;

use PPI;


OPERATOR_CAST: {
	my @nothing = ( '',  [] );
	my @number =  ( '1', [ 'PPI::Token::Number' => '1' ] );

	my @asterisk_op =    ( '*',  [ 'PPI::Token::Operator' => '*' ] );
	my @asteriskeq_op =  ( '*=', [ 'PPI::Token::Operator' => '*=' ] );
	my @percent_op =     ( '%',  [ 'PPI::Token::Operator' => '%' ] );
	my @percenteq_op =   ( '%=', [ 'PPI::Token::Operator' => '%=' ] );
	my @ampersand_op =   ( '&',  [ 'PPI::Token::Operator' => '&' ] );
	my @ampersandeq_op = ( '&=', [ 'PPI::Token::Operator' => '&=' ] );
	my @exp_op =         ( '**', [ 'PPI::Token::Operator' => '**' ] );

	my @asterisk_cast =  ( '*', [ 'PPI::Token::Cast' => '*' ] );
	my @percent_cast =   ( '%', [ 'PPI::Token::Cast' => '%' ] );
	my @ampersand_cast = ( '&', [ 'PPI::Token::Cast' => '&' ] );
	my @at_cast =        ( '@',  [ 'PPI::Token::Cast' => '@' ] );

	my @scalar = ( '$a', [ 'PPI::Token::Symbol' => '$a' ] );
	my @list = ( '@a', [ 'PPI::Token::Symbol' => '@a' ] );
	my @hash = ( '%a', [ 'PPI::Token::Symbol' => '%a' ] );
	my @glob = ( '*a', [ 'PPI::Token::Symbol' => '*a' ] );
	my @bareword = ( 'word', [ 'PPI::Token::Word' => 'word' ] );
	my @hashctor1 = (
		'{2}',
		[
#			'PPI::Structure::Constructor' => '{2}',
			'PPI::Structure::Block' => '{2}',  # should be constructor
			'PPI::Token::Structure' => '{',
#			'PPI::Statement::Expression' => '2',
			'PPI::Statement' => '2',  # should be expression
			'PPI::Token::Number' => '2',
			'PPI::Token::Structure' => '}',
		]
	);
	my @hashctor2 = (
		'{x=>2}',
		[
#			'PPI::Structure::Constructor' => '{x=>2}',
			'PPI::Structure::Block' => '{x=>2}',  # should be constructor
			'PPI::Token::Structure' => '{',
#			'PPI::Statement::Expression' => 'x=>2',
			'PPI::Statement' => 'x=>2',  # should be expression
			'PPI::Token::Word' => 'x',
			'PPI::Token::Operator' => '=>',
			'PPI::Token::Number' => '2',
			'PPI::Token::Structure' => '}',
		]
	);
	my @hashctor3 = (
		'{$args}',
		[
#			'PPI::Structure::Constructor' => '{$args}',
			'PPI::Structure::Block' => '{$args}',  # should be constructor
			'PPI::Token::Structure' => '{',
#			'PPI::Statement::Expression' => '$args',
			'PPI::Statement' => '$args',  # should be expression
			'PPI::Token::Symbol' => '$args',
			'PPI::Token::Structure' => '}',
		]
	);
	my @listctor = @hashctor3;

	test_varying_whitespace( @number, @asterisk_op, @scalar );
	test_varying_whitespace( @number, @asterisk_op, @list );
	test_varying_whitespace( @number, @asterisk_op, @hash );
TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @number, @asterisk_op, @hashctor1 );
	test_varying_whitespace( @number, @asterisk_op, @hashctor2 );
	test_varying_whitespace( @number, @asterisk_op, @hashctor3 );
}
	test_varying_whitespace( @number, @exp_op, @bareword );
	test_varying_whitespace( @number, @exp_op, @hashctor3 );  # doesn't compile, but make sure ** is operator
	test_varying_whitespace( @number, @asteriskeq_op, @bareword );
	test_varying_whitespace( @number, @asteriskeq_op, @hashctor3 );  # doesn't compile, but make sure it's an operator
	test_varying_whitespace( @nothing, @asterisk_cast, @scalar );

TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @number, @percent_op, @scalar );
	test_varying_whitespace( @number, @percent_op, @list );
	test_varying_whitespace( @number, @percent_op, @hash );
	test_varying_whitespace( @number, @percent_op, @glob );
	test_varying_whitespace( @number, @percent_op, @hashctor1 );
	test_varying_whitespace( @number, @percent_op, @hashctor2 );
	test_varying_whitespace( @number, @percent_op, @hashctor3 );
}
	test_varying_whitespace( @number, @percenteq_op, @bareword );
	test_varying_whitespace( @number, @percenteq_op, @hashctor3 );  # doesn't compile, but make sure it's an operator
	test_varying_whitespace( @nothing, @percent_cast, @scalar );

TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @number, @ampersand_op, @scalar );
	test_varying_whitespace( @number, @ampersand_op, @list );
	test_varying_whitespace( @number, @ampersand_op, @hash );
}
	test_varying_whitespace( @number, @ampersand_op, @glob );
TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @number, @ampersand_op, @hashctor1 );
	test_varying_whitespace( @number, @ampersand_op, @hashctor2 );
	test_varying_whitespace( @number, @ampersand_op, @hashctor3 );
}
	test_varying_whitespace( @number, @ampersandeq_op, @bareword );
	test_varying_whitespace( @number, @ampersandeq_op, @hashctor3 );  # doesn't compile, but make sure it's an operator
	test_varying_whitespace( @nothing, @ampersand_cast, @scalar );

	my @plus = ( '+', [ 'PPI::Token::Operator' => '+', ] );
	my @ex = ( 'x', [ 'PPI::Token::Operator' => 'x', ] );
	test_varying_whitespace( @plus, @asterisk_cast, @scalar );
	test_varying_whitespace( @plus, @asterisk_cast, @hashctor3 );
	test_varying_whitespace( @plus, @percent_cast, @scalar );
	test_varying_whitespace( @plus, @percent_cast, @hashctor3 );
	test_varying_whitespace( @plus, @ampersand_cast, @scalar );
	test_varying_whitespace( @plus, @ampersand_cast, @hashctor3 );
	test_varying_whitespace( @ex, @asterisk_cast, @scalar );
	test_varying_whitespace( @ex, @asterisk_cast, @hashctor3 );
	test_varying_whitespace( @ex, @percent_cast, @scalar );
	test_varying_whitespace( @ex, @percent_cast, @hashctor3 );
	test_varying_whitespace( @ex, @ampersand_cast, @scalar );
	test_varying_whitespace( @ex, @ampersand_cast, @hashctor3 );

	my @single = ( "'3'", [ 'PPI::Token::Quote::Single' => "'3'", ] );
TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @single, @asterisk_op, @scalar );
	test_varying_whitespace( @single, @asterisk_op, @hashctor3 );
	test_varying_whitespace( @single, @percent_op, @scalar );
	test_varying_whitespace( @single, @percent_op, @hashctor3 );
	test_varying_whitespace( @single, @ampersand_op, @scalar );
	test_varying_whitespace( @single, @ampersand_op, @hashctor3 );

	my @double = ( '"3"', [ 'PPI::Token::Quote::Double' => '"3"', ] );
	test_varying_whitespace( @double, @asterisk_op, @scalar );
	test_varying_whitespace( @double, @asterisk_op, @hashctor3 );
	test_varying_whitespace( @double, @percent_op, @scalar );
	test_varying_whitespace( @double, @percent_op, @hashctor3 );
	test_varying_whitespace( @double, @ampersand_op, @scalar );
	test_varying_whitespace( @double, @ampersand_op, @hashctor3 );
}

	test_varying_whitespace( @scalar, @asterisk_op, @scalar );
TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @scalar, @percent_op, @scalar );
	test_varying_whitespace( @scalar, @ampersand_op, @scalar );

	my @package = (
		'package foo {}',
		[
			'PPI::Statement::Package' => 'package foo {}',
			'PPI::Token::Word' => 'package',
			'PPI::Token::Word' => 'foo',
			'PPI::Structure::Block' => '{}',
			'PPI::Token::Structure' => '{',
			'PPI::Token::Structure' => '}',
		]
	);
	test_varying_whitespace( @package, @asterisk_cast, @scalar, 1 );
	test_varying_whitespace( @package, @asterisk_cast, @hashctor3, 1 );
	test_varying_whitespace( @package, @percent_cast, @scalar, 1 );
	test_varying_whitespace( @package, @percent_cast, @hashctor3, 1 );
	test_varying_whitespace( @package, @ampersand_cast, @scalar, 1 );
	test_varying_whitespace( @package, @ampersand_cast, @hashctor3, 1 );
	test_varying_whitespace( @package, @at_cast, @scalar, 1 );
	test_varying_whitespace( @package, @at_cast, @listctor, 1 );
}

	my @sub = (
		'sub foo {}',
		[
			'PPI::Statement::Sub' => 'sub foo {}',
			'PPI::Token::Word' => 'sub',
			'PPI::Token::Word' => 'foo',
			'PPI::Structure::Block' => '{}',
			'PPI::Token::Structure' => '{',
			'PPI::Token::Structure' => '}',
		]
	);
	test_varying_whitespace( @sub, @asterisk_cast, @scalar, 1 );
	test_varying_whitespace( @sub, @asterisk_cast, @hashctor3, 1 );
	test_varying_whitespace( @sub, @percent_cast, @scalar, 1 );
	test_varying_whitespace( @sub, @percent_cast, @hashctor3, 1 );
	test_varying_whitespace( @sub, @ampersand_cast, @scalar, 1 );
	test_varying_whitespace( @sub, @ampersand_cast, @hashctor3, 1 );
	test_varying_whitespace( @sub, @at_cast, @scalar, 1 );
	test_varying_whitespace( @sub, @at_cast, @listctor, 1 );

	my @statement = (
		'1;',
		[
			'PPI::Statement' => '1;',
			'PPI::Token::Number' => '1',
			'PPI::Token::Structure' => ';',
		]
	);
	test_varying_whitespace( @statement, @asterisk_cast, @scalar, 1 );
	test_varying_whitespace( @statement, @asterisk_cast, @hashctor3, 1 );
	test_varying_whitespace( @statement, @percent_cast, @scalar, 1 );
	test_varying_whitespace( @statement, @percent_cast, @hashctor3, 1 );
	test_varying_whitespace( @statement, @ampersand_cast, @scalar, 1 );
	test_varying_whitespace( @statement, @ampersand_cast, @hashctor3, 1 );
	test_varying_whitespace( @statement, @at_cast, @scalar, 1 );
	test_varying_whitespace( @statement, @at_cast, @listctor, 1 );

	my @label = (
		'LABEL:',
		[
			'PPI::Statement::Compound' => 'LABEL:',
			'PPI::Token::Label' => 'LABEL:',
		]
	);
	test_varying_whitespace( @label, @asterisk_cast, @scalar, 1 );
	test_varying_whitespace( @label, @asterisk_cast, @hashctor3, 1 );
	test_varying_whitespace( @label, @percent_cast, @scalar, 1 );
	test_varying_whitespace( @label, @percent_cast, @hashctor3, 1 );
	test_varying_whitespace( @label, @ampersand_cast, @scalar, 1 );
	test_varying_whitespace( @label, @ampersand_cast, @hashctor3, 1 );
	test_varying_whitespace( @label, @at_cast, @scalar, 1 );
	test_varying_whitespace( @label, @at_cast, @listctor, 1 );

	my @map = (
		'map {1}',
		[
			'PPI::Token::Word' => 'map',
			'PPI::Structure::Block' => '{1}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '1',
			'PPI::Token::Number' => '1',
			'PPI::Token::Structure' => '}',
		]
	);
	test_varying_whitespace( @map, @asterisk_cast, @scalar );
	test_varying_whitespace( @map, @asterisk_cast, @hashctor3 );
	test_varying_whitespace( @map, @percent_cast, @scalar );
	test_varying_whitespace( @map, @percent_cast, @hashctor3 );
	test_varying_whitespace( @map, @ampersand_cast, @scalar );
	test_varying_whitespace( @map, @ampersand_cast, @hashctor3 );
	test_varying_whitespace( @map, @at_cast, @scalar );
	test_varying_whitespace( @map, @at_cast, @listctor );

	my @evalblock = (
		'eval {2}',
		[
			'PPI::Token::Word' => 'eval',
			'PPI::Structure::Block' => '{2}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '2',
			'PPI::Token::Number' => '2',
			'PPI::Token::Structure' => '}',
		]
	);
TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @evalblock, @asterisk_op, @scalar );
	test_varying_whitespace( @evalblock, @asterisk_op, @hashctor3 );
	test_varying_whitespace( @evalblock, @percent_op, @scalar );
	test_varying_whitespace( @evalblock, @percent_op, @hashctor3 );
	test_varying_whitespace( @evalblock, @ampersand_op, @scalar );
	test_varying_whitespace( @evalblock, @ampersand_op, @hashctor3 );

	my @evalstring = (
		'eval "2"',
		[
			'PPI::Token::Word' => 'eval',
			'PPI::Token::Quote::Double' => '"2"',
		]
	);
	test_varying_whitespace( @evalstring, @asterisk_op, @scalar );
	test_varying_whitespace( @evalstring, @asterisk_op, @hashctor3 );
	test_varying_whitespace( @evalstring, @percent_op, @scalar );
	test_varying_whitespace( @evalstring, @percent_op, @hashctor3 );
	test_varying_whitespace( @evalstring, @ampersand_op, @scalar );
	test_varying_whitespace( @evalstring, @ampersand_op, @hashctor3 );
}

	my @curly_subscript1 = (
		'$y->{x}',
		[
			'PPI::Token::Symbol' => '$y',
			'PPI::Token::Operator' => '->',
			'PPI::Structure::Subscript' => '{x}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement::Expression' => 'x',
			'PPI::Token::Word' => 'x',
			'PPI::Token::Structure' => '}',
		]
	);
	my @curly_subscript2 = (
		'$y->{z}{x}',
		[
			'PPI::Token::Symbol' => '$y',
			'PPI::Token::Operator' => '->',
			'PPI::Structure::Subscript' => '{z}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement::Expression' => 'z',
			'PPI::Token::Word' => 'z',
			'PPI::Token::Structure' => '}',
			'PPI::Structure::Subscript' => '{x}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement::Expression' => 'x',
			'PPI::Token::Word' => 'x',
			'PPI::Token::Structure' => '}',
		]
	);
	my @curly_subscript3 = (
		'$y->[z]{x}',
		[
			'PPI::Token::Symbol' => '$y',
			'PPI::Token::Operator' => '->',
			'PPI::Structure::Subscript' => '[z]',
			'PPI::Token::Structure' => '[',
			'PPI::Statement::Expression' => 'z',
			'PPI::Token::Word' => 'z',
			'PPI::Token::Structure' => ']',
			'PPI::Structure::Subscript' => '{x}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement::Expression' => 'x',
			'PPI::Token::Word' => 'x',
			'PPI::Token::Structure' => '}',
		]
	);
	my @square_subscript1 = (
		'$y->[x]',
		[
			'PPI::Token::Symbol' => '$y',
			'PPI::Token::Operator' => '->',
			'PPI::Structure::Subscript' => '[x]',
			'PPI::Token::Structure' => '[',
			'PPI::Statement::Expression' => 'x',
			'PPI::Token::Word' => 'x',
			'PPI::Token::Structure' => ']',
		]
	);

TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @curly_subscript1, @asterisk_op, @scalar );
	test_varying_whitespace( @curly_subscript1, @percent_op, @scalar );
	test_varying_whitespace( @curly_subscript1, @ampersand_op, @scalar );
	test_varying_whitespace( @curly_subscript2, @asterisk_op, @scalar );
	test_varying_whitespace( @curly_subscript2, @percent_op, @scalar );
	test_varying_whitespace( @curly_subscript2, @ampersand_op, @scalar );
	test_varying_whitespace( @curly_subscript3, @asterisk_op, @scalar );
	test_varying_whitespace( @curly_subscript3, @percent_op, @scalar );
	test_varying_whitespace( @curly_subscript3, @ampersand_op, @scalar );
}
	test_varying_whitespace( @square_subscript1, @asterisk_op, @scalar );
TODO: {
    local $TODO = "known bug";
	test_varying_whitespace( @square_subscript1, @percent_op, @scalar );
	test_varying_whitespace( @square_subscript1, @ampersand_op, @scalar );
}

	test_varying_whitespace( 'keys', [ 'PPI::Token::Word' => 'keys' ],     @percent_cast, @scalar );
	test_varying_whitespace( 'values', [ 'PPI::Token::Word' => 'values' ], @percent_cast, @scalar );

	test_varying_whitespace( 'keys', [ 'PPI::Token::Word' => 'keys' ],     @percent_cast, @hashctor3 );
	test_varying_whitespace( 'values', [ 'PPI::Token::Word' => 'values' ], @percent_cast, @hashctor3 );

TODO: {
    local $TODO = "known bug";
	test_statement(
		'} *$a', # unbalanced '}' before '*', arbitrary decision
		[
			'PPI::Statement::UnmatchedBrace' => '}',
			'PPI::Token::Structure' => '}',
			'PPI::Statement' => '*$a',
			'PPI::Token::Operator' => '*',
			'PPI::Token::Symbol' => '$a',
		]
	);
}

	test_statement(
		'$bar = \%*$foo', # multiple consecutive casts
		[
			'PPI::Token::Symbol' => '$bar',
			'PPI::Token::Operator' => '=',
			'PPI::Token::Cast' => '\\',
			'PPI::Token::Cast' => '%',
			'PPI::Token::Cast' => '*',
			'PPI::Token::Symbol' => '$foo',
		]
	);

TODO: {
    local $TODO = "known bug";
	test_statement(
		'$#tmp*$#tmp2',
		[
			'PPI::Token::ArrayIndex' => '$#tmp',
			'PPI::Token::Operator' => '*',
			'PPI::Token::ArrayIndex' => '$#tmp2',
		]
	);
}

	test_statement(
		'[ %{$req->parameters} ]',  # preceded by '['
		[
			'PPI::Structure::Constructor' => '[ %{$req->parameters} ]',
			'PPI::Token::Structure' => '[',
			'PPI::Statement' => '%{$req->parameters}',
			'PPI::Token::Cast' => '%',
			'PPI::Structure::Block' => '{$req->parameters}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '$req->parameters',
			'PPI::Token::Symbol' => '$req',
			'PPI::Token::Operator' => '->',
			'PPI::Token::Word' => 'parameters',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Structure' => ']',
		]
	);
	test_statement(
		'( %{$req->parameters} )',  # preceded by '('
		[
			'PPI::Structure::List' => '( %{$req->parameters} )',
			'PPI::Token::Structure' => '(',
			'PPI::Statement::Expression' => '%{$req->parameters}',
			'PPI::Token::Cast' => '%',
			'PPI::Structure::Block' => '{$req->parameters}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '$req->parameters',
			'PPI::Token::Symbol' => '$req',
			'PPI::Token::Operator' => '->',
			'PPI::Token::Word' => 'parameters',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Structure' => ')',
		]
	);

TODO: {
    local $TODO = "known bug";
	test_statement(
		'++$i%$f',  # '%' wrongly a cast through 1.220.
		[
			'PPI::Statement' => '++$i%$f',
			'PPI::Token::Operator' => '++',
			'PPI::Token::Symbol' => '$i',
			'PPI::Token::Operator' => '%',
			'PPI::Token::Symbol' => '$f',
		]
	);
}
}


exit 0;


sub test_statement {
	local $Test::Builder::Level = $Test::Builder::Level+1;
	my ( $code, $expected, $msg ) = @_;
	$msg = $code if !defined $msg;

	my $d = PPI::Document->new( \$code );
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref($_), $_->content() } @$tokens ];

	if ( $expected->[0] !~ /^PPI::Statement/ ) {
		$expected = [ 'PPI::Statement', $code, @$expected ];
	}
	my $ok = is_deeply( $tokens, $expected, $msg );
	if ( !$ok ) {
		diag ">>> $code -- $msg\n";
		diag explain $tokens;
		diag explain $expected;
	}

	return;
}


sub test_varying_whitespace {
	local $Test::Builder::Level = $Test::Builder::Level+1;
	my( $left, $left_expected, $cast_or_op, $cast_or_op_expected, $right, $right_expected, $right_is_statement ) = @_;

	assemble_and_test( "",  $left, $left_expected, $cast_or_op, $cast_or_op_expected, $right, $right_expected, $right_is_statement );
#	assemble_and_test( " ", $left, $left_expected, $cast_or_op, $cast_or_op_expected, $right, $right_expected, $right_is_statement );
#	assemble_and_test( "\t", $left, $left_expected, $cast_or_op, $cast_or_op_expected, $right, $right_expected, $right_is_statement );
#	assemble_and_test( "\n", $left, $left_expected, $cast_or_op, $cast_or_op_expected, $right, $right_expected, $right_is_statement );
#	assemble_and_test( "\f", $left, $left_expected, $cast_or_op, $cast_or_op_expected, $right, $right_expected, $right_is_statement );
#	assemble_and_test( "\r", $left, $left_expected, $cast_or_op, $cast_or_op_expected, $right, $right_expected, $right_is_statement );  # fix this -- different breakage from \n, \t, etc.

	return;
}


sub assemble_and_test {
	local $Test::Builder::Level = $Test::Builder::Level+1;
	my( $whitespace, $left, $left_expected, $cast_or_op, $cast_or_op_expected, $right, $right_expected, $right_is_statement ) = @_;

	my $code = $left eq '' ? "$cast_or_op$whitespace$right" : "$left$whitespace$cast_or_op$whitespace$right";

	if ( $right_is_statement ) {
		$cast_or_op_expected = [ 'PPI::Statement' => "$cast_or_op$whitespace$right", @$cast_or_op_expected ];
	}

	my $expected = [
		@$left_expected,
		@$cast_or_op_expected,
		@$right_expected,
	];
	test_statement( $code, $expected );

	return;
}
