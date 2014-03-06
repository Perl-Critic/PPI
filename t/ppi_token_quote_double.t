#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Double

use lib 't/lib';
use PPI::Test::pragmas;
use PPI::Test qw( :cmp );
use Test::More tests => 14;
use PPI;

sub t {
	{ class => shift, content => shift, @_ };
}

sub i {
	my ( $code, $interpolations, %args ) = @_;
	cmp_element(
		$code,
		t( 'PPI::Token::Quote::Double', $code, interpolations => $interpolations, %args )
	);
}

sub si {
	cmp_element( shift, { class => 'PPI::Token::Quote::Double', simplify => shift } );
}

INTERPOLATIONS: {
	i( '"no interpolations"',                                '' );
	i( '"no \@interpolations"',                              '' );
	i( '"has $interpolation"',                               1 );
	i( '"has @interpolation"',                               1 );
	i( '"has \\\\@interpolation"',                           1 );
	i( '"" # False content to test double-negation scoping', '', content => '""', STOP => 1 );
}

SIMPLIFY: {
	si( '"no special characters"', q<'no special characters'> );
	si( '"has \"double\" quotes"', q<"has \"double\" quotes"> );
	si( '"has \'single\' quotes"', q<"has 'single' quotes">   );
	si( '"has $interpolation"',    q<"has $interpolation">    );
	si( '"has @interpolation"',    q<"has @interpolation">    );
	si( '""',                      q<''>                      );
}

PARSING: {
	cmp_selement(
		'print "foo";',
		[
			t( "PPI::Token::Word",          'print' ),
			t( "PPI::Token::Quote::Double", '"foo"' ),
			t( "PPI::Token::Structure",     ';' ),
		]
	);
}
