#!/usr/bin/perl

# Unit testing for PPI::Token::Attribute

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 1788 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI;
use Test::Deep;

sub execute_test;
sub permute_test;

PARSING_AND_METHODS: {
	# no attribute
	execute_test 'sub foo {}', [];
	execute_test 'sub foo;', [];

	# perl allows there to be no attributes following the colon.
	execute_test 'sub foo:{}', [];
	execute_test 'sub foo : {}', [];

	# Attribute with no parameters
	permute_test 'foo',    [ [ 'Attr1', undef ] ];
	permute_test 'foo',    [ [ 'Attr1', undef ] ];
	permute_test 'foo',    [ [ 'Attr1', undef ] ];
	permute_test 'method', [ [ 'Attr1', undef ] ];
	permute_test 'lvalue', [ [ 'Attr1', undef ] ];
	permute_test 'foo',    [ [ '_', undef ] ];

	# Attribute with parameters
	permute_test 'foo', [ [ 'Attr1', '' ] ];
	permute_test 'foo', [ [ 'Attr1', ' ' ] ];
	permute_test 'foo', [ [ 'Attr1', ' () ' ] ];
	permute_test 'foo', [ [ 'Attr1', ' (()) ' ] ];
	permute_test 'foo', [ [ 'Attr1', ' \) ' ] ];
	permute_test 'foo', [ [ 'Attr1', ' \( ' ] ];
	permute_test 'foo', [ [ 'Attr1', '{' ] ];
	permute_test 'foo', [ [ '_', '' ] ];

	# Multiple attributes, separated by colon+whitespace
	permute_test 'foo', [ [ 'Attr1', undef ], [ 'Attr2', undef ] ];
	permute_test 'foo', [ [ 'Attr1', undef ], [ 'Attr2', undef ] ];
	permute_test 'foo', [ [ 'Attr1', undef ], [ 'Attr2', undef ] ];
	permute_test 'foo', [ [ 'Attr1', undef ], [ 'Attr2', undef ], [ 'Attr3', undef ] ];
	permute_test 'foo', [ [ 'Attr1', '' ],    [ 'Attr2', '' ],    [ 'Attr3', '' ] ];
	permute_test 'foo', [ [ 'Attr1', '' ],    [ 'Attr2', '___' ], [ 'Attr3', '' ] ];

	# Multiple attributes, separated by whitespace only
	permute_test 'foo', [ [ 'Attr1', undef ], [ 'Attr2', undef ] ];
	permute_test 'foo', [ [ 'Attr1', 'a' ],   [ 'Attr2', 'b' ] ];

	# Examples from perldoc attributes
	permute_test 'foo', [ [ 'switch', '10,foo(7,3)' ], [ 'expensive', undef ] ];
	permute_test 'foo', [ [ 'Ugly',   '\'\\("' ],      [ 'Bad', undef ] ];
	permute_test 'foo', [ [ '_5x5',   undef ] ];
	permute_test 'foo', [ [ 'lvalue', undef ],         [ 'method', undef ] ];

	# Mixed separators
	execute_test 'sub foo : Attr1(a) Attr2(b) : Attr3(c) Attr4(d) {}', [ [ 'Attr1', 'a' ], [ 'Attr2', 'b' ], [ 'Attr3', 'c' ], [ 'Attr4', 'd' ] ];

	# When PPI supports anonymous subs, we'll need tests for
	# attributes on them, too.
}

sub execute_test {
	my ( $code, $expected, $msg ) = @_;
	$msg = $code if !defined $msg;

	my $Document = PPI::Document->new( \$code );
	isa_ok( $Document, 'PPI::Document', "$msg got document" );

	my $attributes = $Document->find( 'PPI::Token::Attribute') || [];
	is( scalar(@$attributes), scalar(@$expected), "'$msg' got expected number of attributes" );
	is_deeply(
		[ map { [ $_->identifier, $_->parameters ] } @$attributes ],
		$expected,
		"'$msg' attribute properties as expected"
	);

	my $blocks = $Document->find( 'PPI::Structure::Block') || [];
	my $blocks_expected = $code =~ m/{}$/ ? [ '{}' ] : [];
	is_deeply(
		[ map { $_->content } @$blocks ],
		$blocks_expected,
		"$msg blocks found as expected"
	);

	return;
}

sub assemble_and_run {
	my ( $name, $post_colon, $separator, $attributes, $post_attributes, $block ) = @_;
	$block = '{}' if !defined $block;

	my $attribute_str = join $separator, map { defined $_->[1] ? "$_->[0]($_->[1])" : $_->[0] } @$attributes;
	my $code = "sub $name :$post_colon$attribute_str$post_attributes$block";

	my $msg = $code;
	$msg =~ s|\x{b}|\\v|g;
	$msg =~ s|\t|\\t|g;
	$msg =~ s|\r|\\r|g;
	$msg =~ s|\n|\\n|g;
	$msg =~ s|\f|\\f|g;

	execute_test $code, $attributes, $msg;

	return;
}

sub permute_test {
	my ( $name, $attributes ) = @_;

	# Vertical tab \x{b} is whitespace since perl 5.20, but PPI currently
	# (1.220) only supports it as whitespace when running on 5.20
	# or greater.

	assemble_and_run $name, '',  ':',   $attributes, '',  '{}';
	assemble_and_run $name, '',  ':',   $attributes, '',  ';';
	assemble_and_run $name, ' ', ' ',   $attributes, ' ', '{}';
	assemble_and_run $name, ' ', "\t",  $attributes, ' ', '{}';
	assemble_and_run $name, ' ', "\r",  $attributes, ' ', '{}';
	assemble_and_run $name, ' ', "\n",  $attributes, ' ', '{}';
	assemble_and_run $name, ' ', "\f",  $attributes, ' ', '{}';

	assemble_and_run $name, "\t", "\t", $attributes, "\t", '{}';
	assemble_and_run $name, "\t", "\t", $attributes, "\t", ';';
	assemble_and_run $name, "\r", "\r", $attributes, "\r", '{}';
	assemble_and_run $name, "\n", "\n", $attributes, "\n", '{}';
	assemble_and_run $name, "\f", "\f", $attributes, "\f", '{}';
	assemble_and_run $name, "\f", "\f", $attributes, "\f", ';';

	assemble_and_run $name, "\t", "\t:\t", $attributes, "\t", '{}';
	assemble_and_run $name, "\r", "\r:\r", $attributes, "\r", '{}';
	assemble_and_run $name, "\n", "\n:\n", $attributes, "\n", '{}';
	assemble_and_run $name, "\f", "\f:\f", $attributes, "\f", '{}';

	return;
}
