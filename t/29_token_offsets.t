#!/usr/bin/perl

use utf8;
use open qw(:std :utf8);
use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 12;
use Test::NoWarnings;
use PPI;

my @tests = (
[
	"use strict;",
	[
		[0, 2],   # use
		[3, 3],   # whitespace
		[4, 9],   # strict
		[10, 10], # ;
	],
],
[
	"use strict;\nuse warnings;",
	[
		[0, 2],   # use
		[3, 3],   # whitespace
		[4, 9],   # strict
		[10, 10], # ;
		[11, 11], # newline
		[12, 14], # use
		[15, 15], # whitespace
		[16, 23], # warnings
		[24, 24], # ;
	],
],
[
	"my \$var = <<EOT;\nheredocs <3\nEOT\n",
	[
		[0, 1],   # my
		[2, 2],   # whitespace
		[3, 6],   # $var
		[7, 7],   # whitespace
		[8, 8],   # =
		[9, 9],   # whitespace
		undef,    # heredoc
		[15, 15], # ;
		[16, 16], # newline
	],
],
[
	"foobar(<<EOT);\nheredocs <3\nEOT\n",
	[
		[0, 5],   # foobar
		[6, 6],   # (
		undef,    # heredoc
		[12, 12], # )
		[13, 13], # ;
		[14, 14], # newline
	],
],
[
	"foobar(<<EOT);\nheredocs <3\nEOT\nmy \$var = <<EOT;\nheredocs <3\nEOT\n",
	[
		[0, 5],   # foobar
		[6, 6],   # (
		undef,    # heredoc
		[12, 12], # )
		[13, 13], # ;
		[14, 14], # newline
		[31, 32], # my
		[33, 33], # whitespace
		[34, 37], # $var
		[38, 38], # whitespace
		[39, 39], # =
		[40, 40], # whitespace
		undef,    # heredoc
		[46, 46], # ;
		[47, 47], # newline
	],
],
[
	"foobar(<<EOT, \$var1);\nheredocs <3\nEOT\nmy \$var2;",
	[
		[0, 5],   # foobar
		[6, 6],   # (
		undef,    # heredoc
		[12, 12], # ,
		[13, 13], # whitespace
		[14, 18], # $var1
		[19, 19], # )
		[20, 20], # ;
		[21, 21], # \n
		[38, 39], # my
		[40, 40], # whitespace
		[41, 45], # $var2
		[46, 46], # ;
	],
],
[
	"foobar(<<EOT1, <<EOT2);\nheredocs <3\nEOT1\nheredocs <3\nEOT2\nmy \$var;",
	[
		[0, 5],   # foobar
		[6, 6],   # (
		undef,    # heredoc
		[13, 13], # ,
		[14, 14], # whitespace
		undef,    # heredoc
		[21, 21], # )
		[22, 22], # ;
		[23, 23], # \n
		[58, 59], # my
		[60, 60], # whitespace
		[61, 64], # $var
		[65, 65], # ;
	],
],
[
	"foobar(<<EOT1, \$var, <<EOT2);\nheredocs <3\nEOT1\nheredocs <3\nEOT2\nmy \$var2;",
	[
		[0, 5],   # foobar
		[6, 6],   # (
		undef,    # heredoc
		[13, 13], # ,
		[14, 14], # whitespace
		[15, 18], # $var
		[19, 19], # ,
		[20, 20], # whitespace
		undef,    # heredoc
		[27, 27], # )
		[28, 28], # ;
		[29, 29], # \n
		[64, 65], # my
		[66, 66], # whitespace
		[67, 71], # $var2
		[72, 72], # ;
	],
],
[
	"foobar(<<EOT1, \$var, <<EOT2, \$var2);\nheredocs <3\nEOT1\nheredocs <3\nEOT2\nmy \$var3;",
	[
		[0, 5],   # foobar
		[6, 6],   # (
		undef,    # heredoc
		[13, 13], # ,
		[14, 14], # whitespace
		[15, 18], # $var
		[19, 19], # ,
		[20, 20], # whitespace
		undef,    # heredoc
		[27, 27], # whitespace
		[28, 28], # comma
		[29, 33], # $var2
		[34, 34], # )
		[35, 35], # ;
		[36, 36], # \n
		[71, 72], # my
		[73, 73], # whitespace
		[74, 78], # $var3
		[79, 79], # ;
	],
],
[
	"my \@lines = <<EOT =~ /regex/;\nheredocs <3\nEOT\n",
	[
		[0, 1],   # my
		[2, 2],   # whitespace
		[3, 8],   # @lines
		[9, 9],   # whitespace
		[10, 10], # =
		[11, 11], # whitespace
		undef,    # heredoc
		[17, 17], # whitespace
		[18, 19], # =~
		[20, 20], # whitespace
		[21, 27], # /regex/
		[28, 28], # ;
		[29, 29], # \n
	],
],
[
	"my \$var = 'こんにちは';",
	[
		[0, 1],   # my
		[2, 2],   # whitespace
		[3, 6],   # $var
		[7, 7],   # whitespace
		[8, 8],   # =
		[9, 9],   # whitespace
		[10, 26], # 'こんにちは'
		[27, 27], # ;
	],
],
);

for my $t (@tests) {
	my $Document = PPI::Document->new( \$t->[0] );

	my $ok = is_deeply(
		[ map($_->byte_span, $Document->tokens) ],
		$t->[1],
		"Tokens have correct byte spans"
	);

	unless($ok) {
		diag($t->[0]);
	}
}
