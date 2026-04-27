#!/usr/bin/perl

# Unit testing for PPI::Token::Word classification methods

use lib 't/lib';
use PPI::Test::pragmas;
use Helper 'safe_new';

use PPI ();
use Test::More tests => 49 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

HASH_KEY: {
	my $doc = safe_new \<<'END_PERL';
$hash{hash_subscript_key};
%hash = (fat_comma_key => 1);
func_not_key();
bare_word;
$hash{func_in_braces()};
END_PERL
	my $words = $doc->find('Token::Word');
	my %words = map { $_ => $_ } @{$words};

	ok( $words{hash_subscript_key}->hash_key,
		'Word inside hash subscript is a hash key' );
	ok( $words{fat_comma_key}->hash_key,
		'Word before fat comma is a hash key' );
	ok( !$words{func_not_key}->hash_key,
		'Function call is not a hash key' );
	ok( !$words{bare_word}->hash_key,
		'Bare word is not a hash key' );
	ok( !$words{func_in_braces}->hash_key,
		'Function call inside braces is not a hash key' );
}

CLASS_NAME: {
	my $doc = safe_new \<<'END_PERL';
Foo->new;
$obj->a_method;
Bar->class_method;
Baz::Quux->nested_class;
not_a_class();
END_PERL
	my $words = $doc->find('Token::Word');
	my %words = map { $_ => $_ } @{$words};

	ok( $words{Foo}->class_name,
		'Class before -> is a class name' );
	ok( !$words{new}->class_name,
		'Method after -> is not a class name' );
	ok( !$words{a_method}->class_name,
		'Method called on object is not a class name' );
	ok( $words{Bar}->class_name,
		'Class before ->class_method is a class name' );
	ok( !$words{class_method}->class_name,
		'class_method after -> is not a class name' );
	ok( !$words{not_a_class}->class_name,
		'Function call is not a class name' );
}

SUBROUTINE_NAME: {
	my $doc = safe_new \<<'END_PERL';
sub my_sub { }
sub forward_decl;
not_a_sub();
END_PERL
	my $words = $doc->find('Token::Word');
	my %words = map { $_ => $_ } @{$words};

	ok( $words{my_sub}->subroutine_name,
		'Name in sub declaration is a subroutine name' );
	ok( $words{forward_decl}->subroutine_name,
		'Name in forward declaration is a subroutine name' );
	ok( !$words{not_a_sub}->subroutine_name,
		'Function call is not a subroutine name' );
}

INCLUDED_MODULE_NAME: {
	my $doc = safe_new \<<'END_PERL';
use My::Module;
require Another::Module;
no Some::Pragma;
not_a_module();
END_PERL
	my $words = $doc->find('Token::Word');
	my %words;
	for my $w (@{$words}) {
		$words{"$w"} = $w;
	}

	ok( $words{'My::Module'}->included_module_name,
		'Module in use statement is an included module name' );
	ok( $words{'Another::Module'}->included_module_name,
		'Module in require statement is an included module name' );
	ok( $words{'Some::Pragma'}->included_module_name,
		'Module in no statement is an included module name' );
	ok( !$words{use}->included_module_name,
		'use keyword is not an included module name' );
	ok( !$words{not_a_module}->included_module_name,
		'Function call is not an included module name' );
}

LABEL_POINTER: {
	my $doc = safe_new \<<'END_PERL';
next NEXT_LABEL;
last LAST_LABEL;
redo REDO_LABEL;
goto GOTO_LABEL;
not_a_label();
END_PERL
	my $words = $doc->find('Token::Word');
	my %words = map { $_ => $_ } @{$words};

	ok( $words{NEXT_LABEL}->label_pointer,
		'Label in next is a label pointer' );
	ok( $words{LAST_LABEL}->label_pointer,
		'Label in last is a label pointer' );
	ok( $words{REDO_LABEL}->label_pointer,
		'Label in redo is a label pointer' );
	ok( $words{GOTO_LABEL}->label_pointer,
		'Label in goto is a label pointer' );
	ok( !$words{not_a_label}->label_pointer,
		'Function call is not a label pointer' );
	ok( !$words{next}->label_pointer,
		'next keyword is not a label pointer' );
	ok( !$words{last}->label_pointer,
		'last keyword is not a label pointer' );
}

PACKAGE_DECLARATION: {
	my $doc = safe_new \<<'END_PERL';
package My::Package;
use Not::A::Package;
END_PERL
	my $words = $doc->find('Token::Word');
	my %words;
	for my $w (@{$words}) {
		$words{"$w"} = $w;
	}

	ok( $words{'My::Package'}->package_declaration,
		'Package name in package statement is a package declaration' );
	ok( !$words{package}->package_declaration,
		'package keyword is not a package declaration' );
	ok( !$words{'Not::A::Package'}->package_declaration,
		'Module in use statement is not a package declaration' );
}

COMBINATIONS: {
	my $doc = safe_new \<<'END_PERL';
package Pkg;
use Mod;
sub func { }
Cls->meth;
next LBL;
$h{hkey};
fat_key => 1;
plain_call();
END_PERL
	my $words = $doc->find('Token::Word');
	my %words;
	for my $w (@{$words}) {
		$words{"$w"} = $w;
	}

	ok( $words{Pkg}->package_declaration
			&& !$words{Pkg}->included_module_name,
		'Pkg is a package declaration but not an included module name' );
	ok( $words{Mod}->included_module_name
			&& !$words{Mod}->package_declaration,
		'Mod is an included module name but not a package declaration' );
	ok( $words{func}->subroutine_name
			&& !$words{func}->hash_key,
		'func is a subroutine name but not a hash key' );
	ok( $words{Cls}->class_name
			&& !$words{Cls}->subroutine_name,
		'Cls is a class name but not a subroutine name' );
	ok( $words{meth}->method_call
			&& !$words{meth}->class_name,
		'meth is a method call but not a class name' );
	ok( $words{hkey}->hash_key
			&& !$words{hkey}->subroutine_name,
		'hkey is a hash key but not a subroutine name' );
}

1;
