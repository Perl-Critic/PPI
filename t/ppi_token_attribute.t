#!/usr/bin/perl

# Unit testing for PPI::Token::Attribute

use t::lib::PPI::Test::pragmas;
use Test::More tests => 1789;

use PPI;
use Test::Deep;

sub execute_test;
sub permute_test;

my %known_fails_sblock = map { $_ => 1 } 'sub foo:{}', 'sub foo : {}';
my %known_fails_nprop = map { $_ => 1 } "sub foo : Attr1 Attr2 {}", "sub foo : Attr1\tAttr2 {}", "sub foo : Attr1\rAttr2 {}", "sub foo : Attr1\nAttr2 {}", "sub foo : Attr1\fAttr2 {}", "sub foo :\tAttr1\tAttr2\t{}", "sub foo :\tAttr1\tAttr2\t;", "sub foo :\rAttr1\rAttr2\r{}", "sub foo :\nAttr1\nAttr2\n{}", "sub foo :\fAttr1\fAttr2\f{}", "sub foo :\fAttr1\fAttr2\f;", "sub foo : Attr1 Attr2 {}", "sub foo : Attr1\tAttr2 {}", "sub foo : Attr1\rAttr2 {}", "sub foo : Attr1\nAttr2 {}", "sub foo : Attr1\fAttr2 {}", "sub foo :\tAttr1\tAttr2\t{}", "sub foo :\tAttr1\tAttr2\t;", "sub foo :\rAttr1\rAttr2\r{}", "sub foo :\nAttr1\nAttr2\n{}", "sub foo :\fAttr1\fAttr2\f{}", "sub foo :\fAttr1\fAttr2\f;", "sub foo : Attr1 Attr2 {}", "sub foo : Attr1\tAttr2 {}", "sub foo : Attr1\rAttr2 {}", "sub foo : Attr1\nAttr2 {}", "sub foo : Attr1\fAttr2 {}", "sub foo :\tAttr1\tAttr2\t{}", "sub foo :\tAttr1\tAttr2\t;", "sub foo :\rAttr1\rAttr2\r{}", "sub foo :\nAttr1\nAttr2\n{}", "sub foo :\fAttr1\fAttr2\f{}", "sub foo :\fAttr1\fAttr2\f;", "sub foo : Attr1 Attr2 Attr3 {}", "sub foo : Attr1\tAttr2\tAttr3 {}", "sub foo : Attr1\rAttr2\rAttr3 {}", "sub foo : Attr1\nAttr2\nAttr3 {}", "sub foo : Attr1\fAttr2\fAttr3 {}", "sub foo :\tAttr1\tAttr2\tAttr3\t{}", "sub foo :\tAttr1\tAttr2\tAttr3\t;", "sub foo :\rAttr1\rAttr2\rAttr3\r{}", "sub foo :\nAttr1\nAttr2\nAttr3\n{}", "sub foo :\fAttr1\fAttr2\fAttr3\f{}", "sub foo :\fAttr1\fAttr2\fAttr3\f;", "sub foo : Attr1() Attr2() Attr3() {}", "sub foo : Attr1()\tAttr2()\tAttr3() {}", "sub foo : Attr1()\rAttr2()\rAttr3() {}", "sub foo : Attr1()\nAttr2()\nAttr3() {}", "sub foo : Attr1()\fAttr2()\fAttr3() {}", "sub foo :\tAttr1()\tAttr2()\tAttr3()\t{}", "sub foo :\tAttr1()\tAttr2()\tAttr3()\t;", "sub foo :\rAttr1()\rAttr2()\rAttr3()\r{}", "sub foo :\nAttr1()\nAttr2()\nAttr3()\n{}", "sub foo :\fAttr1()\fAttr2()\fAttr3()\f{}", "sub foo :\fAttr1()\fAttr2()\fAttr3()\f;", "sub foo : Attr1() Attr2(___) Attr3() {}", "sub foo : Attr1()\tAttr2(___)\tAttr3() {}", "sub foo : Attr1()\rAttr2(___)\rAttr3() {}", "sub foo : Attr1()\nAttr2(___)\nAttr3() {}", "sub foo : Attr1()\fAttr2(___)\fAttr3() {}", "sub foo :\tAttr1()\tAttr2(___)\tAttr3()\t{}", "sub foo :\tAttr1()\tAttr2(___)\tAttr3()\t;", "sub foo :\rAttr1()\rAttr2(___)\rAttr3()\r{}", "sub foo :\nAttr1()\nAttr2(___)\nAttr3()\n{}", "sub foo :\fAttr1()\fAttr2(___)\fAttr3()\f{}", "sub foo :\fAttr1()\fAttr2(___)\fAttr3()\f;", "sub foo : Attr1 Attr2 {}", "sub foo : Attr1\tAttr2 {}", "sub foo : Attr1\rAttr2 {}", "sub foo : Attr1\nAttr2 {}", "sub foo : Attr1\fAttr2 {}", "sub foo :\tAttr1\tAttr2\t{}", "sub foo :\tAttr1\tAttr2\t;", "sub foo :\rAttr1\rAttr2\r{}", "sub foo :\nAttr1\nAttr2\n{}", "sub foo :\fAttr1\fAttr2\f{}", "sub foo :\fAttr1\fAttr2\f;", "sub foo : Attr1(a) Attr2(b) {}", "sub foo : Attr1(a)\tAttr2(b) {}", "sub foo : Attr1(a)\rAttr2(b) {}", "sub foo : Attr1(a)\nAttr2(b) {}", "sub foo : Attr1(a)\fAttr2(b) {}", "sub foo :\tAttr1(a)\tAttr2(b)\t{}", "sub foo :\tAttr1(a)\tAttr2(b)\t;", "sub foo :\rAttr1(a)\rAttr2(b)\r{}", "sub foo :\nAttr1(a)\nAttr2(b)\n{}", "sub foo :\fAttr1(a)\fAttr2(b)\f{}", "sub foo :\fAttr1(a)\fAttr2(b)\f;", "sub foo : switch(10,foo(7,3)) expensive {}", "sub foo : switch(10,foo(7,3))\texpensive {}", "sub foo : switch(10,foo(7,3))\rexpensive {}", "sub foo : switch(10,foo(7,3))\nexpensive {}", "sub foo : switch(10,foo(7,3))\fexpensive {}", "sub foo :\tswitch(10,foo(7,3))\texpensive\t{}", "sub foo :\tswitch(10,foo(7,3))\texpensive\t;", "sub foo :\rswitch(10,foo(7,3))\rexpensive\r{}", "sub foo :\nswitch(10,foo(7,3))\nexpensive\n{}", "sub foo :\fswitch(10,foo(7,3))\fexpensive\f{}", "sub foo :\fswitch(10,foo(7,3))\fexpensive\f;", "sub foo : Ugly('\\(\") Bad {}", "sub foo : Ugly('\\(\")\tBad {}", "sub foo : Ugly('\\(\")\rBad {}", "sub foo : Ugly('\\(\")\nBad {}", "sub foo : Ugly('\\(\")\fBad {}", "sub foo :\tUgly('\\(\")\tBad\t{}", "sub foo :\tUgly('\\(\")\tBad\t;", "sub foo :\rUgly('\\(\")\rBad\r{}", "sub foo :\nUgly('\\(\")\nBad\n{}", "sub foo :\fUgly('\\(\")\fBad\f{}", "sub foo :\fUgly('\\(\")\fBad\f;", "sub foo : lvalue method {}", "sub foo : lvalue\tmethod {}", "sub foo : lvalue\rmethod {}", "sub foo : lvalue\nmethod {}", "sub foo : lvalue\fmethod {}", "sub foo :\tlvalue\tmethod\t{}", "sub foo :\tlvalue\tmethod\t;", "sub foo :\rlvalue\rmethod\r{}", "sub foo :\nlvalue\nmethod\n{}", "sub foo :\flvalue\fmethod\f{}", "sub foo :\flvalue\fmethod\f;", "sub foo : Attr1(a) Attr2(b) : Attr3(c) Attr4(d) {}";
my %known_fails_aprop = map { $_ => 1 } 'sub foo :Attr1(){}', 'sub foo :Attr1();', 'sub foo : Attr1() {}',  "sub foo :\tAttr1()\t{}", "sub foo :\tAttr1()\t;", "sub foo :\rAttr1()\r{}", "sub foo :\nAttr1()\n{}", "sub foo :\fAttr1()\f{}", "sub foo :\fAttr1()\f;", "sub foo :\fAttr1()\f{}", "sub foo :_(){}", "sub foo :_();", "sub foo : _() {}", "sub foo : _() {}", "sub foo : _() {}", "sub foo : _() {}", "sub foo : _() {}", "sub foo :\t_()\t{}", "sub foo :\t_()\t;", "sub foo :\r_()\r{}", "sub foo :\n_()\n{}", "sub foo :\f_()\f{}", "sub foo :\f_()\f;", "sub foo :\t_()\t{}", "sub foo :\r_()\r{}", "sub foo :\n_()\n{}", "sub foo :\f_()\f{}", "sub foo : Attr1 Attr2 {}", "sub foo : Attr1\tAttr2 {}", "sub foo : Attr1\rAttr2 {}", "sub foo : Attr1\nAttr2 {}", "sub foo : Attr1\fAttr2 {}", "sub foo :\tAttr1\tAttr2\t{}", "sub foo :\tAttr1\tAttr2\t;", "sub foo :\rAttr1\rAttr2\r{}", "sub foo :\nAttr1\nAttr2\n{}", "sub foo :\fAttr1\fAttr2\f{}", "sub foo :\fAttr1\fAttr2\f;", "sub foo : Attr1 Attr2 {}", "sub foo : Attr1\tAttr2 {}", "sub foo : Attr1\rAttr2 {}", "sub foo : Attr1\nAttr2 {}", "sub foo : Attr1\fAttr2 {}", "sub foo :\tAttr1\tAttr2\t{}", "sub foo :\tAttr1\tAttr2\t;", "sub foo :\rAttr1\rAttr2\r{}", "sub foo :\nAttr1\nAttr2\n{}", "sub foo :\fAttr1\fAttr2\f{}", "sub foo :\fAttr1\fAttr2\f;", "sub foo : Attr1 Attr2 {}", "sub foo : Attr1\tAttr2 {}", "sub foo : Attr1\rAttr2 {}", "sub foo : Attr1\nAttr2 {}", "sub foo : Attr1\fAttr2 {}", "sub foo :\tAttr1\tAttr2\t{}", "sub foo :\tAttr1\tAttr2\t;", "sub foo :\rAttr1\rAttr2\r{}", "sub foo :\nAttr1\nAttr2\n{}", "sub foo :\fAttr1\fAttr2\f{}", "sub foo :\fAttr1\fAttr2\f;", "sub foo : Attr1 Attr2 Attr3 {}", "sub foo : Attr1\tAttr2\tAttr3 {}", "sub foo : Attr1\rAttr2\rAttr3 {}", "sub foo : Attr1\nAttr2\nAttr3 {}", "sub foo : Attr1\fAttr2\fAttr3 {}", "sub foo :\tAttr1\tAttr2\tAttr3\t{}", "sub foo :\tAttr1\tAttr2\tAttr3\t;", "sub foo :\rAttr1\rAttr2\rAttr3\r{}", "sub foo :\nAttr1\nAttr2\nAttr3\n{}", "sub foo :\fAttr1\fAttr2\fAttr3\f{}", "sub foo :\fAttr1\fAttr2\fAttr3\f;", "sub foo :Attr1():Attr2():Attr3(){}", "sub foo :Attr1():Attr2():Attr3();", "sub foo : Attr1() Attr2() Attr3() {}", "sub foo : Attr1()\tAttr2()\tAttr3() {}", "sub foo : Attr1()\rAttr2()\rAttr3() {}", "sub foo : Attr1()\nAttr2()\nAttr3() {}", "sub foo : Attr1()\fAttr2()\fAttr3() {}", "sub foo :\tAttr1()\tAttr2()\tAttr3()\t{}", "sub foo :\tAttr1()\tAttr2()\tAttr3()\t;", "sub foo :\rAttr1()\rAttr2()\rAttr3()\r{}", "sub foo :\nAttr1()\nAttr2()\nAttr3()\n{}", "sub foo :\fAttr1()\fAttr2()\fAttr3()\f{}", "sub foo :\fAttr1()\fAttr2()\fAttr3()\f;", "sub foo :\tAttr1()\t:\tAttr2()\t:\tAttr3()\t{}", "sub foo :\rAttr1()\r:\rAttr2()\r:\rAttr3()\r{}", "sub foo :\nAttr1()\n:\nAttr2()\n:\nAttr3()\n{}", "sub foo :\fAttr1()\f:\fAttr2()\f:\fAttr3()\f{}", "sub foo :Attr1():Attr2(___):Attr3(){}", "sub foo :Attr1():Attr2(___):Attr3();", "sub foo : Attr1() Attr2(___) Attr3() {}", "sub foo : Attr1()\tAttr2(___)\tAttr3() {}", "sub foo : Attr1()\rAttr2(___)\rAttr3() {}", "sub foo : Attr1()\nAttr2(___)\nAttr3() {}", "sub foo : Attr1()\fAttr2(___)\fAttr3() {}", "sub foo :\tAttr1()\tAttr2(___)\tAttr3()\t{}", "sub foo :\tAttr1()\tAttr2(___)\tAttr3()\t;", "sub foo :\rAttr1()\rAttr2(___)\rAttr3()\r{}", "sub foo :\nAttr1()\nAttr2(___)\nAttr3()\n{}", "sub foo :\fAttr1()\fAttr2(___)\fAttr3()\f{}", "sub foo :\fAttr1()\fAttr2(___)\fAttr3()\f;", "sub foo :\tAttr1()\t:\tAttr2(___)\t:\tAttr3()\t{}", "sub foo :\rAttr1()\r:\rAttr2(___)\r:\rAttr3()\r{}", "sub foo :\nAttr1()\n:\nAttr2(___)\n:\nAttr3()\n{}", "sub foo :\fAttr1()\f:\fAttr2(___)\f:\fAttr3()\f{}", "sub foo : Attr1 Attr2 {}", "sub foo : Attr1\tAttr2 {}", "sub foo : Attr1\rAttr2 {}", "sub foo : Attr1\nAttr2 {}", "sub foo : Attr1\fAttr2 {}", "sub foo :\tAttr1\tAttr2\t{}", "sub foo :\tAttr1\tAttr2\t;", "sub foo :\rAttr1\rAttr2\r{}", "sub foo :\nAttr1\nAttr2\n{}", "sub foo :\fAttr1\fAttr2\f{}", "sub foo :\fAttr1\fAttr2\f;", "sub foo : Attr1(a) Attr2(b) {}", "sub foo : Attr1(a)\tAttr2(b) {}", "sub foo : Attr1(a)\rAttr2(b) {}", "sub foo : Attr1(a)\nAttr2(b) {}", "sub foo : Attr1(a)\fAttr2(b) {}", "sub foo :\tAttr1(a)\tAttr2(b)\t{}", "sub foo :\tAttr1(a)\tAttr2(b)\t;", "sub foo :\rAttr1(a)\rAttr2(b)\r{}", "sub foo :\nAttr1(a)\nAttr2(b)\n{}", "sub foo :\fAttr1(a)\fAttr2(b)\f{}", "sub foo :\fAttr1(a)\fAttr2(b)\f;", "sub foo : switch(10,foo(7,3)) expensive {}", "sub foo : switch(10,foo(7,3))\texpensive {}", "sub foo : switch(10,foo(7,3))\rexpensive {}", "sub foo : switch(10,foo(7,3))\nexpensive {}", "sub foo : switch(10,foo(7,3))\fexpensive {}", "sub foo :\tswitch(10,foo(7,3))\texpensive\t{}", "sub foo :\tswitch(10,foo(7,3))\texpensive\t;", "sub foo :\rswitch(10,foo(7,3))\rexpensive\r{}", "sub foo :\nswitch(10,foo(7,3))\nexpensive\n{}", "sub foo :\fswitch(10,foo(7,3))\fexpensive\f{}", "sub foo :\fswitch(10,foo(7,3))\fexpensive\f;", "sub foo : Ugly('\\(\") Bad {}", "sub foo : Ugly('\\(\")\tBad {}", "sub foo : Ugly('\\(\")\rBad {}", "sub foo : Ugly('\\(\")\nBad {}", "sub foo : Ugly('\\(\")\fBad {}", "sub foo :\tUgly('\\(\")\tBad\t{}", "sub foo :\tUgly('\\(\")\tBad\t;", "sub foo :\rUgly('\\(\")\rBad\r{}", "sub foo :\nUgly('\\(\")\nBad\n{}", "sub foo :\fUgly('\\(\")\fBad\f{}", "sub foo :\fUgly('\\(\")\fBad\f;", "sub foo : lvalue method {}", "sub foo : lvalue\tmethod {}", "sub foo : lvalue\rmethod {}", "sub foo : lvalue\nmethod {}", "sub foo : lvalue\fmethod {}", "sub foo :\tlvalue\tmethod\t{}", "sub foo :\tlvalue\tmethod\t;", "sub foo :\rlvalue\rmethod\r{}", "sub foo :\nlvalue\nmethod\n{}", "sub foo :\flvalue\fmethod\f{}", "sub foo :\flvalue\fmethod\f;", "sub foo : Attr1(a) Attr2(b) : Attr3(c) Attr4(d) {}";

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
	{
	local $TODO = "known bug" if $known_fails_nprop{$code};
	is( scalar(@$attributes), scalar(@$expected), "'$msg' got expected number of attributes" );
	}
	{
	local $TODO = "known bug" if $known_fails_aprop{$code};
	is_deeply(
		[ map { [ $_->identifier, $_->parameters ] } @$attributes ],
		$expected,
		"'$msg' attribute properties as expected"
	);
	}

	my $blocks = $Document->find( 'PPI::Structure::Block') || [];
	my $blocks_expected = $code =~ m/{}$/ ? [ '{}' ] : [];
	local $TODO = "known bug" if $known_fails_sblock{$code};
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
