#!/usr/bin/perl

# Tests the accuracy and features for location functionality

use strict;
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}

use Test::More tests => 683;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use PPI;

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
	[   1,  1,  1,    1, undef ],		# my
	[   1,  3,  3,    1, undef ],		# ' '
	[   1,  4,  4,    1, undef ],		# $foo
	[   1,  8,  8,    1, undef ],		# ' '
	[   1,  9,  9,    1, undef ],		# =
	[   1, 10, 10,    1, undef ],		# ' '
	[   1, 11, 11,    1, undef ],		# 'bar'
	[   1, 16, 16,    1, undef ],		# ;
	[   1, 17, 17,    1, undef ],		# \n

	[   2,  1,  1,    2, undef ],		# \n

	[   3,  1,  1,    3, undef ],		# # comment

	[   4,  1,  1,    4, undef ],		# sub
	[   4,  4,  4,    4, undef ],		# ' '
	[   4,  5,  5,    4, undef ],		# foo
	[   4,  8,  8,    4, undef ],		# ' '
	[   4,  9,  9,    4, undef ],		# {
	[   4, 10, 10,    4, undef ],		# \n

	[   5,  1,  1,    5, undef ],		# '    '
	[   5,  5,  5,    5, undef ],		# my
	[   5,  7,  7,    5, undef ],		# ' '
	[   5,  8,  8,    5, undef ],		# (
	[   5,  9,  9,    5, undef ],		# $this
	[   5, 14, 14,    5, undef ],		# ,
	[   5, 15, 15,    5, undef ],		# ' '
	[   5, 16, 16,    5, undef ],		# $that
	[   5, 21, 21,    5, undef ],		# )
	[   5, 22, 22,    5, undef ],		# ' '
	[   5, 23, 23,    5, undef ],		# =
	[   5, 24, 24,    5, undef ],		# ' '
	[   5, 25, 25,    5, undef ],		# (
	[   5, 26, 26,    5, undef ],		# <<'THIS'
	[   5, 34, 34,    5, undef ],		# ,
	[   5, 35, 35,    5, undef ],		# ' '
	[   5, 36, 36,    5, undef ],		# <<"THAT"
	[   5, 44, 44,    5, undef ],		# )
	[   5, 45, 45,    5, undef ],		# ;
	[   5, 46, 46,    5, undef ],		# \n

	[  13,  1,  1,   13, undef ],		# }
	[  13,  2,  2,   13, undef ],		# \n

	[  14,  1,  1,   14, undef ],		# \n

	[  15,  1,  1,   15, undef ],		# sub
	[  15,  4,  4,   15, undef ],		# ' '
	[  15,  5,  5,   15, undef ],		# baz
	[  15,  8,  8,   15, undef ],		# ' '
	[  15,  9,  9,   15, undef ],		# {
	[  15, 10, 10,   15, undef ],		# \n

	[  16,  1,  1,   16, undef ],		# tab# sub baz contains *tabs*
	[  17,  1,  1,   17, undef ],		# tab
	[  17,  2,  5,   17, undef ],		# my
	[  17,  4,  7,   17, undef ],		# ' '
	[  17,  5,  8,   17, undef ],		# (
	[  17,  6,  9,   17, undef ],		# $one
	[  17, 10, 13,   17, undef ],		# ,
	[  17, 11, 14,   17, undef ],		# ' '
	[  17, 12, 15,   17, undef ],		# $other 
	[  17, 18, 21,   17, undef ],		# )
	[  17, 19, 22,   17, undef ],		# ' '
	[  17, 20, 23,   17, undef ],		# =
	[  17, 21, 24,   17, undef ],		# ' tab'
	[  17, 23, 29,   17, undef ],		# (
	[  17, 24, 30,   17, undef ],		# "one"
	[  17, 29, 35,   17, undef ],		# ,
	[  17, 30, 36,   17, undef ],		# tab 
	[  17, 31, 37,   17, undef ],		# "other"
	[  17, 38, 44,   17, undef ],		# )
	[  17, 39, 45,   17, undef ],		# ;
	[  17, 40, 46,   17, undef ],		# tab
	[  17, 41, 49,   17, undef ],		# # contains 3 tabs
	[  17, 58, 66,   17, undef ],		# \n

	[  18,  1,  1,   18, undef ],		# \n\t

	[  19,  2,  5,   19, undef ],		# foo
	[  19,  5,  8,   19, undef ],		# (
	[  19,  6,  9,   19, undef ],		# )
	[  19,  7, 10,   19, undef ],		# tab
	[  19,  8, 13,   19, undef ],		# ;
	[  19,  9, 14,   19, undef ],		# \n

	[  20,  1,  1,   20, undef ],		# {
	[  20,  2,  2,   20, undef ],		# \n

	[  21,  1,  1,   21, undef ],		# \n

	[  22,  1,  1,   22, undef ],		# sub
	[  22,  4,  4,   22, undef ],		# ' '
	[  22,  5,  5,   22, undef ],		# bar
	[  22,  8,  8,   22, undef ],		# ' '
	[  22,  9,  9,   22, undef ],		# {
	[  22, 10, 10,   22, undef ],		# \n

	[  23,  1,  1,   23, undef ],		# '    '
	[  23,  5,  5,   23, undef ],		# baz
	[  23,  8,  8,   23, undef ],		# (
	[  23,  9,  9,   23, undef ],		# )
	[  23, 10, 10,   23, undef ],		# ;
	[  23, 11, 11,   23, undef ],		# \n

	[  24,  1,  1,   24, undef ],		# \n

	[  25,  1,  1,   25, undef ],		# #Note that there are leading 4 x space, ...

	[  26,  1,  1,   26, undef ],		# '\n    '

	[  27,  5,  5,   27, undef ],		# bas
	[  27,  8,  8,   27, undef ],		# (
	[  27,  9,  9,   27, undef ],		# )
	[  27, 10, 10,   27, undef ],		# ;
	[  27, 11, 11,   27, undef ],		# \n

	[  28,  1,  1,   28, undef ],		# }
	[  28,  2,  2,   28, undef ],		# \n

	[  29,  1,  1,   29, undef ],		# \n

	[  30,  1,  1,   30, undef ],		# =head2 fluzz() ...

	[  35,  1,  1,   35, undef ],		# sub
	[  35,  4,  4,   35, undef ],		# ' '
	[  35,  5,  5,   35, undef ],		# fluzz
	[  35, 10, 10,   35, undef ],		# ' '
	[  35, 11, 11,   35, undef ],		# {
	[  35, 12, 12,   35, undef ],		# \n

	[  36,  1,  1,   36, undef ],		# '    '
	[  36,  5,  5,   36, undef ],		# print
	[  36, 10, 10,   36, undef ],		# ' '
	[  36, 11, 11,   36, undef ],		# "fluzz"
	[  36, 18, 18,   36, undef ],		# ;
	[  36, 19, 19,   36, undef ],		# # line 300 not_at_start_of_line
	[  36, 50, 50,   36, undef ],		# \n

	[  37,  1,  1,   37, undef ],		# }
	[  37,  2,  2,   37, undef ],		# \n

	[  38,  1,  1,   38, undef ],		# \n

	[  39,  1,  1,   39, undef ],		# #line 400

	[  40,  1,  1,  400, undef ],		# $a
	[  40,  3,  3,  400, undef ],		# \n

	[  41,  1,  1,  401, undef ],		# # line 500

	[  42,  1,  1,  500, undef ],		# $b
	[  42,  3,  3,  500, undef ],		# \n

	#  No space between "line" and number causes it to not work.
	[  43,  1,  1,  501, undef ],		# #line600

	[  44,  1,  1,  502, undef ],		# $c
	[  44,  3,  3,  502, undef ],		# \n

	[  45,  1,  1,  503, undef ],		# #line 700 filename

	[  46,  1,  1,  700, 'filename' ],		# $d
	[  46,  3,  3,  700, 'filename' ],		# \n

	[  47,  1,  1,  701, 'filename' ],		# #line 800another-filename

	[  48,  1,  1,  800, 'another-filename' ],		# $e
	[  48,  3,  3,  800, 'another-filename' ],		# \n

	[  49,  1,  1,  801, 'another-filename' ],		# #line 900 yet-another-filename

	[  50,  1,  1,  900, 'yet-another-filename' ],		# $f
	[  50,  3,  3,  900, 'yet-another-filename' ],		# \n

	[  51,  1,  1,  901, 'yet-another-filename' ],		# #line 1000"quoted-filename"

	[  52,  1,  1, 1000, 'quoted-filename' ],		# $g
	[  52,  3,  3, 1000, 'quoted-filename' ],		# \n

	[  53,  1,  1, 1001, 'quoted-filename' ],		# \n

	[  54,  1,  1, 1002, 'quoted-filename' ],		# =pod #line 1100 (not in column 1)

	[  59,  1,  1, 1007, 'quoted-filename' ],		# $h
	[  59,  3,  3, 1007, 'quoted-filename' ],		# \n

	[  60,  1,  1, 1008, 'quoted-filename' ],		# =pod #line 1200

	[  65,  1,  1, 1202, 'quoted-filename' ],		# $i
	[  65,  3,  3, 1202, 'quoted-filename' ],		# \n

	[  66,  1,  1, 1203, 'quoted-filename' ],		# =pod # line 1300

	[  71,  1,  1, 1302, 'quoted-filename' ],		# $j
	[  71,  3,  3, 1302, 'quoted-filename' ],		# \n

	#  No space between "line" and number causes it to not work.
	[  72,  1,  1, 1303, 'quoted-filename' ],		# =pod #line1400

	[  77,  1,  1, 1308, 'quoted-filename' ],		# $k
	[  77,  3,  3, 1308, 'quoted-filename' ],		# \n

	[  78,  1,  1, 1309, 'quoted-filename' ],		# =pod #line 1500 filename

	[  83,  1,  1, 1502, 'filename' ],		# $l
	[  83,  3,  3, 1502, 'filename' ],		# \n

	[  84,  1,  1, 1503, 'filename' ],		# =pod #line 1600another-filename

	[  89,  1,  1, 1602, 'another-filename' ],		# $m
	[  89,  3,  3, 1602, 'another-filename' ],		# \n

	[  90,  1,  1, 1603, 'another-filename' ],		# =pod #line 1700 yet-another-filename

	[  95,  1,  1, 1702, 'yet-another-filename' ],		# $n
	[  95,  3,  3, 1702, 'yet-another-filename' ],		# \n

	[  96,  1,  1, 1703, 'yet-another-filename' ],		# =pod #line 1800"quoted-filename"

	[ 101,  1,  1, 1802, 'quoted-filename' ],		# $o
	[ 101,  3,  3, 1802, 'quoted-filename' ],		# \n

	[ 102,  1,  1, 1803, 'quoted-filename' ],		# \n

	[ 103,  1,  1, 1804, 'quoted-filename' ],		# 1
	[ 103,  2,  2, 1804, 'quoted-filename' ],		# ;
	[ 103,  3,  3, 1804, 'quoted-filename' ],		# \n
);



#####################################################################
# Test the locations of everything in the test code

# Prepare
my $Document = PPI::Document->new( \$test_source );
isa_ok( $Document, 'PPI::Document' );
$Document->tab_width(4);
is($Document->tab_width, 4, 'Tab width set correctly');
ok( $Document->index_locations, '->index_locations returns true' );

# Now check the locations of every token
my @tokens = $Document->tokens;
is( scalar(@tokens), scalar(@test_locations), 'Number of tokens matches expected' );
foreach my $i ( 0 .. $#test_locations ) {
	my $location = $tokens[$i]->location;
	is( ref($location), 'ARRAY', "Token $i: ->location returns an ARRAY ref" );
	is( scalar(@$location), 5, "Token $i: ->location returns a 5 element ARRAY ref" );
	ok(
		(
				$location->[0] > 0
			and $location->[1] > 0
			and $location->[2] > 0
			and $location->[3] > 0
		),
		"Token $i: ->location returns four positive positions"
	);
	is_deeply(
		$tokens[$i]->location,
		$test_locations[$i],
		"Token $i: ->location matches expected",
	);
}

ok( $Document->flush_locations, '->flush_locations returns true' );
is( scalar(grep { defined $_->{_location} } $Document->tokens), 0, 'All _location attributes removed' );
