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
use Test::More tests => 6;
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

PACKAGE_VERSION: {
	my $Document = PPI::Document->new(\'package Foo 1.0; sub baz { }');

	my $package = $Document->find_first('PPI::Statement::Package');
	my $sibling = $package && $package->snext_sibling;
	ok eval { $sibling->isa('PPI::Statement::Sub') }, 'Package statement with version ends at semicolon';
}

PACKAGE_BLOCK: {
	my $Document = PPI::Document->new(\'package Foo { sub bar { } } sub baz { }');

	my $package = $Document->find_first('PPI::Statement::Package');
	my $sibling = $package && $package->snext_sibling;
	ok eval { $sibling->isa('PPI::Statement::Sub') }, 'Block package statement ends at closing brace';
}

PACKAGE_VERSION_BLOCK: {
	my $Document = PPI::Document->new(\'package Foo 1.0 { sub bar { } } sub baz { }');

	my $package = $Document->find_first('PPI::Statement::Package');
	my $sibling = $package && $package->snext_sibling;
	ok eval { $sibling->isa('PPI::Statement::Sub') }, 'Block package with version statement ends at closing brace';
}
