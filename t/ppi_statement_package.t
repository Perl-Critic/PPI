#!/usr/bin/perl

# Unit testing for PPI::Statement::Package

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 2526 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use PPI::Singletons qw( %KEYWORDS );
use Helper 'safe_new';


HASH_CONSTRUCTORS_DONT_CONTAIN_PACKAGES_RT52259: {
	my $Document = safe_new \<<'END_PERL';
{    package  => "", };
+{   package  => "", };
{   'package' => "", };
+{  'package' => "", };
{   'package' ,  "", };
+{  'package' ,  "", };
END_PERL

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
	my $Document = safe_new \<<'END_PERL';
package Foo;
SCOPE: {
	package # comment
	Bar::Baz;
	1;
}
package Other v1.23;
package Again 0.09;
1;
END_PERL

	# Check that both of the package statements are detected
	my $packages = $Document->find('Statement::Package');
	is( scalar(@$packages), 4, 'Found 2 package statements' );
	is( $packages->[0]->namespace, 'Foo', 'Package 1 returns correct namespace' );
	is( $packages->[1]->namespace, 'Bar::Baz', 'Package 2 returns correct namespace' );
	is( $packages->[2]->namespace, 'Other', 'Package 3 returns correct namespace' );
	is( $packages->[3]->namespace, 'Again', 'Package 4 returns correct namespace' );
	is( $packages->[0]->file_scoped, 1,  '->file_scoped returns true for package 1' );
	is( $packages->[1]->file_scoped, '', '->file_scoped returns false for package 2' );
	is( $packages->[2]->file_scoped, 1, '->file_scoped returns true for package 3' );
	is( $packages->[3]->file_scoped, 1, '->file_scoped returns true for package 4' );
	is( $packages->[0]->version, '', 'Package 1 has no version' );
	is( $packages->[1]->version, '', 'Package 2 has no version' );
	is( $packages->[2]->version, 'v1.23', 'Package 3 returns correct version' );
	is( $packages->[3]->version, '0.09', 'Package 4 returns correct version' );
}

PERL_5_12_SYNTAX: {
	my @names = (
		# normal name
		'Foo',
		# Keywords must parse as Word and not influence lexing
		# of subsequent curly braces.
		keys %KEYWORDS,
		# regression: misparsed as version string
		'v10',
		# regression GitHub #122: 'x' parsed as x operator
		'x64',
		# Other weird and/or special words, just in case
		'__PACKAGE__',
		'__FILE__',
		'__LINE__',
		'__SUB__',
		'AUTOLOAD',
	);
	my @versions = (
		[ 'v1.2.3 ', 'PPI::Token::Number::Version' ],
		[ 'v1.2.3', 'PPI::Token::Number::Version' ],
		[ '0.50 ', 'PPI::Token::Number::Float' ],
		[ '0.50', 'PPI::Token::Number::Float' ],
		[ '', '' ],  # omit version, traditional
	);
	my @blocks = (
		[ ';', 'PPI::Token::Structure' ],  # traditional package syntax
		[ '{ 1 }', 'PPI::Structure::Block' ],  # 5.12 package syntax
	);
	$_->[2] = strip_ws_padding( $_->[0] ) for @versions, @blocks;

	for my $name ( @names ) {
		for my $version_pair ( @versions ) {
			for my $block_pair ( @blocks ) {
				my @test = prepare_package_test( $version_pair, $block_pair, $name );
				test_package_blocks( @test );
			}
		}
	}
}

MULTIPLE_BLOCK_FORM_PACKAGES_ISSUE_191: {
	my $Document = safe_new \<<'END_PERL';
package Foo;
package Bar { }
package Baz { }
print 'hello';
END_PERL

	my $packages = $Document->find('PPI::Statement::Package');
	is( scalar @$packages, 3, 'found 3 package statements' );
	is( $packages->[0]->namespace, 'Foo', 'first package is Foo' );
	is( $packages->[1]->namespace, 'Bar', 'second package is Bar' );
	is( $packages->[2]->namespace, 'Baz', 'third package is Baz' );

	my @stmts = $Document->schildren;
	is( scalar @stmts, 4, 'document has 4 statements' );
	isa_ok( $stmts[3], 'PPI::Statement', 'print is a separate statement' );
	is( eval { $stmts[3]->schild(0)->content }, 'print',
		'print statement not swallowed by package block' );
}

BLOCK_FORM_PACKAGE_COMPLETE: {
	my $doc_semi = safe_new \"package Foo;";
	my $pkg_semi = $doc_semi->find_first('PPI::Statement::Package');
	ok( $pkg_semi->_complete, 'semicolon-form package is _complete' );

	my $doc_block = safe_new \"package Foo { 1 }";
	my $pkg_block = $doc_block->find_first('PPI::Statement::Package');
	ok( $pkg_block->_complete, 'block-form package is _complete' );

	my $doc_ver = safe_new \"package Foo 1.0 { 1 }";
	my $pkg_ver = $doc_ver->find_first('PPI::Statement::Package');
	ok( $pkg_ver->_complete, 'block-form package with version is _complete' );
}

sub strip_ws_padding {
	my ( $string ) = @_;
	$string =~ s/(^\s+|\s+$)//g;
	return $string;
}

sub prepare_package_test {
	my ( $version_pair, $block_pair, $name ) = @_;

	my ( $version, $version_type, $version_stripped ) = @{$version_pair};
	my ( $block, $block_type, $block_stripped ) = @{$block_pair};

	my $code = "package $name $version$block";

	my $expected_package_tokens = [
		[ 'PPI::Token::Word', 'package' ],
		[ 'PPI::Token::Word', $name ],
		($version ne '') ? [ $version_type, $version_stripped ] : (),
		[ $block_type, $block_stripped ],
	];

	return ( $code, $expected_package_tokens );
}

sub test_package_blocks {
	my ( $code, $expected_package_tokens ) = @_;

	subtest "'$code'", sub {

	my $Document = safe_new \"$code 999;";
	is(     $Document->schildren, 2, "correct number of statements in document" );
	isa_ok( $Document->schild(0), 'PPI::Statement::Package', "entire code" );

	# first child is the package statement
	my $got_tokens = [ map { [ ref $_, "$_" ] } $Document->schild(0)->schildren ];
	is_deeply( $got_tokens, $expected_package_tokens, "tokens as expected" );

	# second child not swallowed up by the first
	isa_ok( $Document->schild(1), 'PPI::Statement', "code prior statement end recognized" );
	isa_ok( eval { $Document->schild(1)->schild(0) }, 'PPI::Token::Number', "inner code" );
	is(     eval { $Document->schild(1)->schild(0) }, '999', "number correct"  );

	};

	return;
}
