#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Double

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 20;
use Test::NoWarnings;
use PPI;


INTERPOLATIONS: {
	# Get a set of objects
	my $Document = PPI::Document->new(\<<'END_PERL');
"no interpolations"
"no \@interpolations"
"has $interpolation"
"has @interpolation"
"has \\@interpolation"
"" # False content to test double-negation scoping
END_PERL
	isa_ok( $Document, 'PPI::Document' );
	my $strings = $Document->find('Token::Quote::Double');
	is( scalar @{$strings}, 6, 'Found the 6 test strings' );
	is( $strings->[0]->interpolations, '', 'String 1: No interpolations'  );
	is( $strings->[1]->interpolations, '', 'String 2: No interpolations'  );
	is( $strings->[2]->interpolations, 1,  'String 3: Has interpolations' );
	is( $strings->[3]->interpolations, 1,  'String 4: Has interpolations' );
	is( $strings->[4]->interpolations, 1,  'String 5: Has interpolations' );
	is( $strings->[5]->interpolations, '', 'String 6: No interpolations'  );
}


SIMPLIFY: {
	my $Document = PPI::Document->new(\<<'END_PERL');
"no special characters"
"has \"double\" quotes"
"has 'single' quotes"
"has $interpolation"
"has @interpolation"
""
END_PERL
	isa_ok( $Document, 'PPI::Document' );
	my $strings = $Document->find('Token::Quote::Double');
	is( scalar @{$strings}, 6, 'Found the 6 test strings' );
	is( $strings->[0]->simplify, q<'no special characters'>, 'String 1: No special characters' );
	is( $strings->[1]->simplify, q<"has \"double\" quotes">, 'String 2: Double quotes'         );
	is( $strings->[2]->simplify, q<"has 'single' quotes">,   'String 3: Single quotes'         );
	is( $strings->[3]->simplify, q<"has $interpolation">,    'String 3: Has interpolation'     );
	is( $strings->[4]->simplify, q<"has @interpolation">,    'String 4: Has interpolation'     );
	is( $strings->[5]->simplify, q<''>,                      'String 6: Empty string'          );
}


STRING: {
	my $Document = PPI::Document->new( \'print "foo";' );
	isa_ok( $Document, 'PPI::Document' );
	my $Double = $Document->find_first('Token::Quote::Double');
	isa_ok( $Double, 'PPI::Token::Quote::Double' );
	is( $Double->string, 'foo', '->string returns as expected' );
}
