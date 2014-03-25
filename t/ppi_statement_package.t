#!/usr/bin/perl

# Unit testing for PPI::Statement::Package

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 2506 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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
package Other v1.23;
package Again 0.09;
1;
END_PERL
	isa_ok( $Document, 'PPI::Document' );

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

my %known_bad = map { ( "package $_" => 1 ) }
  'and 0.50 ;', 'and 0.50 { 1 }', 'and 0.50;', 'and 0.50{ 1 }', 'and ;', 'and v1.2.3 ;', 'and v1.2.3 { 1 }', 'and v1.2.3;', 'and v1.2.3{ 1 }', 'and { 1 }', 'bless { 1 }',
  'cmp 0.50 ;', 'cmp 0.50 { 1 }', 'cmp 0.50;', 'cmp 0.50{ 1 }', 'cmp ;', 'cmp v1.2.3 ;', 'cmp v1.2.3 { 1 }', 'cmp v1.2.3;', 'cmp v1.2.3{ 1 }', 'cmp { 1 }',
  'eq 0.50 ;', 'eq 0.50 { 1 }', 'eq 0.50;', 'eq 0.50{ 1 }', 'eq ;', 'eq v1.2.3 ;', 'eq v1.2.3 { 1 }', 'eq v1.2.3;', 'eq v1.2.3{ 1 }', 'eq { 1 }',
  'ge 0.50 ;', 'ge 0.50 { 1 }', 'ge 0.50;', 'ge 0.50{ 1 }', 'ge ;', 'ge v1.2.3 ;', 'ge v1.2.3 { 1 }', 'ge v1.2.3;', 'ge v1.2.3{ 1 }', 'ge { 1 }',
  'gt 0.50 ;', 'gt 0.50 { 1 }', 'gt 0.50;', 'gt 0.50{ 1 }', 'gt ;', 'gt v1.2.3 ;', 'gt v1.2.3 { 1 }', 'gt v1.2.3;', 'gt v1.2.3{ 1 }', 'gt { 1 }',
  'le 0.50 ;', 'le 0.50 { 1 }', 'le 0.50;', 'le 0.50{ 1 }', 'le ;', 'le v1.2.3 ;', 'le v1.2.3 { 1 }', 'le v1.2.3;', 'le v1.2.3{ 1 }', 'le { 1 }',
  'lt 0.50 ;', 'lt 0.50 { 1 }', 'lt 0.50;', 'lt 0.50{ 1 }', 'lt ;', 'lt v1.2.3 ;', 'lt v1.2.3 { 1 }', 'lt v1.2.3;', 'lt v1.2.3{ 1 }', 'lt { 1 }',
  'm 0.50 ;', 'm 0.50 { 1 }', 'm 0.50;', 'm 0.50{ 1 }', 'm ;', 'm v1.2.3 ;', 'm v1.2.3 { 1 }', 'm v1.2.3;', 'm v1.2.3{ 1 }', 'm { 1 }',
  'ne 0.50 ;', 'ne 0.50 { 1 }', 'ne 0.50;', 'ne 0.50{ 1 }', 'ne ;', 'ne v1.2.3 ;', 'ne v1.2.3 { 1 }', 'ne v1.2.3;', 'ne v1.2.3{ 1 }', 'ne { 1 }',
  'not 0.50 ;', 'not 0.50 { 1 }', 'not 0.50;', 'not 0.50{ 1 }', 'not ;', 'not v1.2.3 ;', 'not v1.2.3 { 1 }', 'not v1.2.3;', 'not v1.2.3{ 1 }', 'not { 1 }',
  'or 0.50 ;', 'or 0.50 { 1 }', 'or 0.50;', 'or 0.50{ 1 }', 'or ;', 'or v1.2.3 ;', 'or v1.2.3 { 1 }', 'or v1.2.3;', 'or v1.2.3{ 1 }', 'or { 1 }',
  'q 0.50 ;', 'q 0.50 { 1 }', 'q 0.50;', 'q 0.50{ 1 }', 'q ;', 'q v1.2.3 ;', 'q v1.2.3 { 1 }', 'q v1.2.3;', 'q v1.2.3{ 1 }', 'q { 1 }',
  'qq 0.50 ;', 'qq 0.50 { 1 }', 'qq 0.50;', 'qq 0.50{ 1 }', 'qq ;', 'qq v1.2.3 ;', 'qq v1.2.3 { 1 }', 'qq v1.2.3;', 'qq v1.2.3{ 1 }', 'qq { 1 }',
  'qr 0.50 ;', 'qr 0.50 { 1 }', 'qr 0.50;', 'qr 0.50{ 1 }', 'qr ;', 'qr v1.2.3 ;', 'qr v1.2.3 { 1 }', 'qr v1.2.3;', 'qr v1.2.3{ 1 }', 'qr { 1 }',
  'qw 0.50 ;', 'qw 0.50 { 1 }', 'qw 0.50;', 'qw 0.50{ 1 }', 'qw ;', 'qw v1.2.3 ;', 'qw v1.2.3 { 1 }', 'qw v1.2.3;', 'qw v1.2.3{ 1 }', 'qw { 1 }',
  'qx 0.50 ;', 'qx 0.50 { 1 }', 'qx 0.50;', 'qx 0.50{ 1 }', 'qx ;', 'qx v1.2.3 ;', 'qx v1.2.3 { 1 }', 'qx v1.2.3;', 'qx v1.2.3{ 1 }', 'qx { 1 }',
  'return { 1 }',
  's 0.50 ;', 's 0.50 { 1 }', 's 0.50;', 's 0.50{ 1 }', 's ;', 's v1.2.3 ;', 's v1.2.3 { 1 }', 's v1.2.3;', 's v1.2.3{ 1 }', 's { 1 }',
  'scalar { 1 }',
  'tr 0.50 ;', 'tr 0.50 { 1 }', 'tr 0.50;', 'tr 0.50{ 1 }', 'tr ;', 'tr v1.2.3 ;', 'tr v1.2.3 { 1 }', 'tr v1.2.3;', 'tr v1.2.3{ 1 }', 'tr { 1 }',
  'v10 0.50 ;', 'v10 0.50 { 1 }', 'v10 0.50;', 'v10 0.50{ 1 }', 'v10 ;', 'v10 v1.2.3 ;', 'v10 v1.2.3 { 1 }', 'v10 v1.2.3;', 'v10 v1.2.3{ 1 }', 'v10 { 1 }',
  'x 0.50 ;', 'x 0.50 { 1 }', 'x 0.50;', 'x 0.50{ 1 }', 'x ;', 'x v1.2.3 ;', 'x v1.2.3 { 1 }', 'x v1.2.3;', 'x v1.2.3{ 1 }', 'x { 1 }',
  'x64 0.50 ;', 'x64 0.50 { 1 }', 'x64 0.50;', 'x64 0.50{ 1 }', 'x64 ;', 'x64 v1.2.3 ;', 'x64 v1.2.3 { 1 }', 'x64 v1.2.3;', 'x64 v1.2.3{ 1 }', 'x64 { 1 }',
  'xor 0.50 ;', 'xor 0.50 { 1 }', 'xor 0.50;', 'xor 0.50{ 1 }', 'xor ;', 'xor v1.2.3 ;', 'xor v1.2.3 { 1 }', 'xor v1.2.3;', 'xor v1.2.3{ 1 }', 'xor { 1 }',
  'y 0.50 ;', 'y 0.50 { 1 }', 'y 0.50;', 'y 0.50{ 1 }', 'y ;', 'y v1.2.3 ;', 'y v1.2.3 { 1 }', 'y v1.2.3;', 'y v1.2.3{ 1 }', 'y { 1 }'
  ;

PERL_5_12_SYNTAX: {
	my @names = (
		# normal name
		'Foo',
		# Keywords must parse as Word and not influence lexing
		# of subsequent curly braces.
		keys %PPI::Token::Word::KEYWORDS,
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

TODO: {
	local $TODO = $known_bad{$code} ? "known bug" : undef;
	subtest "'$code'", sub {

	my $Document = PPI::Document->new( \"$code 999;" );
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
}
	return;
}
