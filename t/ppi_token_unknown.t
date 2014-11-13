#!/usr/bin/perl

# Unit testing for PPI::Token::Unknown

use t::lib::PPI::Test::pragmas;
use Test::More tests => 2;

use PPI;


OPERATOR_MULT_CAST: {
	my @tests = (
		{
			desc     => 'multiply, not cast',
			code     => '$c{d}*$e',
			expected => [
				'PPI::Statement'             => '$c{d}*$e',
				'PPI::Token::Symbol'         => '$c',
				'PPI::Structure::Subscript'  => '{d}',
				'PPI::Token::Structure'      => '{',
				'PPI::Statement::Expression' => 'd',
				'PPI::Token::Word'           => 'd',
				'PPI::Token::Structure'      => '}',
				'PPI::Token::Operator'       => '*',
				'PPI::Token::Symbol'         => '$e',
			]
		},
	);

	for my $test ( @tests ) {
		my $d = PPI::Document->new( \$test->{code} );
		my $tokens = $d->find( sub { 1 } );
		$tokens = [ map { ref $_, $_->content } @$tokens ];
		my $expected = $test->{expected};
		unshift @$expected, 'PPI::Statement', $test->{code} if $expected->[0] !~ /^PPI::Statement/;
		next if is_deeply( $tokens, $expected, $test->{desc} );

		diag "$test->{code} ($test->{desc})\n";
		diag explain $tokens;
		diag explain $test->{expected};
	}
}
