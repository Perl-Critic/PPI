#!/usr/bin/perl

# Unit testing for PPI::Statement::Include

use t::lib::PPI::Test::pragmas;
use Test::More tests => 12065 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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
use VString::Version v10;
use VString::Version::Decimal v1.5;
END_PERL

	isa_ok( $document, 'PPI::Document' );
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 9, 'Found expected include statements.' );
	is( $statements->[0]->module_version, 1, 'Integer version' );
	is( $statements->[1]->module_version, 1.5, 'Float version' );
	is( $statements->[2]->module_version, 1, 'Version and argument' );
	is( $statements->[3]->module_version, undef, 'No version, no arguments' );
	is( $statements->[4]->module_version, undef, 'No version, with argument' );
	is( $statements->[5]->module_version, undef, 'No version, with arguments' );
	is( $statements->[6]->module_version, undef, 'Version include, no module' );
	is( $statements->[7]->module_version, 'v10', 'Version string' );
	is( $statements->[8]->module_version, 'v1.5', 'Version string with decimal' );
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


KEYWORDS_AS_MODULE_NAMES: {
	for my $name (
		# normal names
		'Foo',
		'Foo::Bar',
		'Foo::Bar::Baz',
		'version',
		# Keywords must parse as Word and not influence lexing
		# of subsequent curly braces.
		keys %PPI::Token::Word::KEYWORDS,
		# Other weird and/or special words, just in case
		'__PACKAGE__',
		'__FILE__',
		'__LINE__',
		'__SUB__',
		'AUTOLOAD',
	) {
		for my $include ( 'use', 'no' ) {  # 'require' does not force tokes to be words
			for my $version ( '', 'v1.2.3', '1.2.3', 'v10' ) {
				my $code = "$include $name $version;";

				my $Document = PPI::Document->new( \"$code 999;" );
				is( $Document->schildren(), 2, "$code number of statements in document" );
				isa_ok( $Document->schild(0), 'PPI::Statement::Include', $code );

				# first child is the include statement
				my $expected_tokens = [
					[ 'PPI::Token::Word', $include ],
					[ 'PPI::Token::Word', $name ],
				];
				if ( $version ) {
					push @$expected_tokens, [ 'PPI::Token::Number::Version', $version ];
				}
				push @$expected_tokens, [ 'PPI::Token::Structure', ';' ];
				my $got_tokens = [ map { [ ref $_, "$_" ] } $Document->schild(0)->schildren() ];
				is_deeply( $got_tokens, $expected_tokens, "$code tokens as expected" );

				# second child not swallowed up by the first
				isa_ok( $Document->schild(1), 'PPI::Statement', "$code prior statement end recognized" );
				isa_ok( $Document->schild(1)->schild(0), 'PPI::Token::Number', $code );
				is(     $Document->schild(1)->schild(0), '999', "$code number correct"  );
			}
		}
	}
}
