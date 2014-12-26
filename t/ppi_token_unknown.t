#!/usr/bin/perl

# Unit testing for PPI::Token::Unknown

use t::lib::PPI::Test::pragmas;
use Test::More tests => 70;

use PPI;

sub o { test_cast_or_op( @_ ) }
sub c { test_cast_or_op( @_, 1 ) }

OPERATOR_CAST: {
	o '1*$a';
	o '1*@a';
	o '1*%a';
	o '1**a';
	o '1**{$a}';
	o '1*={$a}';  # doesn't compile, but make sure *= is operator
	o '1*{2}';
	o '1*{2=>2}';  # same as '1*{2}'

	o '1%$a';
	o '1%@a';
	o '1%%a';
	o '1%*a';
	o '1%{2}';
	o '1%{2=>2}';  # same as '1%{2}'

	o '1&$a';
	o '1&@a';
	o '1&%a';
	o '1&*a';
	o '1&{2}';
	o '1&{2=>2}';  # same as '1&{2}'
        o '$obj&$obj';
	
	c '*$a';
	c 'package foo {} *$a';
	c 'keys %$a';
	c 'keys %{$a}';
	c 'values %$a';
	c 'values %{$a}';

        test_complex(
                'map {1} %{$args}',
		[
			'PPI::Token::Word' => 'map',
			'PPI::Structure::Block' => '{1}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '1',
			'PPI::Token::Number' => '1',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Cast' => '%',
                        'PPI::Structure::Block' => '{$args}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '$args',
			'PPI::Token::Symbol' => '$args',
			'PPI::Token::Structure' => '}',
		]
        );
        test_complex(
                'map {1} @{$args}',
		[
			'PPI::Token::Word' => 'map',
			'PPI::Structure::Block' => '{1}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '1',
			'PPI::Token::Number' => '1',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Cast' => '@',
                        'PPI::Structure::Block' => '{$args}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '$args',
			'PPI::Token::Symbol' => '$args',
			'PPI::Token::Structure' => '}',
		]
        );
        test_complex(
                'map {1} *{$args}',
		[
			'PPI::Token::Word' => 'map',
			'PPI::Structure::Block' => '{1}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '1',
			'PPI::Token::Number' => '1',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Cast' => '*',
                        'PPI::Structure::Block' => '{$args}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '$args',
			'PPI::Token::Symbol' => '$args',
			'PPI::Token::Structure' => '}',
		]
        );

	test_complex(
		'} *$a', # unbalanced '}' before '*', arbitrary decision
		[
			'PPI::Statement::UnmatchedBrace' => '}',
			'PPI::Token::Structure' => '}',
			'PPI::Statement' => '*$a',
			'PPI::Token::Operator' => '*',
			'PPI::Token::Symbol' => '$a',
		]
	);

	test_complex(
		'eval {2}*$a',
		[
			'PPI::Token::Word' => 'eval',
			'PPI::Structure::Block' => '{2}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement' => '2',
			'PPI::Token::Number' => '2',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Operator' => '*',
			'PPI::Token::Symbol' => '$a',
		]
	);

	test_complex(
		'sub foo {} *$a=$b;',
		[
			'PPI::Statement::Sub' => 'sub foo {}',
			'PPI::Token::Word' => 'sub',
			'PPI::Token::Word' => 'foo',
			'PPI::Structure::Block' => '{}',
			'PPI::Token::Structure' => '{',
			'PPI::Token::Structure' => '}',
			'PPI::Statement' => '*$a=$b;',
			'PPI::Token::Cast' => '*',
			'PPI::Token::Symbol' => '$a',
			'PPI::Token::Operator' => '=',
			'PPI::Token::Symbol' => '$b',
			'PPI::Token::Structure' => ';',
		]
	);

	test_complex(
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

	# See GitHub #60 for info on '$$$' not being parsed right
	test_complex(
                '$#tmp*$#tmp2',
		[
			'PPI::Token::ArrayIndex' => '$#tmp',
			'PPI::Token::Operator' => '*',
			'PPI::Token::ArrayIndex' => '$#tmp2',
		]
        );

	test_complex(
		'LABEL: *$a=$b',  # preceded by label
		[
			'PPI::Statement::Compound' => 'LABEL:',
			'PPI::Token::Label' => 'LABEL:',
			'PPI::Statement' => '*$a=$b',
			'PPI::Token::Cast' => '*',
			'PPI::Token::Symbol' => '$a',
			'PPI::Token::Operator' => '=',
			'PPI::Token::Symbol' => '$b',
		]
	);

	test_complex(
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
	test_complex(
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

	test_complex(
		'++$i%$f',  # '%' wrongly a cast through 1.220.
		[
			'PPI::Statement' => '++$i%$f',
			'PPI::Token::Operator' => '++',
			'PPI::Token::Symbol' => '$i',
			'PPI::Token::Operator' => '%',
			'PPI::Token::Symbol' => '$f',
		]
	);

        # subscripting prior to curlies
	test_complex(
		'$a->{a}*$x',
		[
			'PPI::Token::Symbol' => '$a',
			'PPI::Token::Operator' => '->',
			'PPI::Structure::Subscript' => '{a}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement::Expression' => 'a',
			'PPI::Token::Word' => 'a',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Operator' => '*',
			'PPI::Token::Symbol' => '$x',
		]
	);
	test_complex(
		'$a->{a}{b}*$x',
		[
			'PPI::Token::Symbol' => '$a',
			'PPI::Token::Operator' => '->',
			'PPI::Structure::Subscript' => '{a}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement::Expression' => 'a',
			'PPI::Token::Word' => 'a',
			'PPI::Token::Structure' => '}',
			'PPI::Structure::Subscript' => '{b}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement::Expression' => 'b',
			'PPI::Token::Word' => 'b',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Operator' => '*',
			'PPI::Token::Symbol' => '$x',
		]
	);
	test_complex(
		'$a->[a]{b}*$x',
		[
			'PPI::Token::Symbol' => '$a',
			'PPI::Token::Operator' => '->',
			'PPI::Structure::Subscript' => '[a]',
			'PPI::Token::Structure' => '[',
			'PPI::Statement::Expression' => 'a',
			'PPI::Token::Word' => 'a',
			'PPI::Token::Structure' => ']',
			'PPI::Structure::Subscript' => '{b}',
			'PPI::Token::Structure' => '{',
			'PPI::Statement::Expression' => 'b',
			'PPI::Token::Word' => 'b',
			'PPI::Token::Structure' => '}',
			'PPI::Token::Operator' => '*',
			'PPI::Token::Symbol' => '$x',
		]
	);
}


exit 0;


sub test_cast_or_op {
	my ( $code, $want_cast ) = @_;

	my $d        = PPI::Document->new( \$code );
	my @tokens   = @{ $d->find( sub { 1 } ) };
	my @types    = map { ref $_ } @tokens;
	my $has_cast = grep { $_ eq 'PPI::Token::Cast' } @types;
	my $has_op   = grep { $_ eq 'PPI::Token::Operator' } @types;
	return
	  if $want_cast
	  ? ( ok( $has_cast, "$code: has cast" ) and ok( !$has_op, "$code: has no op" ) )
	  : ( ok( $has_op, "$code: has op" ) and ok( !$has_cast, "$code: has no cast" ) );

	@tokens = map { ref $_, $_->content } @tokens;
	diag explain \@tokens;
	return;
}


sub test_complex {
	my ( $code, $expected, $msg ) = @_;
	$msg = $code if !defined $msg;

	my $d = PPI::Document->new( \$code );
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref($_), $_->content() } @$tokens ];

	if ( $expected->[0] !~ /^PPI::Statement/ ) {
		unshift @$expected, 'PPI::Statement', $code;
	}
	my $ok = is_deeply( $tokens, $expected, $msg );
	if ( !$ok ) {
		diag ">>> $code -- $msg\n";
		diag explain $tokens;
		diag explain $expected;
	}

	return;
}
