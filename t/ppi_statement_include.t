#!/usr/bin/perl

# Unit testing for PPI::Statement::Include

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 64;
use Test::NoWarnings;
use PPI;


TYPE: {
	my $document = PPI::Document->new(\<<'END_PERL');
require 5.6;
require Module;
require 'Module.pm';
use 5.6;
use Module;
use Module 1.00;
no Module;
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar(@$statements), 7, 'Found 7 include statements' );
	my @expected = qw{ require require require use use use no };
	foreach ( 0 .. 6 ) {
		is( $statements->[$_]->type, $expected[$_], "->type $_ ok" );
	}
}


MODULE_VERSION: {
	my $document = PPI::Document->new(\<<'END_PERL');
use Integer::Version 1;
use Float::Version 1.5;
use Version::With::Argument 1 2;
use No::Version;
use No::Version::With::Argument 'x';
use No::Version::With::Arguments 1, 2;
use 5.005;
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 7, 'Found expected include statements.' );
	is( $statements->[0]->module_version, 1, 'Integer version' );
	is( $statements->[1]->module_version, 1.5, 'Float version' );
	is( $statements->[2]->module_version, 1, 'Version and argument' );
	is( $statements->[3]->module_version, undef, 'No version, no arguments' );
	is( $statements->[4]->module_version, undef, 'No version, with argument' );
	is( $statements->[5]->module_version, undef, 'No version, with arguments' );
	is( $statements->[6]->module_version, undef, 'Version include, no module' );
}


VERSION: {
	my $document = PPI::Document->new(\<<'END_PERL');
# Examples from perlfunc in 5.10.
use v5.6.1;
use 5.6.1;
use 5.006_001;
use 5.006; use 5.6.1;

# Same, but using require.
require v5.6.1;
require 5.6.1;
require 5.006_001;
require 5.006; require 5.6.1;

# Module.
use Float::Version 1.5;
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 11, 'Found expected include statements.' );

	is( $statements->[0]->version, 'v5.6.1', 'use v-string' );
	is( $statements->[1]->version, '5.6.1', 'use v-string, no leading "v"' );
	is( $statements->[2]->version, '5.006_001', 'use developer release' );
	is( $statements->[3]->version, '5.006', 'use back-compatible version, followed by...' );
	is( $statements->[4]->version, '5.6.1', '... use v-string, no leading "v"' );

	is( $statements->[5]->version, 'v5.6.1', 'require v-string' );
	is( $statements->[6]->version, '5.6.1', 'require v-string, no leading "v"' );
	is( $statements->[7]->version, '5.006_001', 'require developer release' );
	is( $statements->[8]->version, '5.006', 'require back-compatible version, followed by...' );
	is( $statements->[9]->version, '5.6.1', '... require v-string, no leading "v"' );

	is( $statements->[10]->version, '', 'use module version' );
}


VERSION_LITERAL: {
	my $document = PPI::Document->new(\<<'END_PERL');
# Examples from perlfunc in 5.10.
use v5.6.1;
use 5.6.1;
use 5.006_001;
use 5.006; use 5.6.1;

# Same, but using require.
require v5.6.1;
require 5.6.1;
require 5.006_001;
require 5.006; require 5.6.1;

# Module.
use Float::Version 1.5;
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 11, 'Found expected include statements.' );

	is( $statements->[0]->version_literal, v5.6.1, 'use v-string' );
	is( $statements->[1]->version_literal, 5.6.1, 'use v-string, no leading "v"' );
	is( $statements->[2]->version_literal, 5.006_001, 'use developer release' );
	is( $statements->[3]->version_literal, 5.006, 'use back-compatible version, followed by...' );
	is( $statements->[4]->version_literal, 5.6.1, '... use v-string, no leading "v"' );

	is( $statements->[5]->version_literal, v5.6.1, 'require v-string' );
	is( $statements->[6]->version_literal, 5.6.1, 'require v-string, no leading "v"' );
	is( $statements->[7]->version_literal, 5.006_001, 'require developer release' );
	is( $statements->[8]->version_literal, 5.006, 'require back-compatible version, followed by...' );
	is( $statements->[9]->version_literal, 5.6.1, '... require v-string, no leading "v"' );

	is( $statements->[10]->version_literal, '', 'use module version' );
}


ARGUMENTS: {
	my $document = PPI::Document->new(\<<'END_PERL');
use 5.006;       # Don't expect anything.
use Foo;         # Don't expect anything.
use Foo 5;       # Don't expect anything.
use Foo 'bar';   # One thing.
use Foo 5 'bar'; # One thing.
use Foo qw< bar >, "baz";
use Test::More tests => 5 * 9   # Don't get tripped up by the lack of the ";"
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 7, 'Found expected include statements.' );

	is(
		scalar $statements->[0]->arguments, undef, 'arguments for perl version',
	);
	is(
		scalar $statements->[1]->arguments,
		undef,
		'arguments with no arguments',
	);
	is(
		scalar $statements->[2]->arguments,
		undef,
		'arguments with no arguments but module version',
	);

	my @arguments = $statements->[3]->arguments;
	is( scalar @arguments, 1, 'arguments with single argument' );
	is( $arguments[0]->content, q<'bar'>, 'arguments with single argument' );

	@arguments = $statements->[4]->arguments;
	is(
		scalar @arguments,
		1,
		'arguments with single argument and module version',
	);
	is(
		$arguments[0]->content,
		q<'bar'>,
		'arguments with single argument and module version',
	);

	@arguments = $statements->[5]->arguments;
	is(
		scalar @arguments,
		3,
		'arguments with multiple arguments',
	);
	is(
		$arguments[0]->content,
		q/qw< bar >/,
		'arguments with multiple arguments',
	);
	is(
		$arguments[1]->content,
		q<,>,
		'arguments with multiple arguments',
	);
	is(
		$arguments[2]->content,
		q<"baz">,
		'arguments with multiple arguments',
	);

	@arguments = $statements->[6]->arguments;
	is(
		scalar @arguments,
		5,
		'arguments with Test::More',
	);
	is(
		$arguments[0]->content,
		'tests',
		'arguments with Test::More',
	);
	is(
		$arguments[1]->content,
		q[=>],
		'arguments with Test::More',
	);
	is(
		$arguments[2]->content,
		5,
		'arguments with Test::More',
	);
	is(
		$arguments[3]->content,
		'*',
		'arguments with Test::More',
	);
	is(
		$arguments[4]->content,
		9,
		'arguments with Test::More',
	);
}
