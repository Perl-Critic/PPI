#!/usr/bin/perl

# Unit testing for PPI::Statement::Package

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 129;
use Test::NoWarnings;
use PPI;


HASH_CONSTRUCTORS_DONT_CONTAIN_PACKAGES_RT52259: {
	my $Document = PPI::Document->new(\<<'END_PERL');
{    package  => "", };
+{   package  => "", };
{   'package' => "", };
+{  'package' => "", };
{   'package' ,  "", };
+{  'package' ,  "", };
END_PERL
	isa_ok( $Document, 'PPI::Document' );

	my $packages = $Document->find('PPI::Statement::Package');
	my $test_name = 'Found no package statements in hash constructors - RT #52259';
	if (not $packages) {
		pass $test_name;
	} elsif ( not is(scalar @{$packages}, 0, $test_name) ) {
		diag 'Package statements found:';
		diag $_->parent()->parent()->content() foreach @{$packages};
	}
}


INSIDE_SCOPE: {
	# Create a document with various example package statements
	my $Document = PPI::Document->new( \<<'END_PERL' );
package Foo;
SCOPE: {
	package # comment
	Bar::Baz;
	1;
}
1;
END_PERL
	isa_ok( $Document, 'PPI::Document' );

	# Check that both of the package statements are detected
	my $packages = $Document->find('Statement::Package');
	is( scalar(@$packages), 2, 'Found 2 package statements' );
	is( $packages->[0]->namespace, 'Foo', 'Package 1 returns correct namespace' );
	is( $packages->[1]->namespace, 'Bar::Baz', 'Package 2 returns correct namespace' );
	is( $packages->[0]->file_scoped, 1,  '->file_scoped returns true for package 1' );
	is( $packages->[1]->file_scoped, '', '->file_scoped returns false for package 2' );
}


PERL_5_12_SYNTAX: {
	for my $name (
		'Foo',
		'package',
	) {
		for my $version_pair (
			[ 'v1.2.3 ', 'PPI::Token::Number::Version' ],
			[ 'v1.2.3', 'PPI::Token::Number::Version' ],
			[ '0.50 ', 'PPI::Token::Number::Float' ],
			[ '0.50', 'PPI::Token::Number::Float' ],
			[ '', '' ],  # omit version
		) {
			my ( $version, $version_type ) = @$version_pair;
			my $version_stripped = $version;
			$version_stripped =~ s/^\s+//;
			$version_stripped =~ s/\s+$//;

			for my $block_pair (
				[ ';', 'PPI::Token::Structure' ],
				[ '{ 1 }', 'PPI::Structure::Block' ],
			) {
				my ( $block, $block_type ) = @$block_pair;
				my $block_stripped = $block;
				$block_stripped =~ s/^\s+//;
				$block_stripped =~ s/\s+$//;

				my $code = "package $name $version$block";

				my $Document = PPI::Document->new( \"$code 999;" );
				is( $Document->schildren(), 2, "$code number of statements in document" );
				isa_ok( $Document->schild(0), 'PPI::Statement::Package', $code );

				# first child is the package statement
				my $expected_package_tokens = [
					[ 'PPI::Token::Word', 'package' ],
					[ 'PPI::Token::Word', $name ],
					($version ne '') ? [ $version_type, $version_stripped ] : (),
					[ $block_type, $block_stripped ],
				];
				my $got_tokens = [ map { [ ref $_, "$_" ] } $Document->schild(0)->schildren() ];
				is_deeply( $got_tokens, $expected_package_tokens, "$code tokens as expected" );

				# second child not swallowed up by the first
				isa_ok( $Document->schild(1), 'PPI::Statement', "$code prior statement end recognized" );
				isa_ok( $Document->schild(1)->schild(0), 'PPI::Token::Number', $code );
				is(     $Document->schild(1)->schild(0), '999', "$code number correct"  );
			}
		}
	}
}
