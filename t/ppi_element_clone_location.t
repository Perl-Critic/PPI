#!/usr/bin/perl

# Test that location data survives clone operations
# See https://github.com/Perl-Critic/PPI/issues/80

use lib 't/lib';
use PPI::Test::pragmas;

use PPI::Document ();
use PPI::Find     ();
use Test::More tests => 11 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use Helper 'safe_new';

# Basic: clone a statement and check location
SCOPE: {
	my $doc = safe_new \"f(\$x, \$z, \$x);";
	my $stmt = $doc->find_first('PPI::Statement');
	my $clone = $stmt->clone;
	local $TODO = "location data should survive clone";
	is $clone->line_number, 1, 'cloned statement has line_number';
}

# Clone a statement from a multi-line document
SCOPE: {
	my $src = "my \$x = 1;\nmy \$y = 2;\n";
	my $doc = safe_new \$src;
	my @stmts = @{ $doc->find('PPI::Statement') || [] };
	is scalar @stmts, 2, 'found two statements';

	my $clone2 = $stmts[1]->clone;
	local $TODO = "location data should survive clone";
	is $clone2->line_number, 2, 'cloned second statement preserves line 2';
}

# Clone a leaf token and check location
SCOPE: {
	my $doc = safe_new \"my \$x = 1;";
	my $sym = $doc->find_first('PPI::Token::Symbol');
	my $clone = $sym->clone;
	local $TODO = "location data should survive clone";
	is $clone->line_number,   1, 'cloned token has line_number';
	is $clone->column_number, 4, 'cloned token has column_number';
}
