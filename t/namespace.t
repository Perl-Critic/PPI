#!/usr/bin/perl

# Unit testing for PPI::Element->namespace and PPI::Statement::Package->block

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 46 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


PACKAGE_BLOCK_METHOD: {
	local $TODO = "PPI::Statement::Package->block not yet implemented";

	my $doc = safe_new \"package Foo { 1 }";
	my $pkg = $doc->find_first('Statement::Package');
	my $block = eval { $pkg->block };
	isa_ok( $block, 'PPI::Structure::Block', 'block() returns the block' );

	my $doc2 = safe_new \"package Bar;";
	my $pkg2 = $doc2->find_first('Statement::Package');
	my $no_block = eval { $pkg2->block };
	is( $no_block, '', 'block() returns false for semicolon-form' );
}


NO_PACKAGE_IS_MAIN: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $doc = safe_new \"my \$x = 1;";
	my $stmt = $doc->find_first('Statement');
	is( eval { $stmt->namespace }, 'main',
		'code with no package declaration is in main' );
}


SEMICOLON_FORM_BASIC: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $doc = safe_new \"package Foo; my \$x = 1;";
	my @stmts = $doc->schildren;
	is( eval { $stmts[1]->namespace }, 'Foo',
		'statement after package Foo; is in Foo' );
}


MULTIPLE_PACKAGES: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $doc = safe_new \"package Foo; my \$x = 1; package Bar; my \$y = 2;";
	my @stmts = $doc->schildren;
	is( eval { $stmts[1]->namespace }, 'Foo', 'between Foo and Bar is Foo' );
	is( eval { $stmts[3]->namespace }, 'Bar', 'after Bar is Bar' );
}


CODE_BEFORE_ANY_PACKAGE: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $doc = safe_new \"my \$x = 1; package Foo; my \$y = 2;";
	my @stmts = $doc->schildren;
	is( eval { $stmts[0]->namespace }, 'main', 'code before any package is main' );
	is( eval { $stmts[2]->namespace }, 'Foo', 'code after package Foo is Foo' );
}


SCOPED_PACKAGE_IN_BLOCK: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $code = <<'END_PERL';
package Foo;
my $a = 1;
{
    package Alpha;
    my $b = 2;
}
my $c = 3;
END_PERL

	my $doc = safe_new \$code;
	my @top = $doc->schildren;

	is( eval { $top[1]->namespace }, 'Foo',
		'$a after package Foo; is in Foo' );

	my $block = $top[2]->find_first('Structure::Block');
	my @inner = $block->schildren;

	is( eval { $inner[1]->namespace }, 'Alpha',
		'$b after package Alpha; inside block is in Alpha' );

	is( eval { $top[3]->namespace }, 'Foo',
		'$c after block reverts to Foo' );
}


BLOCK_FORM_PACKAGE: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $code = <<'END_PERL';
my $before = 1;
package Baz {
    my $inside = 2;
}
my $after = 3;
END_PERL

	my $doc = safe_new \$code;
	my @top = $doc->schildren;

	is( eval { $top[0]->namespace }, 'main',
		'code before block-form package is main' );

	my $pkg = $doc->find_first('Statement::Package');
	my $block = $pkg->find_first('Structure::Block');
	my @inner = $block->schildren;
	is( eval { $inner[0]->namespace }, 'Baz',
		'code inside block-form package is Baz' );

	is( eval { $top[2]->namespace }, 'main',
		'code after block-form package reverts to main' );
}


NESTED_BLOCK_FORM: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $code = <<'END_PERL';
package Outer {
    package Inner {
        my $deep = 1;
    }
    my $mid = 2;
}
my $out = 3;
END_PERL

	my $doc = safe_new \$code;
	my @top = $doc->schildren;

	my $outer_pkg = $top[0];
	my $outer_block = $outer_pkg->find_first('Structure::Block');
	my @outer_kids = $outer_block->schildren;

	my $inner_pkg = $outer_kids[0];
	my $inner_block = $inner_pkg->find_first('Structure::Block');
	my @inner_kids = $inner_block->schildren;

	is( eval { $inner_kids[0]->namespace }, 'Inner',
		'deep inside nested block-form is Inner' );
	is( eval { $outer_kids[1]->namespace }, 'Outer',
		'after inner block reverts to Outer' );

	is( eval { $top[1]->namespace }, 'main',
		'after outer block reverts to main' );
}


TOKEN_LEVEL_NAMESPACE: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $doc = safe_new \"package Foo; my \$x = 1;";
	my $symbol = $doc->find_first('Token::Symbol');
	is( eval { $symbol->namespace }, 'Foo',
		'individual token reports correct namespace' );
}


PACKAGE_STATEMENT_NAMESPACE_UNCHANGED: {
	my $doc = safe_new \"package Foo;";
	my $pkg = $doc->find_first('Statement::Package');
	is( $pkg->namespace, 'Foo',
		'Package->namespace still returns declared name' );
}


SEMICOLON_IN_BLOCK_THEN_BLOCK_FORM: {
	local $TODO = "PPI::Element->namespace not yet implemented";

	my $code = <<'END_PERL';
package Foo;
my $a = 1;
package Bar {
    my $b = 2;
}
my $c = 3;
END_PERL

	my $doc = safe_new \$code;
	my @top = $doc->schildren;

	is( eval { $top[1]->namespace }, 'Foo',
		'$a after package Foo; is Foo' );

	my $bar_pkg = $top[2];
	my $bar_block = $bar_pkg->find_first('Structure::Block');
	my @inner = $bar_block->schildren;
	is( eval { $inner[0]->namespace }, 'Bar',
		'$b inside block-form Bar is Bar' );

	is( eval { $top[3]->namespace }, 'Foo',
		'$c after block-form Bar reverts to Foo' );
}
