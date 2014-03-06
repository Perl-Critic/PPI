#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Double

use lib 't/lib';
use PPI::Test::pragmas;
use PPI::Test qw( :cmp );
use Test::More tests => 14;
use PPI;


INTERPOLATIONS: {
	for my $test (
		{ interpolations => '', code => '"no interpolations"' },
		{ interpolations => '', code => '"no \@interpolations"' },
		{ interpolations => 1,  code => '"has $interpolation"' },
		{ interpolations => 1,  code => '"has @interpolation"' },
		{ interpolations => 1,  code => '"has \\\\@interpolation"' },
		{
			interpolations => '',
			code => '"" # False content to test double-negation scoping',
			content => '""',
			STOP => 1,
		},
	) {
		my $code = delete $test->{code};
		cmp_element(
			$code,
			{
				class => 'PPI::Token::Quote::Double',
				content => $code,
				%$test,
			}
		);
	}
}


SIMPLIFY: {
	for my $test (
		{ code => '"no special characters"', simplify => q<'no special characters'>, },
		{ code => '"has \"double\" quotes"', simplify => q<"has \"double\" quotes">, },
		{ code => '"has \'single\' quotes"', simplify => q<"has 'single' quotes">,   },
		{ code => '"has $interpolation"',    simplify => q<"has $interpolation">,    },
		{ code => '"has @interpolation"',    simplify => q<"has @interpolation">,    },
		{ code => '""',                      simplify => q<''>,                      },
	) {
		my $code = delete $test->{code};
		cmp_element( $code, { class => 'PPI::Token::Quote::Double', %$test } );
	}
}


PARSING: {
	cmp_selement(
		'print "foo";',
		[
			{ class => 'PPI::Token::Word',          content => 'print' },
			{ class => 'PPI::Token::Quote::Double', content => '"foo"' },
			{ class => 'PPI::Token::Structure',     content => ';' },
		]
	);
}
