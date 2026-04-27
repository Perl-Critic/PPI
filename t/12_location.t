#!/usr/bin/perl

# Tests the accuracy and features for location functionality

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 695 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


my $test_source = <<'END_PERL';
my $foo = 'bar';

# comment
sub foo {
    my ($this, $that) = (<<'THIS', <<"THAT");
foo
bar
baz
THIS
foo
bar
THAT
}

sub baz {
	# sub baz contains *tabs*
	my ($one, $other) = 	("one",	"other");	# contains 4 tabs

	foo()	;
}

sub bar {
    baz();

    #Note that there are leading 4 x space, not 1 x tab in the sub bar

    bas();
}

=head2 fluzz()

Print "fluzz". Return 1.

=cut
sub fluzz {
    print "fluzz";# line 300 not_at_start_of_line
}

#line 400
$a
# line 500
$b
#line600
$c
#line 700 filename
$d
#line 800another-filename
$e
#line 900 yet-another-filename
$f
#line 1000"quoted-filename"
$g

=pod

 #line 1100

=cut
$h
=pod

#line 1200

=cut
$i
=pod

# line 1300

=cut
$j
=pod

#line1400

=cut
$k
=pod

#line 1500 filename

=cut
$l
=pod

#line 1600another-filename

=cut
$m
=pod

#line 1700 yet-another-filename

=cut
$n
=pod

#line 1800"quoted-filename"

=cut
$o

1;
END_PERL
my @test_locations = (
	[   1,  1,  1,    1, undef,   1 ],		# my
	[   1,  3,  3,    1, undef,   3 ],		# ' '
	[   1,  4,  4,    1, undef,   4 ],		# $foo
	[   1,  8,  8,    1, undef,   8 ],		# ' '
	[   1,  9,  9,    1, undef,   9 ],		# =
	[   1, 10, 10,    1, undef,  10 ],		# ' '
	[   1, 11, 11,    1, undef,  11 ],		# 'bar'
	[   1, 16, 16,    1, undef,  16 ],		# ;
	[   1, 17, 17,    1, undef,  17 ],		# \n

	[   2,  1,  1,    2, undef,  18 ],		# \n

	[   3,  1,  1,    3, undef,  19 ],		# # comment

	[   4,  1,  1,    4, undef,  29 ],		# sub
	[   4,  4,  4,    4, undef,  32 ],		# ' '
	[   4,  5,  5,    4, undef,  33 ],		# foo
	[   4,  8,  8,    4, undef,  36 ],		# ' '
	[   4,  9,  9,    4, undef,  37 ],		# {
	[   4, 10, 10,    4, undef,  38 ],		# \n

	[   5,  1,  1,    5, undef,  39 ],		# '    '
	[   5,  5,  5,    5, undef,  43 ],		# my
	[   5,  7,  7,    5, undef,  45 ],		# ' '
	[   5,  8,  8,    5, undef,  46 ],		# (
	[   5,  9,  9,    5, undef,  47 ],		# $this
	[   5, 14, 14,    5, undef,  52 ],		# ,
	[   5, 15, 15,    5, undef,  53 ],		# ' '
	[   5, 16, 16,    5, undef,  54 ],		# $that
	[   5, 21, 21,    5, undef,  59 ],		# )
	[   5, 22, 22,    5, undef,  60 ],		# ' '
	[   5, 23, 23,    5, undef,  61 ],		# =
	[   5, 24, 24,    5, undef,  62 ],		# ' '
	[   5, 25, 25,    5, undef,  63 ],		# (
	[   5, 26, 26,    5, undef,  64 ],		# <<'THIS'
	[   5, 34, 34,    5, undef,  72 ],		# ,
	[   5, 35, 35,    5, undef,  73 ],		# ' '
	[   5, 36, 36,    5, undef,  74 ],		# <<"THAT"
	[   5, 44, 44,    5, undef,  82 ],		# )
	[   5, 45, 45,    5, undef,  83 ],		# ;
	[   5, 46, 46,    5, undef,  84 ],		# \n

	[  13,  1,  1,   13, undef, 115 ],		# }
	[  13,  2,  2,   13, undef, 116 ],		# \n

	[  14,  1,  1,   14, undef, 117 ],		# \n

	[  15,  1,  1,   15, undef, 118 ],		# sub
	[  15,  4,  4,   15, undef, 121 ],		# ' '
	[  15,  5,  5,   15, undef, 122 ],		# baz
	[  15,  8,  8,   15, undef, 125 ],		# ' '
	[  15,  9,  9,   15, undef, 126 ],		# {
	[  15, 10, 10,   15, undef, 127 ],		# \n

	[  16,  1,  1,   16, undef, 128 ],		# tab# sub baz contains *tabs*
	[  17,  1,  1,   17, undef, 155 ],		# tab
	[  17,  2,  5,   17, undef, 156 ],		# my
	[  17,  4,  7,   17, undef, 158 ],		# ' '
	[  17,  5,  8,   17, undef, 159 ],		# (
	[  17,  6,  9,   17, undef, 160 ],		# $one
	[  17, 10, 13,   17, undef, 164 ],		# ,
	[  17, 11, 14,   17, undef, 165 ],		# ' '
	[  17, 12, 15,   17, undef, 166 ],		# $other
	[  17, 18, 21,   17, undef, 172 ],		# )
	[  17, 19, 22,   17, undef, 173 ],		# ' '
	[  17, 20, 23,   17, undef, 174 ],		# =
	[  17, 21, 24,   17, undef, 175 ],		# ' tab'
	[  17, 23, 29,   17, undef, 177 ],		# (
	[  17, 24, 30,   17, undef, 178 ],		# "one"
	[  17, 29, 35,   17, undef, 183 ],		# ,
	[  17, 30, 36,   17, undef, 184 ],		# tab
	[  17, 31, 37,   17, undef, 185 ],		# "other"
	[  17, 38, 44,   17, undef, 192 ],		# )
	[  17, 39, 45,   17, undef, 193 ],		# ;
	[  17, 40, 46,   17, undef, 194 ],		# tab
	[  17, 41, 49,   17, undef, 195 ],		# # contains 3 tabs
	[  17, 58, 66,   17, undef, 212 ],		# \n

	[  18,  1,  1,   18, undef, 213 ],		# \n\t

	[  19,  2,  5,   19, undef, 215 ],		# foo
	[  19,  5,  8,   19, undef, 218 ],		# (
	[  19,  6,  9,   19, undef, 219 ],		# )
	[  19,  7, 10,   19, undef, 220 ],		# tab
	[  19,  8, 13,   19, undef, 221 ],		# ;
	[  19,  9, 14,   19, undef, 222 ],		# \n

	[  20,  1,  1,   20, undef, 223 ],		# {
	[  20,  2,  2,   20, undef, 224 ],		# \n

	[  21,  1,  1,   21, undef, 225 ],		# \n

	[  22,  1,  1,   22, undef, 226 ],		# sub
	[  22,  4,  4,   22, undef, 229 ],		# ' '
	[  22,  5,  5,   22, undef, 230 ],		# bar
	[  22,  8,  8,   22, undef, 233 ],		# ' '
	[  22,  9,  9,   22, undef, 234 ],		# {
	[  22, 10, 10,   22, undef, 235 ],		# \n

	[  23,  1,  1,   23, undef, 236 ],		# '    '
	[  23,  5,  5,   23, undef, 240 ],		# baz
	[  23,  8,  8,   23, undef, 243 ],		# (
	[  23,  9,  9,   23, undef, 244 ],		# )
	[  23, 10, 10,   23, undef, 245 ],		# ;
	[  23, 11, 11,   23, undef, 246 ],		# \n

	[  24,  1,  1,   24, undef, 247 ],		# \n

	[  25,  1,  1,   25, undef, 248 ],		# #Note that there are leading 4 x space, ...

	[  26,  1,  1,   26, undef, 319 ],		# '\n    '

	[  27,  5,  5,   27, undef, 324 ],		# bas
	[  27,  8,  8,   27, undef, 327 ],		# (
	[  27,  9,  9,   27, undef, 328 ],		# )
	[  27, 10, 10,   27, undef, 329 ],		# ;
	[  27, 11, 11,   27, undef, 330 ],		# \n

	[  28,  1,  1,   28, undef, 331 ],		# }
	[  28,  2,  2,   28, undef, 332 ],		# \n

	[  29,  1,  1,   29, undef, 333 ],		# \n

	[  30,  1,  1,   30, undef, 334 ],		# =head2 fluzz() ...

	[  35,  1,  1,   35, undef, 381 ],		# sub
	[  35,  4,  4,   35, undef, 384 ],		# ' '
	[  35,  5,  5,   35, undef, 385 ],		# fluzz
	[  35, 10, 10,   35, undef, 390 ],		# ' '
	[  35, 11, 11,   35, undef, 391 ],		# {
	[  35, 12, 12,   35, undef, 392 ],		# \n

	[  36,  1,  1,   36, undef, 393 ],		# '    '
	[  36,  5,  5,   36, undef, 397 ],		# print
	[  36, 10, 10,   36, undef, 402 ],		# ' '
	[  36, 11, 11,   36, undef, 403 ],		# "fluzz"
	[  36, 18, 18,   36, undef, 410 ],		# ;
	[  36, 19, 19,   36, undef, 411 ],		# # line 300 not_at_start_of_line
	[  36, 50, 50,   36, undef, 442 ],		# \n

	[  37,  1,  1,   37, undef, 443 ],		# }
	[  37,  2,  2,   37, undef, 444 ],		# \n

	[  38,  1,  1,   38, undef, 445 ],		# \n

	[  39,  1,  1,   39, undef, 446 ],		# #line 400

	[  40,  1,  1,  400, undef, 456 ],		# $a
	[  40,  3,  3,  400, undef, 458 ],		# \n

	[  41,  1,  1,  401, undef, 459 ],		# # line 500

	[  42,  1,  1,  500, undef, 470 ],		# $b
	[  42,  3,  3,  500, undef, 472 ],		# \n

	#  No space between "line" and number causes it to not work.
	[  43,  1,  1,  501, undef, 473 ],		# #line600

	[  44,  1,  1,  502, undef, 482 ],		# $c
	[  44,  3,  3,  502, undef, 484 ],		# \n

	[  45,  1,  1,  503, undef, 485 ],		# #line 700 filename

	[  46,  1,  1,  700, 'filename', 504 ],		# $d
	[  46,  3,  3,  700, 'filename', 506 ],		# \n

	[  47,  1,  1,  701, 'filename', 507 ],		# #line 800another-filename

	[  48,  1,  1,  800, 'another-filename', 533 ],		# $e
	[  48,  3,  3,  800, 'another-filename', 535 ],		# \n

	[  49,  1,  1,  801, 'another-filename', 536 ],		# #line 900 yet-another-filename

	[  50,  1,  1,  900, 'yet-another-filename', 567 ],		# $f
	[  50,  3,  3,  900, 'yet-another-filename', 569 ],		# \n

	[  51,  1,  1,  901, 'yet-another-filename', 570 ],		# #line 1000"quoted-filename"

	[  52,  1,  1, 1000, 'quoted-filename', 598 ],		# $g
	[  52,  3,  3, 1000, 'quoted-filename', 600 ],		# \n

	[  53,  1,  1, 1001, 'quoted-filename', 601 ],		# \n

	[  54,  1,  1, 1002, 'quoted-filename', 602 ],		# =pod #line 1100 (not in column 1)

	[  59,  1,  1, 1007, 'quoted-filename', 626 ],		# $h
	[  59,  3,  3, 1007, 'quoted-filename', 628 ],		# \n

	[  60,  1,  1, 1008, 'quoted-filename', 629 ],		# =pod #line 1200

	[  65,  1,  1, 1202, 'quoted-filename', 652 ],		# $i
	[  65,  3,  3, 1202, 'quoted-filename', 654 ],		# \n

	[  66,  1,  1, 1203, 'quoted-filename', 655 ],		# =pod # line 1300

	[  71,  1,  1, 1302, 'quoted-filename', 679 ],		# $j
	[  71,  3,  3, 1302, 'quoted-filename', 681 ],		# \n

	#  No space between "line" and number causes it to not work.
	[  72,  1,  1, 1303, 'quoted-filename', 682 ],		# =pod #line1400

	[  77,  1,  1, 1308, 'quoted-filename', 704 ],		# $k
	[  77,  3,  3, 1308, 'quoted-filename', 706 ],		# \n

	[  78,  1,  1, 1309, 'quoted-filename', 707 ],		# =pod #line 1500 filename

	[  83,  1,  1, 1502, 'filename', 739 ],		# $l
	[  83,  3,  3, 1502, 'filename', 741 ],		# \n

	[  84,  1,  1, 1503, 'filename', 742 ],		# =pod #line 1600another-filename

	[  89,  1,  1, 1602, 'another-filename', 781 ],		# $m
	[  89,  3,  3, 1602, 'another-filename', 783 ],		# \n

	[  90,  1,  1, 1603, 'another-filename', 784 ],		# =pod #line 1700 yet-another-filename

	[  95,  1,  1, 1702, 'yet-another-filename', 828 ],		# $n
	[  95,  3,  3, 1702, 'yet-another-filename', 830 ],		# \n

	[  96,  1,  1, 1703, 'yet-another-filename', 831 ],		# =pod #line 1800"quoted-filename"

	[ 101,  1,  1, 1802, 'quoted-filename', 871 ],		# $o
	[ 101,  3,  3, 1802, 'quoted-filename', 873 ],		# \n

	[ 102,  1,  1, 1803, 'quoted-filename', 874 ],		# \n

	[ 103,  1,  1, 1804, 'quoted-filename', 875 ],		# 1
	[ 103,  2,  2, 1804, 'quoted-filename', 876 ],		# ;
	[ 103,  3,  3, 1804, 'quoted-filename', 877 ],		# \n
);



#####################################################################
# Test the locations of everything in the test code

# Prepare
my $Document = safe_new \$test_source;
$Document->tab_width(4);
is($Document->tab_width, 4, 'Tab width set correctly');
ok( $Document->index_locations, '->index_locations returns true' );

# Now check the locations of every token
my @tokens = $Document->tokens;
is( scalar(@tokens), scalar(@test_locations), 'Number of tokens matches expected' );
foreach my $i ( 0 .. $#test_locations ) {
	my $location = $tokens[$i]->location;
	is( ref($location), 'ARRAY', "Token $i: ->location returns an ARRAY ref" );
	is( scalar(@$location), 6, "Token $i: ->location returns a 6 element ARRAY ref" );
	ok(
		(
				$location->[0] > 0
			and $location->[1] > 0
			and $location->[2] > 0
			and $location->[3] > 0
			and $location->[5] > 0
		),
		"Token $i: ->location returns five positive positions"
	);
	is_deeply(
		$tokens[$i]->location,
		$test_locations[$i],
		"Token $i: ->location matches expected",
	);
}

ok( $Document->flush_locations, '->flush_locations returns true' );
is( scalar(grep { defined $_->{_location} } $Document->tokens), 0, 'All _location attributes removed' );


#####################################################################
# Character offset tests

# Simple source: verify location returns 6 elements and offsets are correct
{
	my $simple_src = 'my $x = 1;';
	my $sdoc = PPI::Document->new( \$simple_src );
	$sdoc->index_locations;
	my @st = $sdoc->tokens;

	is( scalar( @{ $st[0]->location } ), 6,
		"location returns a 6-element array" );

	# character_offset accessor
	is( $st[0]->character_offset, 1,  'my at offset 1' );
	is( $st[1]->character_offset, 3,  'space at offset 3' );
	is( $st[2]->character_offset, 4,  '$x at offset 4' );
	is( $st[3]->character_offset, 6,  'space at offset 6' );
	is( $st[4]->character_offset, 7,  '= at offset 7' );
	is( $st[5]->character_offset, 8,  'space at offset 8' );
	is( $st[6]->character_offset, 9,  '1 at offset 9' );
	is( $st[7]->character_offset, 10, '; at offset 10' );
}

# Heredoc: offsets account for heredoc body content
{
	my $hd_src = "my \$x = <<'END';\nhello\nEND\n\$y;\n";
	my $hdoc = PPI::Document->new( \$hd_src );
	$hdoc->index_locations;
	my @ht = $hdoc->tokens;
	# $y should be after: "my $x = <<'END';\n" (17) + "hello\n" (6) + "END\n" (4) = offset 28
	is( $ht[-3]->character_offset, 28,
		'$y at offset 28 (after heredoc body)' );
}

# All offsets match positions in the serialized document
{
	my $tdoc = PPI::Document->new( \$test_source );
	$tdoc->index_locations;
	my $serialized = $tdoc->serialize;
	my @tt = $tdoc->tokens;
	my $all_have_offsets = 1;
	my $all_match = 1;
	for my $i ( 0 .. $#tt ) {
		my $loc = $tt[$i]->location;
		unless ( $loc && @$loc >= 6 ) {
			$all_have_offsets = 0;
			$all_match = 0;
			next;
		}
		my $offset  = $loc->[5];
		my $content = $tt[$i]->content;
		my $at_pos  = substr( $serialized, $offset - 1, length($content) );
		$all_match = 0 unless $at_pos eq $content;
	}
	ok( $all_have_offsets, "all tokens in test_source have a 6th location element" );
	ok( $all_match, "all offsets match positions in the serialized document" );
}
