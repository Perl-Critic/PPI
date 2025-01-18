#!/usr/bin/perl

# Unit testing for PPI::Statement::Include

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 6070 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI             ();
use PPI::Singletons qw( %KEYWORDS );
use Helper 'safe_new';

TYPE: {
	my $document = safe_new \<<'END_PERL';
require 5.6;
require Module;
require 'Module.pm';
use 5.6;
use Module;
use Module 1.00;
no Module;
END_PERL
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar(@$statements), 7, 'Found 7 include statements' );
	my @expected = qw{ require require require use use use no };
	foreach ( 0 .. 6 ) {
		is( $statements->[$_]->type, $expected[$_], "->type $_ ok" );
	}
}

MODULE_VERSION: {
	my $document = safe_new \<<'END_PERL';
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
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 9, 'Found expected include statements.' );
	is( $statements->[0]->module_version, 1,     'Integer version' );
	is( $statements->[1]->module_version, 1.5,   'Float version' );
	is( $statements->[2]->module_version, 1,     'Version and argument' );
	is( $statements->[3]->module_version, undef, 'No version, no arguments' );
	is( $statements->[4]->module_version, undef, 'No version, with argument' );
	is( $statements->[5]->module_version, undef, 'No version, with arguments' );
	is( $statements->[6]->module_version, undef, 'Version include, no module' );
	is( $statements->[7]->module_version, 'v10', 'Version string' );
	is( $statements->[8]->module_version,
		'v1.5', 'Version string with decimal' );
}

VERSION: {
	my $document = safe_new \<<'END_PERL';
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
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 11, 'Found expected include statements.' );

	is( $statements->[0]->version, 'v5.6.1', 'use v-string' );
	is( $statements->[1]->version, '5.6.1',  'use v-string, no leading "v"' );
	is( $statements->[2]->version, '5.006_001', 'use developer release' );
	is( $statements->[3]->version,
		'5.006', 'use back-compatible version, followed by...' );
	is( $statements->[4]->version, '5.6.1',
		'... use v-string, no leading "v"' );

	is( $statements->[5]->version, 'v5.6.1', 'require v-string' );
	is( $statements->[6]->version, '5.6.1',
		'require v-string, no leading "v"' );
	is( $statements->[7]->version, '5.006_001', 'require developer release' );
	is( $statements->[8]->version,
		'5.006', 'require back-compatible version, followed by...' );
	is( $statements->[9]->version,
		'5.6.1', '... require v-string, no leading "v"' );

	is( $statements->[10]->version, '', 'use module version' );
}

VERSION_LITERAL: {
	my $document = safe_new \<<'END_PERL';
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
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 11, 'Found expected include statements.' );

	is( $statements->[0]->version_literal, v5.6.1, 'use v-string' );
	is( $statements->[1]->version_literal,
		5.6.1, 'use v-string, no leading "v"' );
	is( $statements->[2]->version_literal, 5.006_001, 'use developer release' );
	is( $statements->[3]->version_literal,
		5.006, 'use back-compatible version, followed by...' );
	is( $statements->[4]->version_literal,
		5.6.1, '... use v-string, no leading "v"' );

	is( $statements->[5]->version_literal, v5.6.1, 'require v-string' );
	is( $statements->[6]->version_literal,
		5.6.1, 'require v-string, no leading "v"' );
	is( $statements->[7]->version_literal,
		5.006_001, 'require developer release' );
	is( $statements->[8]->version_literal,
		5.006, 'require back-compatible version, followed by...' );
	is( $statements->[9]->version_literal,
		5.6.1, '... require v-string, no leading "v"' );

	is( $statements->[10]->version_literal, '', 'use module version' );
}

ARGUMENTS: {
	my $document = safe_new \<<'END_PERL';
use 5.006;       # Don't expect anything.
use Foo;         # Don't expect anything.
use Foo 5;       # Don't expect anything.
use Foo 'bar';   # One thing.
use Foo 5 'bar'; # One thing.
use Foo qw< bar >, "baz";
use Test::More tests => 5 * 9   # Don't get tripped up by the lack of the ";"
END_PERL
	my $statements = $document->find('PPI::Statement::Include');
	is( scalar @{$statements}, 7, 'Found expected include statements.' );

	is(
		scalar $statements->[0]->arguments,
		undef, 'arguments for perl version',
	);
	is(
		scalar $statements->[1]->arguments,
		undef, 'arguments with no arguments',
	);
	is(
		scalar $statements->[2]->arguments,
		undef, 'arguments with no arguments but module version',
	);

	my @arguments = $statements->[3]->arguments;
	is( scalar @arguments,      1,        'arguments with single argument' );
	is( $arguments[0]->content, q<'bar'>, 'arguments with single argument' );

	@arguments = $statements->[4]->arguments;
	is(
		scalar @arguments,
		1, 'arguments with single argument and module version',
	);
	is(
		$arguments[0]->content,
		q<'bar'>, 'arguments with single argument and module version',
	);

	@arguments = $statements->[5]->arguments;
	is( scalar @arguments, 3, 'arguments with multiple arguments', );
	is(
		$arguments[0]->content,
		q/qw< bar >/, 'arguments with multiple arguments',
	);
	is( $arguments[1]->content, q<,>, 'arguments with multiple arguments', );
	is( $arguments[2]->content, q<"baz">,
		'arguments with multiple arguments', );

	@arguments = $statements->[6]->arguments;
	is( scalar @arguments,      5,       'arguments with Test::More', );
	is( $arguments[0]->content, 'tests', 'arguments with Test::More', );
	is( $arguments[1]->content, q[=>],   'arguments with Test::More', );
	is( $arguments[2]->content, 5,       'arguments with Test::More', );
	is( $arguments[3]->content, '*',     'arguments with Test::More', );
	is( $arguments[4]->content, 9,       'arguments with Test::More', );
}

KEYWORDS_AS_MODULE_NAMES: {
	my %known_bad = map { $_ => 1 } 'no m 1.2.3;', 'no m ;', 'no m v1.2.3;',
	  'no m v10;',     'no q 1.2.3;', 'no q ;',    'no q v1.2.3;', 'no q v10;',
	  'no qq 1.2.3;',  'no qq ;', 'no qq v1.2.3;', 'no qq v10;', 'no qr 1.2.3;',
	  'no qr ;',       'no qr v1.2.3;', 'no qr v10;', 'no qw 1.2.3;', 'no qw ;',
	  'no qw v1.2.3;', 'no qw v10;',    'no qx 1.2.3;', 'no qx ;',
	  'no qx v1.2.3;', 'no qx v10;',    'no s 1.2.3;', 'no s ;', 'no s v1.2.3;',
	  'no s v10;',     'no tr 1.2.3;', 'no tr ;', 'no tr v1.2.3;', 'no tr v10;',
	  'no y 1.2.3;',   'no y ;', 'no y v1.2.3;',  'no y v10;', 'use m 1.2.3;',
	  'use m ;',       'use m v1.2.3;', 'use m v10;', 'use q 1.2.3;', 'use q ;',
	  'use q v1.2.3;',  'use q v10;',   'use qq 1.2.3;', 'use qq ;',
	  'use qq v1.2.3;', 'use qq v10;',  'use qr 1.2.3;', 'use qr ;',
	  'use qr v1.2.3;', 'use qr v10;',  'use qw 1.2.3;', 'use qw ;',
	  'use qw v1.2.3;', 'use qw v10;',  'use qx 1.2.3;', 'use qx ;',
	  'use qx v1.2.3;', 'use qx v10;',  'use s 1.2.3;',  'use s ;',
	  'use s v1.2.3;',  'use s v10;',   'use tr 1.2.3;', 'use tr ;',
	  'use tr v1.2.3;', 'use tr v10;',  'use y 1.2.3;',  'use y ;',
	  'use y v1.2.3;',  'use y v10;';
	my %known_badish = map { $_ => 1 } 'use not ;', 'use lt ;',
	  'no and 1.2.3;', 'no and ;', 'no and v1.2.3;', 'no and v10;',
	  'no cmp 1.2.3;', 'no cmp ;', 'no cmp v1.2.3;', 'no cmp v10;',
	  'no eq 1.2.3;',  'no eq ;', 'no eq v1.2.3;', 'no eq v10;', 'no ge 1.2.3;',
	  'no ge ;',       'no ge v1.2.3;', 'no ge v10;', 'no gt 1.2.3;', 'no gt ;',
	  'no gt v1.2.3;',  'no gt v10;',   'no le 1.2.3;',  'no le ;',
	  'no le v1.2.3;',  'no le v10;',   'no lt 1.2.3;',  'no lt ;',
	  'no lt v1.2.3;',  'no lt v10;',   'no ne 1.2.3;',  'no ne ;',
	  'no ne v1.2.3;',  'no ne v10;',   'no not 1.2.3;', 'no not ;',
	  'no not v1.2.3;', 'no not v10;',  'no or 1.2.3;',  'no or ;',
	  'no or v1.2.3;',  'no or v10;',   'no x 1.2.3;', 'no x ;', 'no x v1.2.3;',
	  'no x v10;',      'no xor 1.2.3;',   'no xor ;',       'no xor v1.2.3;',
	  'no xor v10;',    'use and 1.2.3;',  'use and ;',      'use and v1.2.3;',
	  'use and v10;',   'use cmp 1.2.3;',  'use cmp ;',      'use cmp v1.2.3;',
	  'use cmp v10;',   'use eq 1.2.3;',   'use eq ;',       'use eq v1.2.3;',
	  'use eq v10;',    'use ge 1.2.3;',   'use ge ;',       'use ge v1.2.3;',
	  'use ge v10;',    'use gt 1.2.3;',   'use gt ;',       'use gt v1.2.3;',
	  'use gt v10;',    'use le 1.2.3;',   'use le ;',       'use le v1.2.3;',
	  'use le v10;',    'use lt 1.2.3;',   'use lt v1.2.3;', 'use lt v10;',
	  'use ne 1.2.3;',  'use ne ;',        'use ne v1.2.3;', 'use ne v10;',
	  'use not 1.2.3;', 'use not v1.2.3;', 'use not v10;',   'use or 1.2.3;',
	  'use or ;', 'use or v1.2.3;',    'use or v10;', 'use x 1.2.3;', 'use x ;',
	  'use x v1.2.3;',   'use x v10;', 'use xor 1.2.3;', 'use xor ;',
	  'use xor v1.2.3;', 'use xor v10;';
	for my $name (
		# normal names
		'Foo',
		'Foo::Bar',
		'Foo::Bar::Baz',
		'version',
		# Keywords must parse as Word and not influence lexing
		# of subsequent curly braces.
		keys %KEYWORDS,
		# Other weird and/or special words, just in case
		'__PACKAGE__',
		'__FILE__',
		'__LINE__',
		'__SUB__',
		'AUTOLOAD',
	  )
	{
		for my $include ( 'use', 'no' )
		{    # 'require' does not force tokes to be words
			for my $version ( '', 'v1.2.3', '1.2.3', 'v10' ) {
				my $code = "$include $name $version;";

				my $Document = safe_new \"$code 999;";

				subtest "'$code'", => sub {
					{
						local $TODO = $known_bad{$code} ? "known bug" : undef;
						is( $Document->schildren(),
							2, "$code number of statements in document" );
					}
					isa_ok( $Document->schild(0),
						'PPI::Statement::Include', $code );
					{
						local $TODO =
						  ( $known_bad{$code} || $known_badish{$code} )
						  ? "known bug"
						  : undef;
						# first child is the include statement
						my $expected_tokens = [
							[ 'PPI::Token::Word', $include ],
							[ 'PPI::Token::Word', $name ],
						];
						if ($version) {
							push @$expected_tokens,
							  [ 'PPI::Token::Number::Version', $version ];
						}
						push @$expected_tokens,
						  [ 'PPI::Token::Structure', ';' ];
						my $got_tokens = [ map { [ ref $_, "$_" ] }
							  $Document->schild(0)->schildren() ];
						is_deeply( $got_tokens, $expected_tokens,
							"$code tokens as expected" );
					}

					{
						local $TODO = $known_bad{$code} ? "known bug" : undef;
						# second child not swallowed up by the first
						isa_ok( $Document->schild(1),
							'PPI::Statement',
							"$code prior statement end recognized" );
						isa_ok( eval { $Document->schild(1)->schild(0) },
							'PPI::Token::Number', $code );
						is( eval { $Document->schild(1)->schild(0) },
							'999', "$code number correct" );
					}
				};
			}
		}
	}
}
