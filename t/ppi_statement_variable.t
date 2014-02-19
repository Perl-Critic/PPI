#!/usr/bin/perl

# Unit testing for PPI::Statement::Variable

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More 'no_plan';
use Test::NoWarnings;
use PPI;


VARIABLES: {
	# Test the things we assert to work in the synopsis
	my $Document = PPI::Document->new(\<<'END_PERL');
package Bar;
my $foo = 1;
my ( $foo, $bar) = (1, 2);
our $foo = 1;
local $foo;
local $foo = 1;
LABEL: my $foo = 1;

# As well as those basics, lets also try some harder ones
local($foo = $bar->$bar(), $bar);
END_PERL
	isa_ok( $Document, 'PPI::Document' );

	# There should be 6 statement objects
	my $ST = $Document->find('Statement::Variable');
	is( ref($ST), 'ARRAY', 'Found statements' );
	is( scalar(@$ST), 7, 'Found 7 ::Variable objects' );
	foreach my $Var ( @$ST ) {
		isa_ok( $Var, 'PPI::Statement::Variable' );
	}
	is_deeply( [ $ST->[0]->variables ], [ '$foo' ],         '1: Found $foo' );
	is_deeply( [ $ST->[1]->variables ], [ '$foo', '$bar' ], '2: Found $foo and $bar' );
	is_deeply( [ $ST->[2]->variables ], [ '$foo' ],         '3: Found $foo' );
	is_deeply( [ $ST->[3]->variables ], [ '$foo' ],         '4: Found $foo' );
	is_deeply( [ $ST->[4]->variables ], [ '$foo' ],         '5: Found $foo' );
	is_deeply( [ $ST->[5]->variables ], [ '$foo' ],         '6: Found $foo' );
	is_deeply( [ $ST->[6]->variables ], [ '$foo', '$bar' ], '7: Found $foo and $bar' );
}
