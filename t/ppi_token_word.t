#!/usr/bin/perl

# Unit testing for PPI::Token::Word

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 61;
use Test::NoWarnings;
use PPI;


LITERAL: {
	my @pairs = (
		"F",        'F',
		"Foo::Bar", 'Foo::Bar',
		"Foo'Bar",  'Foo::Bar',
	);
	while ( @pairs ) {
		my $from  = shift @pairs;
		my $to	= shift @pairs;
		my $doc   = PPI::Document->new( \"$from;" );
		isa_ok( $doc, 'PPI::Document' );
		my $word = $doc->find_first('Token::Word');
		isa_ok( $word, 'PPI::Token::Word' );
		is( $word->literal, $to, "The source $from becomes $to ok" );
	}
}


METHOD_CALL: {
	my $Document = PPI::Document->new(\<<'END_PERL');
indirect $foo;
indirect_class_with_colon Foo::;
$bar->method_with_parentheses;
print SomeClass->method_without_parentheses + 1;
sub_call();
$baz->chained_from->chained_to;
a_first_thing a_middle_thing a_last_thing;
(first_list_element, second_list_element, third_list_element);
first_comma_separated_word, second_comma_separated_word, third_comma_separated_word;
single_bareword_statement;
{ bareword_no_semicolon_end_of_block }
$buz{hash_key};
fat_comma_left_side => $thingy;
END_PERL

	isa_ok( $Document, 'PPI::Document' );
	my $words = $Document->find('Token::Word');
	is( scalar @{$words}, 23, 'Found the 23 test words' );
	my %words = map { $_ => $_ } @{$words};
	is(
		scalar $words{indirect}->method_call,
		undef,
		'Indirect notation is unknown.',
	);
	is(
		scalar $words{indirect_class_with_colon}->method_call,
		1,
		'Indirect notation with following word ending with colons is true.',
	);
	is(
		scalar $words{method_with_parentheses}->method_call,
		1,
		'Method with parentheses is true.',
	);
	is(
		scalar $words{method_without_parentheses}->method_call,
		1,
		'Method without parentheses is true.',
	);
	is(
		scalar $words{print}->method_call,
		undef,
		'Plain print is unknown.',
	);
	is(
		scalar $words{SomeClass}->method_call,
		undef,
		'Class in class method call is unknown.',
	);
	is(
		scalar $words{sub_call}->method_call,
		0,
		'Subroutine call is false.',
	);
	is(
		scalar $words{chained_from}->method_call,
		1,
		'Method that is chained from is true.',
	);
	is(
		scalar $words{chained_to}->method_call,
		1,
		'Method that is chained to is true.',
	);
	is(
		scalar $words{a_first_thing}->method_call,
		undef,
		'First bareword is unknown.',
	);
	is(
		scalar $words{a_middle_thing}->method_call,
		undef,
		'Bareword in the middle is unknown.',
	);
	is(
		scalar $words{a_last_thing}->method_call,
		0,
		'Bareword at the end is false.',
	);
	foreach my $false_word (
		qw<
			first_list_element second_list_element third_list_element
			first_comma_separated_word second_comma_separated_word third_comma_separated_word
			single_bareword_statement
			bareword_no_semicolon_end_of_block
			hash_key
			fat_comma_left_side
		>
	) {
		is(
			scalar $words{$false_word}->method_call,
			0,
			"$false_word is false.",
		);
	}
}


__TOKENIZER__ON_CHAR: {
	my $Document = PPI::Document->new(\<<'END_PERL');
$foo eq'bar';
$foo ne'bar';
$foo ge'bar';
$foo le'bar';
$foo gt'bar';
$foo lt'bar';
END_PERL

	isa_ok( $Document, 'PPI::Document' );
	my $words = $Document->find('Token::Operator');
	is( scalar @{$words}, 6, 'Found the 6 test operators' );

	is( $words->[0], 'eq', q{$foo eq'bar'} );
	is( $words->[1], 'ne', q{$foo ne'bar'} );
	is( $words->[2], 'ge', q{$foo ge'bar'} );
	is( $words->[3], 'le', q{$foo le'bar'} );
	is( $words->[4], 'gt', q{$foo ht'bar'} );
	is( $words->[5], 'lt', q{$foo lt'bar'} );

	$Document = PPI::Document->new(\<<'END_PERL');
q'foo';
qq'foo';
END_PERL

	isa_ok( $Document, 'PPI::Document' );
	$words = $Document->find('Token::Quote');
	is( scalar @{$words}, 2, 'Found the 2 test quotes' );

	is( $words->[0], q{q'foo'}, q{q'foo'} );
	is( $words->[1], q{qq'foo'}, q{qq'foo'} );

	$Document = PPI::Document->new(\<<'END_PERL');
qx'foo';
qw'foo';
qr'foo';
END_PERL

	isa_ok( $Document, 'PPI::Document' );
	$words = $Document->find('Token::QuoteLike');
	is( scalar @{$words}, 3, 'Found the 3 test quotelikes' );

	is( $words->[0], q{qx'foo'}, q{qx'foo'} );
	is( $words->[1], q{qw'foo'}, q{qw'foo'} );
	is( $words->[2], q{qr'foo'}, q{qr'foo'} );

	$Document = PPI::Document->new(\<<'END_PERL');
m'foo';
s'foo'bar';
tr'fo'ba';
y'fo'ba';
END_PERL

	isa_ok( $Document, 'PPI::Document' );
	$words = $Document->find('Token::Regexp');
	is( scalar @{$words}, 4, 'Found the 4 test quotelikes' );

	is( $words->[0], q{m'foo'},     q{m'foo'} );
	is( $words->[1], q{s'foo'bar'}, q{s'foo'bar'} );
	is( $words->[2], q{tr'fo'ba'},  q{tr'fo'ba'} );
	is( $words->[3], q{y'fo'ba'},   q{y'fo'ba'} );

	$Document = PPI::Document->new(\<<'END_PERL');
pack'H*',$data;
unpack'H*',$data;
END_PERL

	isa_ok( $Document, 'PPI::Document' );
	$words = $Document->find('Token::Word');
	is( scalar @{$words}, 2, 'Found the 2 test words' );

	is( $words->[0], 'pack', q{pack'H*',$data} );
	is( $words->[1], 'unpack', q{unpack'H*',$data} );
}
