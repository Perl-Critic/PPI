#!/usr/bin/perl

# Unit testing for PPI::Token::QuoteLike::Words

use t::lib::PPI::Test::pragmas;
use Test::More tests => 1941;
use Test::Deep;

use PPI;

sub permute_test;
sub assemble_and_run;

my %known_bad = map { $_ => 1 } "qw ' \\' '", "qw ( \\( )", "qw ( \\) )", "qw / \\/ /", "qw 1 a \\1 1", "qw < \\< >", "qw < \\> >", "qw [ \\[ ]", "qw [ \\] ]", "qw \" \\\" \"", "qw a \\a a", "qw { \\{ }", "qw { \\} }", "qw# \\# #", "qw#\\##", "qw#\n\\#\n#", "qw' \\' '", "qw'\\''", "qw'\f\\'\f'", "qw'\n\\'\n'", "qw'\t\\'\t'", "qw( \\( )", "qw( \\) )", "qw( \\\\ )", "qw(\\()", "qw(\\))", "qw(\f\\(\f)", "qw(\f\\)\f)", "qw(\n\\(\n)", "qw(\n\\)\n)", "qw(\n\\\\\n)", "qw(\t\\(\t)", "qw(\t\\)\t)", "qw/ \\/ /", "qw/\\//", "qw/\f\\/\f/", "qw/\n\\/\n/", "qw/\t\\/\t/", "qw< \\< >", "qw< \\> >", "qw<\\<>", "qw<\\>>", "qw<\f\\<\f>", "qw<\f\\>\f>", "qw<\n\\<\n>", "qw<\n\\>\n>", "qw<\t\\<\t>", "qw<\t\\>\t>", "qw[ \\[ ]", "qw[ \\] ]", "qw[\\[]", "qw[\\]]", "qw[\f\\[\f]", "qw[\f\\]\f]", "qw[\n\\[\n]", "qw[\n\\]\n]", "qw[\t\\[\t]", "qw[\t\\]\t]", "qw\" \\\" \"", "qw\"\\\"\"", "qw\"\f\\\"\f\"", "qw\"\n\\\"\n\"", "qw\"\t\\\"\t\"", "qw\f'\f\\'\f'", "qw\f(\f\\(\f)", "qw\f(\f\\)\f)", "qw\f/\f\\/\f/", "qw\f<\f\\<\f>", "qw\f<\f\\>\f>", "qw\f[\f\\[\f]", "qw\f[\f\\]\f]", "qw\f\"\f\\\"\f\"", "qw\f{\f\\{\f}", "qw\f{\f\\}\f}", "qw\n'\n\\'\n'", "qw\n(\n\\(\n)", "qw\n(\n\\)\n)", "qw\n/\n\\/\n/", "qw\n<\n\\<\n>", "qw\n<\n\\>\n>", "qw\n[\n\\[\n]", "qw\n[\n\\]\n]", "qw\n\"\n\\\"\n\"", "qw\na\n\\a\na", "qw\n{\n\\{\n}", "qw\n{\n\\}\n}", "qw\t'\t\\'\t'", "qw\t(\t\\(\t)", "qw\t(\t\\)\t)", "qw\t/\t\\/\t/", "qw\t<\t\\<\t>", "qw\t<\t\\>\t>", "qw\t[\t\\[\t]", "qw\t[\t\\]\t]", "qw\t\"\t\\\"\t\"", "qw\t{\t\\{\t}", "qw\t{\t\\}\t}", "qw{ \\{ }", "qw{ \\} }", "qw{\\{}", "qw{\\}}", "qw{\f\\{\f}", "qw{\f\\}\f}", "qw{\n\\{\n}", "qw{\n\\}\n}", "qw{\t\\{\t}", "qw{\t\\}\t}";

LITERAL: {
	# empty
	permute_test [], '/', '/', [];
	permute_test [], '"', '"', [];
	permute_test [], "'", "'", [];
	permute_test [], '(', ')', [];
	permute_test [], '{', '}', [];
	permute_test [], '[', ']', [];
	permute_test [], '<', '>', [];

	# words
	permute_test ['a', 'b', 'c'],      '/', '/', ['a', 'b', 'c'];
	permute_test ['a,', 'b', 'c,'],    '/', '/', ['a,', 'b', 'c,'];
	permute_test ['a', ',', '#', 'c'], '/', '/', ['a', ',', '#', 'c'];
	permute_test ['f_oo', 'b_ar'],     '/', '/', ['f_oo', 'b_ar'];

	# it's allowed for both delims to be closers
	permute_test ['a'], ')', ')', ['a'];
	permute_test ['a'], '}', '}', ['a'];
	permute_test ['a'], ']', ']', ['a'];
	permute_test ['a'], '>', '>', ['a'];

	# containing things that sometimes are delimiters
	permute_test ['/'],        '(', ')', ['/'];
	permute_test ['//'],       '(', ')', ['//'];
	permute_test ['qw()'],     '(', ')', ['qw()'];
	permute_test ['qw', '()'], '(', ')', ['qw', '()'];
	permute_test ['qw//'],     '(', ')', ['qw//'];

	# nested delimiters
	permute_test ['()'],           '(', ')', ['()'];
	permute_test ['{}'],           '{', '}', ['{}'];
	permute_test ['[]'],           '[', ']', ['[]'];
	permute_test ['<>'],           '<', '>', ['<>'];
	permute_test ['((', ')', ')'], '(', ')', ['((', ')', ')'];
	permute_test ['{{', '}', '}'], '{', '}', ['{{', '}', '}'];
	permute_test ['[[', ']', ']'], '[', ']', ['[[', ']', ']'];
	permute_test ['<<', '>', '>'], '<', '>', ['<<', '>', '>'];

	my $bs = '\\'; # a single backslash character

	# escaped opening and closing
	permute_test ["$bs)"],   '(', ')', [')'];
	permute_test ["$bs("],   '(', ')', ['('];
	permute_test ["$bs}"],   '{', '}', ['}'];
	permute_test [$bs.'{'], '{', '}', ['{'];
	permute_test ["$bs]"],   '[', ']', [']'];
	permute_test [$bs.'['], '[', ']', ['['];
	permute_test ["$bs<"],   '<', '>', ['<'];
	permute_test ["$bs>"],   '<', '>', ['>'];
	permute_test ["$bs/"],   '/', '/', ['/'];
	permute_test ["$bs'"],   "'", "'", ["'"];
	permute_test [$bs.'"'],  '"', '"', ['"'];

	# alphanum delims have to be separated from qw
	assemble_and_run " ",  ['a', "${bs}1"], '1', " ",  " ",  '1', ['a', '1'];
	assemble_and_run " ",  ["${bs}a"],      'a', " ",  " ",  'a', ['a'];
	assemble_and_run "\n", ["${bs}a"],      'a', "\n", "\n", 'a', ['a'];

	# '#' delims cannot be separated from qw
	assemble_and_run '',  ['a'],      '#', '',   ' ',  '#', ['a'];
	assemble_and_run '',  ['a'],      '#', ' ',  ' ',  '#', ['a'];
	assemble_and_run '',  ["$bs#"],   '#', '',   ' ',  '#', ['#'];
	assemble_and_run '',  ["$bs#"],   '#', ' ',  ' ',  '#', ['#'];
	assemble_and_run '',  ["$bs#"],   '#', "\n", "\n", '#', ['#'];

	# a single backslash represents itself
	assemble_and_run '',  [$bs],  '(', ' ',  ' ', ')', [$bs];
	assemble_and_run '',  [$bs],  '(', "\n", ' ', ')', [$bs];

	# a double backslash represents itself
	assemble_and_run '',  ["$bs$bs"],  '(', ' ',  ' ', ')', [$bs];
	assemble_and_run '',  ["$bs$bs"],  '(', "\n", ' ', ')', [$bs];

	# even backslash can be a delimiter, in when it is, backslashes
	# can't be embedded or escaped.
	assemble_and_run '',   [],    $bs, ' ',  ' ',  $bs, [];
	assemble_and_run '',   [],    $bs, "\n", "\n", $bs, [];
	assemble_and_run '',   ['a'], $bs, '',   ' ',  $bs, ['a'];
	assemble_and_run ' ',  ['a'], $bs, '',   ' ',  $bs, ['a'];
	assemble_and_run "\n", ['a'], $bs, '',   ' ',  $bs, ['a'];
}

sub execute_test {
	my ( $code, $expected, $msg ) = @_;

	my $d = PPI::Document->new( \$code );
	isa_ok( $d, 'PPI::Document', $msg );
	my $found = $d->find( 'PPI::Token::QuoteLike::Words' ) || [];
	is( @$found, 1, "$msg - exactly one qw" );
	is( $found->[0]->content, $code, "$msg content()" );
TODO: {
	local $TODO = $known_bad{$code} ? "known bug" : undef;
	is_deeply( [ $found->[0]->literal ], $expected, "literal()"  ); # can't dump $msg, as it breaks TODO parsing
}

	return;
}

sub assemble_and_run {
	my ( $pre_left_delim, $words_in, $left_delim, $delim_padding, $word_separator, $right_delim, $expected ) = @_;

	my $code = "qw$pre_left_delim$left_delim$delim_padding" . join(' ', @$words_in) . "$delim_padding$right_delim";
	execute_test $code, $expected, $code;

	return;
}

sub permute_test {
	my ( $words_in, $left_delim, $right_delim, $expected ) = @_;

	assemble_and_run "",  $words_in, $left_delim, "", " ",  $right_delim, $expected;
	assemble_and_run "",  $words_in, $left_delim, "", "\t", $right_delim, $expected;
	assemble_and_run "",  $words_in, $left_delim, "", "\n", $right_delim, $expected;
	assemble_and_run "",  $words_in, $left_delim, "", "\f", $right_delim, $expected;

	assemble_and_run "",  $words_in, $left_delim, " ", " ",   $right_delim, $expected;
	assemble_and_run "",  $words_in, $left_delim, "\t", "\t", $right_delim, $expected;
	assemble_and_run "",  $words_in, $left_delim, "\n", "\n", $right_delim, $expected;
	assemble_and_run "",  $words_in, $left_delim, "\f", "\f", $right_delim, $expected;

	assemble_and_run " ",  $words_in, $left_delim, " ", " ",   $right_delim, $expected;
	assemble_and_run "\t", $words_in, $left_delim, "\t", "\t", $right_delim, $expected;
	assemble_and_run "\n", $words_in, $left_delim, "\n", "\n", $right_delim, $expected;
	assemble_and_run "\f", $words_in, $left_delim, "\f", "\f", $right_delim, $expected;

	return;
}
