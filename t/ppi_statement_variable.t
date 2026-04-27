#!/usr/bin/perl

# Unit testing for PPI::Statement::Variable

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 58 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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

VARIABLE_IN_LIST_CONTEXT: {
	local $TODO = "variable declaration too greedy in list context (GH #25)";

	# open( my $fh, ">", $filename ) - Variable should only contain 'my $fh'
	my $doc = safe_new \"open( my \$fh, \">\", \$filename );";
	my $vars = $doc->find('Statement::Variable');
	is( ref($vars), 'ARRAY', 'open(my $fh, ...): found Variable statements' );
	is( scalar(@$vars), 1, 'open(my $fh, ...): exactly one Variable' );
	my @var_tokens = grep { $_->significant } $vars->[0]->children;
	is( scalar(@var_tokens), 2, 'open(my $fh, ...): Variable has 2 significant tokens (my + $fh)' );
	is( $var_tokens[0]->content, 'my', 'open(my $fh, ...): first token is my' );
	is( $var_tokens[1]->content, '$fh', 'open(my $fh, ...): second token is $fh' );
	is_deeply( [ $vars->[0]->variables ], [ '$fh' ], 'open(my $fh, ...): variables returns $fh' );

	# foo( our $x, $y ) - Variable should only contain 'our $x'
	$doc = safe_new \"foo( our \$x, \$y );";
	$vars = $doc->find('Statement::Variable');
	is( ref($vars), 'ARRAY', 'foo(our $x, ...): found Variable statements' );
	is( scalar(@$vars), 1, 'foo(our $x, ...): exactly one Variable' );
	@var_tokens = grep { $_->significant } $vars->[0]->children;
	is( scalar(@var_tokens), 2, 'foo(our $x, ...): Variable has 2 significant tokens' );

	# foo( local $x, $y ) - Variable should only contain 'local $x'
	$doc = safe_new \"foo( local \$x, \$y );";
	$vars = $doc->find('Statement::Variable');
	is( ref($vars), 'ARRAY', 'foo(local $x, ...): found Variable statements' );
	is( scalar(@$vars), 1, 'foo(local $x, ...): exactly one Variable' );
	@var_tokens = grep { $_->significant } $vars->[0]->children;
	is( scalar(@var_tokens), 2, 'foo(local $x, ...): Variable has 2 significant tokens' );

	# foo( state $x, $y ) - Variable should only contain 'state $x'
	$doc = safe_new \"foo( state \$x, \$y );";
	$vars = $doc->find('Statement::Variable');
	is( ref($vars), 'ARRAY', 'foo(state $x, ...): found Variable statements' );
	is( scalar(@$vars), 1, 'foo(state $x, ...): exactly one Variable' );
	@var_tokens = grep { $_->significant } $vars->[0]->children;
	is( scalar(@var_tokens), 2, 'foo(state $x, ...): Variable has 2 significant tokens' );

	# foo( my $x = 1, $y ) - Variable should contain 'my $x = 1'
	$doc = safe_new \"foo( my \$x = 1, \$y );";
	$vars = $doc->find('Statement::Variable');
	is( ref($vars), 'ARRAY', 'foo(my $x = 1, ...): found Variable statements' );
	is( scalar(@$vars), 1, 'foo(my $x = 1, ...): exactly one Variable' );
	@var_tokens = grep { $_->significant } $vars->[0]->children;
	is( scalar(@var_tokens), 4, 'foo(my $x = 1, ...): Variable has 4 significant tokens (my $x = 1)' );
	is_deeply( [ $vars->[0]->variables ], [ '$x' ], 'foo(my $x = 1, ...): variables returns $x' );
}

VARIABLE_REGRESSION: {
	# Ensure top-level variable declarations with initializers still work
	my $doc = safe_new \"my \$x = 1;";
	my $vars = $doc->find('Statement::Variable');
	is( ref($vars), 'ARRAY', 'my $x = 1: found Variable statements' );
	is( scalar(@$vars), 1, 'my $x = 1: exactly one Variable' );
	my @sig = grep { $_->significant } $vars->[0]->children;
	is( scalar(@sig), 5, 'my $x = 1;: Variable has 5 significant tokens (my $x = 1 ;)' );
	is_deeply( [ $vars->[0]->variables ], [ '$x' ], 'my $x = 1: variables returns $x' );

	# my ($a, $b) = (1, 2); should still work correctly
	$doc = safe_new \"my (\$a, \$b) = (1, 2);";
	$vars = $doc->find('Statement::Variable');
	is( ref($vars), 'ARRAY', 'my ($a, $b) = ...: found Variable statements' );
	is( scalar(@$vars), 1, 'my ($a, $b) = ...: exactly one Variable' );
	is_deeply( [ $vars->[0]->variables ], [ '$a', '$b' ], 'my ($a, $b) = ...: variables returns both' );
}
