#!/usr/bin/perl

# Unit testing for PPI::Token::QuoteLike::Words

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 1941;
use Test::Deep;
use Test::NoWarnings;
use PPI;


LITERAL: {
	my $bs = '\\'; # a single backslash character

	# empty
	permute_test( [], '/', '/', [] );
	permute_test( [], '"', '"', [] );
	permute_test( [], "'", "'", [] );
	permute_test( [], '(', ')', [] );
	permute_test( [], '{', '}', [] );
	permute_test( [], '[', ']', [] );
	permute_test( [], '<', '>', [] );

	# words
	permute_test( ['a', 'b', 'c'],      '/', '/', ['a', 'b', 'c'] );
	permute_test( ['a,', 'b', 'c,'],    '/', '/', ['a,', 'b', 'c,'] );
	permute_test( ['a', ',', '#', 'c'], '/', '/', ['a', ',', '#', 'c'] );
	permute_test( ['f_oo', 'b_ar'],     '/', '/', ['f_oo', 'b_ar'] );

	# it's allowed for both delims to be closers
	permute_test( ['a'], ')', ')', ['a'] );
	permute_test( ['a'], '}', '}', ['a'] );
	permute_test( ['a'], ']', ']', ['a'] );
	permute_test( ['a'], '>', '>', ['a'] );

	# containing things that sometimes are delimiters
	permute_test( ['/'],        '(', ')', ['/'] );
	permute_test( ['//'],       '(', ')', ['//'] );
	permute_test( ['qw()'],     '(', ')', ['qw()'] );
	permute_test( ['qw', '()'], '(', ')', ['qw', '()'] );
	permute_test( ['qw//'],     '(', ')', ['qw//'] );

	# nested delimiters
	permute_test( ['()'],           '(', ')', ['()'] );
	permute_test( ['{}'],           '{', '}', ['{}'] );
	permute_test( ['[]'],           '[', ']', ['[]'] );
	permute_test( ['<>'],           '<', '>', ['<>'] );
	permute_test( ['((', ')', ')'], '(', ')', ['((', ')', ')'] );
	permute_test( ['{{', '}', '}'], '{', '}', ['{{', '}', '}'] );
	permute_test( ['[[', ']', ']'], '[', ']', ['[[', ']', ']'] );
	permute_test( ['<<', '>', '>'], '<', '>', ['<<', '>', '>'] );

	# escaped opening and closing
	permute_test( ["$bs)"],   '(', ')', [')'] );
	permute_test( ["$bs("],   '(', ')', ['('] );
	permute_test( ["$bs}"],   '{', '}', ['}'] );
	permute_test( ["${bs}{"], '{', '}', ['{'] );
	permute_test( ["$bs]"],   '[', ']', [']'] );
	permute_test( ["${bs}["], '[', ']', ['['] );
	permute_test( ["$bs<"],   '<', '>', ['<'] );
	permute_test( ["$bs>"],   '<', '>', ['>'] );
	permute_test( ["$bs/"],   '/', '/', ['/'] );
	permute_test( ["$bs'"],   "'", "'", ["'"] );
	permute_test( [$bs.'"'],  '"', '"', ['"'] );
	# alphanum delims have to be separated from qw
	assemble_and_run( " ",  ['a', "${bs}1"], '1', " ",  " ",  '1', ['a', '1'] );
	assemble_and_run( " ",  ["${bs}a"],      'a', " ",  " ",  'a', ['a'] );
	assemble_and_run( "\n", ["${bs}a"],      'a', "\n", "\n", 'a', ['a'] );
	# '#' delims cannot be separated from qw
	assemble_and_run( '',  ['a'],      '#', '',   ' ',  '#', ['a'] );
	assemble_and_run( '',  ['a'],      '#', ' ',  ' ',  '#', ['a'] );
	assemble_and_run( '',  ["$bs#"],   '#', '',   ' ',  '#', ['#'] );
	assemble_and_run( '',  ["$bs#"],   '#', ' ',  ' ',  '#', ['#'] );
	assemble_and_run( '',  ["$bs#"],   '#', "\n", "\n", '#', ['#'] );
	# a single backslash represents itself
	assemble_and_run( '',  [$bs],  '(', ' ',  ' ', ')', [$bs] );
	assemble_and_run( '',  [$bs],  '(', "\n", ' ', ')', [$bs] );
	# a double backslash represents itself
	assemble_and_run( '',  ["$bs$bs"],  '(', ' ',  ' ', ')', [$bs] );
	assemble_and_run( '',  ["$bs$bs"],  '(', "\n", ' ', ')', [$bs] );
	# even backslash can be a delimiter, in when it is, backslashes
	# can't be embedded or escaped.
	assemble_and_run( '',   [],    $bs, ' ',  ' ',  $bs, [] );
	assemble_and_run( '',   [],    $bs, "\n", "\n", $bs, [] );
	assemble_and_run( '',   ['a'], $bs, '',   ' ',  $bs, ['a'] );
	assemble_and_run( ' ',  ['a'], $bs, '',   ' ',  $bs, ['a'] );
	assemble_and_run( "\n", ['a'], $bs, '',   ' ',  $bs, ['a'] );
}


sub permute_test {
	my $words_in = shift;
	my $left_delim = shift;
	my $right_delim = shift;
	my $expected = shift;

	assemble_and_run( "",  $words_in, $left_delim, "", " ",  $right_delim, $expected );
	assemble_and_run( "",  $words_in, $left_delim, "", "\t", $right_delim, $expected );
	assemble_and_run( "",  $words_in, $left_delim, "", "\n", $right_delim, $expected );
	assemble_and_run( "",  $words_in, $left_delim, "", "\f", $right_delim, $expected );

	assemble_and_run( "",  $words_in, $left_delim, " ", " ",   $right_delim, $expected );
	assemble_and_run( "",  $words_in, $left_delim, "\t", "\t", $right_delim, $expected );
	assemble_and_run( "",  $words_in, $left_delim, "\n", "\n", $right_delim, $expected );
	assemble_and_run( "",  $words_in, $left_delim, "\f", "\f", $right_delim, $expected );

	assemble_and_run( " ",  $words_in, $left_delim, " ", " ",   $right_delim, $expected );
	assemble_and_run( "\t", $words_in, $left_delim, "\t", "\t", $right_delim, $expected );
	assemble_and_run( "\n", $words_in, $left_delim, "\n", "\n", $right_delim, $expected );
	assemble_and_run( "\f", $words_in, $left_delim, "\f", "\f", $right_delim, $expected );

	return;
}


sub assemble_and_run {
	my $pre_left_delim = shift;
	my $words_in = shift;
	my $left_delim = shift;
	my $delim_padding = shift;
	my $word_separator = shift;
	my $right_delim = shift;
	my $expected = shift;

	my $code = "qw$pre_left_delim$left_delim$delim_padding" . join(' ', @$words_in) . "$delim_padding$right_delim";
	execute_test( $code, $expected, $code );

	return;
}


sub execute_test {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;

	my $d = PPI::Document->new( \$code );
	isa_ok( $d, 'PPI::Document', $msg );
	my $found = $d->find( 'PPI::Token::QuoteLike::Words' ) || [];
	is( @$found, 1, "$msg - exactly one qw" );
	is( $found->[0]->content, $code, "$msg content()" );
	is_deeply( [ $found->[0]->literal() ], $expected, "$msg literal()"  );

	return;
}

