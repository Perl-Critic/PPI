#!/usr/bin/perl

# Unit testing for PPI::Statement::Variable

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 38 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


VARIABLES: {
	# Test the things we assert to work in the synopsis
	my $Document = safe_new \<<'END_PERL';
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


# GH #225: Variable declarations should be detected inside builtin calls
# without parentheses, just as they are with parentheses.
VARIABLE_IN_BUILTIN_WITH_PARENS: {
	# Reference case: open() WITH parentheses (already works)
	my $code = 'open(my $fh, "<", "/etc/motd");';
	my $doc = safe_new \$code;
	is( $doc->serialize, $code, 'open() with parens: round-trip' );
	my $vars = $doc->find('Statement::Variable');
	is( ref($vars), 'ARRAY', 'open() with parens: found Statement::Variable' );
	is( $vars->[0]->type, 'my', 'open() with parens: type is my' );
	is_deeply( [ $vars->[0]->variables ], ['$fh'], 'open() with parens: found $fh' );
}


VARIABLE_IN_BUILTIN_NO_PARENS: {
	# GH #225: open my $fh WITHOUT parentheses
	my $code = 'open my $fh, "<", "/etc/motd";';
	my $doc = safe_new \$code;
	is( $doc->serialize, $code, 'open my without parens: round-trip' );
	my $vars = $doc->find('Statement::Variable');
	ok( ref $vars eq 'ARRAY' && @$vars == 1,
		'open my without parens: found one Statement::Variable' );
	is( ( ref $vars eq 'ARRAY' && @$vars ) ? $vars->[0]->type : undef,
		'my', 'open my without parens: type is my' );
	is_deeply(
		( ref $vars eq 'ARRAY' && @$vars ) ? [ $vars->[0]->variables ] : [],
		['$fh'], 'open my without parens: found $fh' );
}


VARIABLE_PRINT_MY: {
	# Another case: print my $x = 1;
	my $code = 'print my $x = 1;';
	my $doc = safe_new \$code;
	is( $doc->serialize, $code, 'print my: round-trip' );
	my $vars = $doc->find('Statement::Variable');
	ok( ref $vars eq 'ARRAY' && @$vars == 1,
		'print my: found one Statement::Variable' );
	is( ( ref $vars eq 'ARRAY' && @$vars ) ? $vars->[0]->type : undef,
		'my', 'print my: type is my' );
}


VARIABLE_FAT_COMMA: {
	# Edge case: 'my' used as a hash key via fat comma should NOT create Variable
	my $doc = safe_new \'func my => 1;';
	is( $doc->find('Statement::Variable'), '', 'my as fat comma: no Statement::Variable' );
}


