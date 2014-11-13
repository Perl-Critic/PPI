#!/usr/bin/perl

# Test PPI::Statement::Sub

use t::lib::PPI::Test::pragmas;
use Test::More tests => 1209;

use PPI;

NAME: {
	for my $test (
		{ code => 'sub   foo   {}', name => 'foo' },
		{ code => 'sub foo{}',  name => 'foo' },
		{ code => 'sub FOO {}', name => 'FOO' },
		{ code => 'sub _foo {}', name => '_foo' },
		{ code => 'sub _0foo {}', name => '_0foo' },
		{ code => 'sub _foo0 {}', name => '_foo0' },
		{ code => 'sub ___ {}', name => '___' },
		{ code => 'sub bar() {}', name => 'bar' },
		{ code => 'sub baz : method{}', name => 'baz' },
		{ code => 'sub baz : method lvalue{}', name => 'baz' },
		{ code => 'sub baz : method:lvalue{}', name => 'baz' },
		{ code => 'sub baz (*) : method : lvalue{}', name => 'baz' },
		{ code => 'sub x64 {}',  name => 'x64' },  # should not be parsed as x operator
	) {
		my $code = $test->{code};
		my $name = $test->{name};

TODO:   {
		local $TODO = $code eq 'sub x64 {}' ? "known bug" : undef;
		subtest "'$code'", => sub {

		my $Document = PPI::Document->new( \$code );
		isa_ok( $Document, 'PPI::Document', "code" );

		my ( $sub_statement, $dummy ) = $Document->schildren;
		isa_ok( $sub_statement, 'PPI::Statement::Sub', "document child" );
		is( $dummy, undef, "document has exactly one child" );

		is( eval { $sub_statement->name }, $name, "name() correct" );

		};
}

	}
}

SUB_WORD_OPTIONAL: {
	# 'sub' is optional for these special subs. Make sure they're
	# recognized as subs and sub declarations.
	for my $name ( qw( AUTOLOAD DESTROY ) ) {
		for my $sub ( '', 'sub ' ) {

			# '{}' -- function definition
			# ';' -- function declaration
			# '' -- function declaration with missing semicolon
			for my $followed_by ( ' {}', '{}', ';', '' ) {
				test_sub_as( $sub, $name, $followed_by );
			}
		}
	}

	# Through 1.218, the PPI statement AUTOLOAD and DESTROY would
	# gobble up everything after them until it hit an explicit
	# statement terminator. Make sure statements following them are
	# not gobbled.
	my $desc = 'regression: word+block not gobbling to statement terminator';
	for my $word ( qw( AUTOLOAD DESTROY ) ) {
		my $Document = PPI::Document->new( \"$word {} sub foo {}" );
		my $statements = $Document->find('Statement::Sub') || [];
		is( scalar(@$statements), 2, "$desc for $word + sub" );
	
		$Document = PPI::Document->new( \"$word {} package;" );
		$statements = $Document->find('Statement::Sub') || [];
		is( scalar(@$statements), 1, "$desc for $word + package" );
		$statements = $Document->find('Statement::Package') || [];
		is( scalar(@$statements), 1, "$desc for $word + package" );
	}
}

PROTOTYPE: {
	# Doesn't have to be as thorough as ppi_token_prototype.t, since
	# we're just making sure PPI::Token::Prototype->prototype gets
	# passed through correctly.
	for my $test (
		[ '',         undef ],
		[ '()',       '' ],
		[ '( $*Z@ )', '$*Z@' ],
	) {
		my ( $proto_text, $expected ) = @$test;

		my $Document = PPI::Document->new( \"sub foo $proto_text {}" );
		isa_ok( $Document, 'PPI::Document', "$proto_text got document" );

		my ( $sub_statement, $dummy ) = $Document->schildren();
		isa_ok( $sub_statement, 'PPI::Statement::Sub', "$proto_text document child is a sub" );
		is( $dummy, undef, "$proto_text document has exactly one child" );
		is( $sub_statement->prototype, $expected, "$proto_text: prototype matches" );
	}
}

BLOCK_AND_FORWARD: {
	for my $test (
		{ code => 'sub foo {1;}', block => '{1;}' },
		{ code => 'sub foo{2;};', block => '{2;}' },
		{ code => "sub foo\n{3;};", block => '{3;}' },
		{ code => 'sub foo;', block => '' },
		{ code => 'sub foo', block => '' },
	) {
		my $code = $test->{code};
		my $block = $test->{block};

		my $Document = PPI::Document->new( \$code );
		isa_ok( $Document, 'PPI::Document', "$code: got document" );

		my ( $sub_statement, $dummy ) = $Document->schildren();
		isa_ok( $sub_statement, 'PPI::Statement::Sub', "$code: document child is a sub" );
		is( $dummy, undef, "$code: document has exactly one child" );
		is( $sub_statement->block, $block, "$code: block matches" );

		is( !$sub_statement->block, !!$sub_statement->forward, "$code: block and forward are opposites" );
	}
}

RESERVED: {
	for my $test (
		{ code => 'sub BEGIN {}', reserved => 1 },
		{ code => 'sub CHECK {}', reserved => 1 },
		{ code => 'sub UNITCHECK {}', reserved => 1 },
		{ code => 'sub INIT {}', reserved => 1 },
		{ code => 'sub END {}', reserved => 1 },
		{ code => 'sub AUTOLOAD {}', reserved => 1 },
		{ code => 'sub CLONE_SKIP {}', reserved => 1 },
		{ code => 'sub __SUB__ {}', reserved => 1 },
		{ code => 'sub _FOO {}', reserved => 1 },
		{ code => 'sub FOO9 {}', reserved => 1 },
		{ code => 'sub FO9O {}', reserved => 1 },
		{ code => 'sub FOo {}', reserved => 0 },
	) {
		my $code = $test->{code};
		my $reserved = $test->{reserved};

		my $Document = PPI::Document->new( \$code );
		isa_ok( $Document, 'PPI::Document', "$code: got document" );

		my ( $sub_statement, $dummy ) = $Document->schildren();
		isa_ok( $sub_statement, 'PPI::Statement::Sub', "$code: document child is a sub" );
		is( $dummy, undef, "$code: document has exactly one child" );
		is( !!$sub_statement->reserved, !!$reserved, "$code: reserved matches" );
	}
}

sub test_sub_as {
	my ( $sub, $name, $followed_by ) = @_;

	my $code     = "$sub$name$followed_by";
	my $Document = PPI::Document->new( \$code );
	isa_ok( $Document, 'PPI::Document', "$code: got document" );

	my ( $sub_statement, $dummy ) = $Document->schildren;
	isa_ok( $sub_statement, 'PPI::Statement::Sub', "$code: document child is a sub" );
	isnt( ref $sub_statement, 'PPI::Statement::Scheduled', "$code: not a PPI::Statement::Scheduled" );
	is( $dummy, undef, "$code: document has exactly one child" );
	ok( $sub_statement->reserved, "$code: is reserved" );
	is( $sub_statement->name, $name, "$code: name() correct" );

	if ( $followed_by =~ /}/ ) {
		isa_ok( $sub_statement->block, 'PPI::Structure::Block', "$code: has a block" );
	}
	else {
		ok( !$sub_statement->block, "$code: has no block" );
	}

	return;
}

my %known_bad = map { ( "sub $_" => 1 ) } 'v10 ;', 'v10  ;', 'v10 { 1 }', 'v10  { 1 }', 'scalar { 1 }', 'scalar  { 1 }', 'bless { 1 }', 'bless  { 1 }', 'return { 1 }', 'return  { 1 }';

KEYWORDS_AS_SUB_NAMES: {
	my @names = (
		# normal name
		'foo',
		# Keywords must parse as Word and not influence lexing
		# of subsequent curly braces.
		keys %PPI::Token::Word::KEYWORDS,
		# regression: misparsed as version string
		'v10',
		# Other weird and/or special words, just in case
		'__PACKAGE__',
		'__FILE__',
		'__LINE__',
		'__SUB__',
		'AUTOLOAD',
	);
	my @blocks = (
		[ ';', 'PPI::Token::Structure' ],
		[ ' ;', 'PPI::Token::Structure' ],
		[ '{ 1 }', 'PPI::Structure::Block' ],
		[ ' { 1 }', 'PPI::Structure::Block' ],
	);
	$_->[2] = strip_ws_padding( $_->[0] ) for @blocks;

	for my $name ( @names ) {
		for my $block_pair ( @blocks ) {
			my @test = prepare_sub_test( $block_pair, $name );
			test_subs( @test );
		}
	}
}

sub strip_ws_padding {
	my ( $string ) = @_;
	$string =~ s/(^\s+|\s+$)//g;
	return $string;
}

sub prepare_sub_test {
	my ( $block_pair, $name ) = @_;

	my ( $block, $block_type, $block_stripped ) = @{$block_pair};

	my $code = "sub $name $block";

	my $expected_sub_tokens = [
		[ 'PPI::Token::Word', 'sub' ],
		[ 'PPI::Token::Word', $name ],
		[ $block_type, $block_stripped ],
	];

	return ( $code, $expected_sub_tokens );
}

sub test_subs {
	my ( $code, $expected_sub_tokens ) = @_;

TODO:   {
	local $TODO = $known_bad{$code} ? "known bug" : undef;
	subtest "'$code'", => sub {

	my $Document = PPI::Document->new( \"$code 999;" );
	is(     $Document->schildren, 2, "number of statements in document" );
	isa_ok( $Document->schild(0), 'PPI::Statement::Sub', "entire code" );

	my $got_tokens = [ map { [ ref $_, "$_" ] } $Document->schild(0)->schildren ];
	is_deeply( $got_tokens, $expected_sub_tokens, "$code tokens as expected" );

	# second child not swallowed up by the first
	isa_ok( $Document->schild(1), 'PPI::Statement', "prior statement end recognized" );
	isa_ok( eval { $Document->schild(1)->schild(0) }, 'PPI::Token::Number', "inner code" );
	is(     eval { $Document->schild(1)->schild(0) }, '999', "number correct"  );

	};
}

	return;
}
