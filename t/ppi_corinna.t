#!/usr/bin/perl

# Test Corinna keyword support (class, method, field, ADJUST)
# https://github.com/Perl-Critic/PPI/issues/299

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 116 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';

my $preamble = 'use feature "class"; ';


# class is parsed as PPI::Statement::Package

CLASS_BASIC: {
	for my $test (
		{ code => 'class Foo { }',     ns => 'Foo' },
		{ code => 'class Foo::Bar { }', ns => 'Foo::Bar' },
		{ code => 'class Foo;',        ns => 'Foo' },
	) {
		my $code = $preamble . $test->{code};
		my $Document = safe_new \$code;

		my $classes = $Document->find('PPI::Statement::Package') || [];
		is( scalar @$classes, 1, "'$test->{code}': found one Package statement" );
		is( $classes->[0]->namespace, $test->{ns}, "'$test->{code}': namespace correct" );

		my $first_word = $classes->[0]->schild(0);
		is( $first_word->content, 'class', "'$test->{code}': first word is 'class'" );
	}
}


CLASS_WITH_ATTRIBUTES: {
	my $code = $preamble . 'class Foo :isa(Bar) { }';
	my $Document = safe_new \$code;

	my $classes = $Document->find('PPI::Statement::Package') || [];
	is( scalar @$classes, 1, "class :isa found one Package" );
	is( $classes->[0]->namespace, 'Foo', "class :isa namespace correct" );

	my $attrs = $classes->[0]->find('PPI::Token::Attribute') || [];
	is( scalar @$attrs, 1, "class :isa found one attribute" );
	is( $attrs->[0]->content, 'isa(Bar)', "class :isa attribute content correct" );
}


CLASS_BLOCK: {
	my $code = $preamble . 'class Foo { } 999;';
	my $Document = safe_new \$code;

	my @stmts = $Document->schildren;
	is( scalar @stmts, 3, "class block: correct number of statements" );
	isa_ok( $stmts[1], 'PPI::Statement::Package', "class block: first is Package" );
	isa_ok( $stmts[2], 'PPI::Statement', "class block: second is Statement" );

	my $block = $stmts[1]->find_first('PPI::Structure::Block');
	ok( $block, "class block: has a Block structure" );
}


# method is parsed as PPI::Statement::Sub

METHOD_BASIC: {
	for my $test (
		{ code => 'method foo { }',      name => 'foo' },
		{ code => 'method foo_bar { }',  name => 'foo_bar' },
		{ code => 'method FOO { }',      name => 'FOO' },
	) {
		my $code = $preamble . 'class C { ' . $test->{code} . ' }';
		my $Document = safe_new \$code;

		my $methods = $Document->find('PPI::Statement::Sub') || [];
		is( scalar @$methods, 1, "'$test->{code}': found one Sub statement" );
		is( $methods->[0]->name, $test->{name}, "'$test->{code}': name correct" );

		my $first_word = $methods->[0]->schild(0);
		is( $first_word->content, 'method', "'$test->{code}': first word is 'method'" );
	}
}


METHOD_WITH_SIGNATURE: {
	my $code = $preamble . 'class C { method greet ($name) { } }';
	my $Document = safe_new \$code;

	my $methods = $Document->find('PPI::Statement::Sub') || [];
	is( scalar @$methods, 1, "method with sig: found one Sub" );
	is( $methods->[0]->name, 'greet', "method with sig: name correct" );

	my $sig = $methods->[0]->find_first('PPI::Structure::Signature');
	ok( $sig, "method with sig: has a Signature structure" );
}


METHOD_BLOCK: {
	my $code = $preamble . 'class C { method foo { } method bar { } }';
	my $Document = safe_new \$code;

	my $methods = $Document->find('PPI::Statement::Sub') || [];
	is( scalar @$methods, 2, "multiple methods: found two Subs" );
	is( $methods->[0]->name, 'foo', "first method name" );
	is( $methods->[1]->name, 'bar', "second method name" );
}


METHOD_WITH_ATTRIBUTE: {
	my $code = $preamble . 'class C { method foo :lvalue { } }';
	my $Document = safe_new \$code;

	my $methods = $Document->find('PPI::Statement::Sub') || [];
	is( scalar @$methods, 1, "method with attr: found one Sub" );

	my $attrs = $methods->[0]->find('PPI::Token::Attribute') || [];
	is( scalar @$attrs, 1, "method with attr: found one attribute" );
	is( $attrs->[0]->content, 'lvalue', "method with attr: attribute content" );
}


# field is parsed as PPI::Statement::Variable

FIELD_BASIC: {
	for my $test (
		{ code => 'field $x;',         vars => ['$x'] },
		{ code => 'field $name;',      vars => ['$name'] },
		{ code => 'field @items;',     vars => ['@items'] },
		{ code => 'field %lookup;',    vars => ['%lookup'] },
	) {
		my $code = $preamble . 'class C { ' . $test->{code} . ' }';
		my $Document = safe_new \$code;

		my $fields = $Document->find('PPI::Statement::Variable') || [];
		is( scalar @$fields, 1, "'$test->{code}': found one Variable statement" );
		my @vars = $fields->[0]->variables;
		is_deeply( \@vars, $test->{vars}, "'$test->{code}': variables correct" );
	}
}


FIELD_WITH_DEFAULT: {
	my $code = $preamble . 'class C { field $x = 42; }';
	my $Document = safe_new \$code;

	my $fields = $Document->find('PPI::Statement::Variable') || [];
	is( scalar @$fields, 1, "field with default: found one Variable" );
	my @vars = $fields->[0]->variables;
	is_deeply( \@vars, ['$x'], "field with default: variable correct" );
}


FIELD_WITH_ATTRIBUTES: {
	my $code = $preamble . 'class C { field $x :param; }';
	my $Document = safe_new \$code;

	my $fields = $Document->find('PPI::Statement::Variable') || [];
	is( scalar @$fields, 1, "field :param: found one Variable" );

	my $attrs = $fields->[0]->find('PPI::Token::Attribute') || [];
	is( scalar @$attrs, 1, "field :param: found one attribute" );
	is( $attrs->[0]->content, 'param', "field :param: attribute content" );
}


FIELD_WITH_MULTIPLE_ATTRIBUTES: {
	my $code = $preamble . 'class C { field $x :param :reader = 42; }';
	my $Document = safe_new \$code;

	my $fields = $Document->find('PPI::Statement::Variable') || [];
	is( scalar @$fields, 1, "field multi-attr: found one Variable" );

	my $attrs = $fields->[0]->find('PPI::Token::Attribute') || [];
	is( scalar @$attrs, 2, "field multi-attr: found two attributes" );
	is( $attrs->[0]->content, 'param', "field multi-attr: first attribute" );
	is( $attrs->[1]->content, 'reader', "field multi-attr: second attribute" );
}


# ADJUST is parsed as PPI::Statement::Scheduled

ADJUST_BASIC: {
	my $code = $preamble . 'class C { ADJUST { 1; } }';
	my $Document = safe_new \$code;

	my $scheduled = $Document->find('PPI::Statement::Scheduled') || [];
	is( scalar @$scheduled, 1, "ADJUST: found one Scheduled" );
	is( $scheduled->[0]->schild(0)->content, 'ADJUST', "ADJUST: word is ADJUST" );

	my $block = $scheduled->[0]->block;
	ok( $block, "ADJUST: has a block" );
}


# Without 'use feature "class"', keywords are not recognized

NO_FEATURE_CLASS: {
	my $code = 'class("foo");';
	my $Document = safe_new \$code;

	my $pkgs = $Document->find('PPI::Statement::Package');
	ok( !$pkgs, "class() without feature: not a Package" );
}


NO_FEATURE_METHOD: {
	my $code = 'method("foo");';
	my $Document = safe_new \$code;

	my $subs = $Document->find('PPI::Statement::Sub');
	ok( !$subs, "method() without feature: not a Sub" );
}


NO_FEATURE_FIELD: {
	my $code = 'field("foo");';
	my $Document = safe_new \$code;

	my $vars = $Document->find('PPI::Statement::Variable');
	ok( !$vars, "field() without feature: not a Variable" );
}


# class => in hash should not become Package even with feature

CLASS_FAT_COMMA: {
	my $code = $preamble . 'my %h = (class => "Foo");';
	my $Document = safe_new \$code;

	my $pkgs = $Document->find('PPI::Statement::Package');
	ok( !$pkgs, "class => with feature: not a Package" );
}


# Round-trip safety: parse + serialize = identical

ROUND_TRIP: {
	my $source = <<'END_PERL';
use feature "class";
class Foo :isa(Bar) {
    field $x :param = 42;
    field $y :reader;
    method greet ($name) {
        say "Hello, $name!";
    }
    ADJUST {
        $x //= "default";
    }
}
END_PERL

	my $Document = safe_new \$source;
	my $output = $Document->serialize;
	is( $output, $source, "round-trip: parse + serialize is identical" );
}


# Full Corinna class structure

FULL_CLASS: {
	my $source = $preamble . <<'END_PERL';
class Dog :isa(Animal) {
    field $name :param :reader;
    field $age :param = 0;
    method speak () { return "Woof!"; }
    ADJUST { $age = int($age); }
}
END_PERL

	my $Document = safe_new \$source;

	my $pkgs = $Document->find('PPI::Statement::Package') || [];
	is( scalar @$pkgs, 1, "full class: found one Package" );
	is( $pkgs->[0]->namespace, 'Dog', "full class: namespace" );

	my $subs = $Document->find( sub {
		$_[1]->isa('PPI::Statement::Sub')
		and not $_[1]->isa('PPI::Statement::Scheduled')
	} ) || [];
	is( scalar @$subs, 1, "full class: found one Sub (non-Scheduled)" );
	is( $subs->[0]->name, 'speak', "full class: method name" );

	my $vars = $Document->find('PPI::Statement::Variable') || [];
	is( scalar @$vars, 2, "full class: found two Variables" );

	my $scheduled = $Document->find('PPI::Statement::Scheduled') || [];
	is( scalar @$scheduled, 1, "full class: found one Scheduled" );
}
