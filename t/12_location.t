#!/usr/bin/perl

# Tests the accuracy and features for location functionality

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;

# Execute the tests
use Test::More tests => 570;

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
#line 800filename
$e
#line 900 other_filename
$f

1;
END_PERL
my @test_locations = (
	[  1,  1,  1,   1 ],		# my
	[  1,  3,  3,   1 ],		# ' '
	[  1,  4,  4,   1 ],		# $foo
	[  1,  8,  8,   1 ],		# ' '
	[  1,  9,  9,   1 ],		# =
	[  1, 10, 10,   1 ],		# ' '
	[  1, 11, 11,   1 ],		# 'bar'
	[  1, 16, 16,   1 ],		# ;
	[  1, 17, 17,   1 ],		# \n

	[  2,  1,  1,   2 ],		# \n

	[  3,  1,  1,   3 ],		# # comment

	[  4,  1,  1,   4 ],		# sub
	[  4,  4,  4,   4 ],		# ' '
	[  4,  5,  5,   4 ],		# foo
	[  4,  8,  8,   4 ],		# ' '
	[  4,  9,  9,   4 ],		# {
	[  4, 10, 10,   4 ],		# \n

	[  5,  1,  1,   5 ],		# '    '
	[  5,  5,  5,   5 ],		# my
	[  5,  7,  7,   5 ],		# ' '
	[  5,  8,  8,   5 ],		# (
	[  5,  9,  9,   5 ],		# $this
	[  5, 14, 14,   5 ],		# ,
	[  5, 15, 15,   5 ],		# ' '
	[  5, 16, 16,   5 ],		# $that
	[  5, 21, 21,   5 ],		# )
	[  5, 22, 22,   5 ],		# ' '
	[  5, 23, 23,   5 ],		# =
	[  5, 24, 24,   5 ], 	# ' '
	[  5, 25, 25,   5 ],		# (
	[  5, 26, 26,   5 ],		# <<'THIS'
	[  5, 34, 34,   5 ],		# ,
	[  5, 35, 35,   5 ],		# ' '
	[  5, 36, 36,   5 ],		# <<"THAT"
	[  5, 44, 44,   5 ],		# )
	[  5, 45, 45,   5 ],		# ;
	[  5, 46, 46,   5 ],		# \n

	[ 13,  1,  1,  13 ],		# }
	[ 13,  2,  2,  13 ],		# \n

	[ 14,  1,  1,  14 ],		# \n

	[ 15,  1,  1,  15 ],		# sub
	[ 15,  4,  4,  15 ],		# ' '
	[ 15,  5,  5,  15 ],		# baz
	[ 15,  8,  8,  15 ],		# ' '
	[ 15,  9,  9,  15 ],		# {
	[ 15, 10, 10,  15 ],		# \n

	[ 16,  1,  1,  16 ],		# tab# sub baz contains *tabs*
	[ 17,  1,  1,  17 ],		# tab
	[ 17,  2,  5,  17 ],		# my
	[ 17,  4,  7,  17 ],		# ' '
	[ 17,  5,  8,  17 ],		# (
	[ 17,  6,  9,  17 ],		# $one
	[ 17, 10, 13,  17 ],		# ,
	[ 17, 11, 14,  17 ],		# ' '
	[ 17, 12, 15,  17 ],		# $other 
	[ 17, 18, 21,  17 ],		# )
	[ 17, 19, 22,  17 ],		# ' '
	[ 17, 20, 23,  17 ],		# =
	[ 17, 21, 24,  17 ],		# ' tab'
	[ 17, 23, 29,  17 ],		# (
	[ 17, 24, 30,  17 ],		# "one"
	[ 17, 29, 35,  17 ],		# ,
	[ 17, 30, 36,  17 ],		# tab 
	[ 17, 31, 37,  17 ],		# "other"
	[ 17, 38, 44,  17 ],		# )
	[ 17, 39, 45,  17 ],		# ;
	[ 17, 40, 46,  17 ],		# tab
	[ 17, 41, 49,  17 ],		# # contains 3 tabs
	[ 17, 58, 66,  17 ],		# \n

	[ 18,  1,  1,  18 ],		# \n\t

	[ 19,  2,  5,  19 ],		# foo
	[ 19,  5,  8,  19 ],		# (
	[ 19,  6,  9,  19 ],		# )
	[ 19,  7, 10,  19 ],		# tab
	[ 19,  8, 13,  19 ],		# ;
	[ 19,  9, 14,  19 ],		# \n

	[ 20,  1,  1,  20 ],		# {
	[ 20,  2,  2,  20 ],		# \n

	[ 21,  1,  1,  21 ],		# \n

	[ 22,  1,  1,  22 ],		# sub
	[ 22,  4,  4,  22 ],		# ' '
	[ 22,  5,  5,  22 ],		# bar
	[ 22,  8,  8,  22 ],		# ' '
	[ 22,  9,  9,  22 ],		# {
	[ 22, 10, 10,  22 ],		# \n

	[ 23,  1,  1,  23 ],		# '    '
	[ 23,  5,  5,  23 ],		# baz
	[ 23,  8,  8,  23 ],		# (
	[ 23,  9,  9,  23 ],		# )
	[ 23, 10, 10,  23 ],		# ;
	[ 23, 11, 11,  23 ],		# \n

	[ 24,  1,  1,  24 ],		# \n

	[ 25,  1,  1,  25 ],		# #Note that there are leading 4 x space, ...

	[ 26,  1,  1,  26 ],		# '\n    '

	[ 27,  5,  5,  27 ],		# bas
	[ 27,  8,  8,  27 ],		# (
	[ 27,  9,  9,  27 ],		# )
	[ 27, 10, 10,  27 ],		# ;
	[ 27, 11, 11,  27 ],		# \n

	[ 28,  1,  1,  28 ],		# }
	[ 28,  2,  2,  28 ],		# \n

	[ 29,  1,  1,  29 ],		# \n

	[ 30,  1,  1,  30 ],		# fluzz() ...

	[ 35,  1,  1,  35 ],		# sub
	[ 35,  4,  4,  35 ],		# ' '
	[ 35,  5,  5,  35 ],		# fluzz
	[ 35, 10, 10,  35 ],		# ' '
	[ 35, 11, 11,  35 ],		# {
	[ 35, 12, 12,  35 ],		# \n

	[ 36,  1,  1,  36 ],		# '    '
	[ 36,  5,  5,  36 ],		# print
	[ 36, 10, 10,  36 ],		# ' '
	[ 36, 11, 11,  36 ],		# "fluzz"
	[ 36, 18, 18,  36 ],		# ;
	[ 36, 19, 19,  36 ],		# # line 300 not_at_start_of_line
	[ 36, 50, 50,  36 ],		# \n

	[ 37,  1,  1,  37 ],		# }
	[ 37,  2,  2,  37 ],		# \n

	[ 38,  1,  1,  38 ],		# \n

	[ 39,  1,  1,  39 ],		# #line 400

	[ 40,  1,  1, 400 ],		# $a
	[ 40,  3,  3, 400 ],		# \n

	[ 41,  1,  1, 401 ],		# # line 500

	[ 42,  1,  1, 500 ],		# $b
	[ 42,  3,  3, 500 ],		# \n

	# No space between "line" and number causes it to not work.
	[ 43,  1,  1, 501 ],		# #line600

	[ 44,  1,  1, 502 ],		# $c
	[ 44,  3,  3, 502 ],		# \n

	[ 45,  1,  1, 503 ],		# #line 700 filename

	[ 46,  1,  1, 700 ],		# $d
	[ 46,  3,  3, 700 ],		# \n

	[ 47,  1,  1, 701 ],		# #line 800filename

	[ 48,  1,  1, 800 ],		# $e
	[ 48,  3,  3, 800 ],		# \n

	[ 49,  1,  1, 801 ],		# #line 900 other_filename

	[ 50,  1,  1, 900 ],		# $f
	[ 50,  3,  3, 900 ],		# \n

	[ 51,  1,  1, 901 ],		# \n

	[ 52,  1,  1, 902 ],		# 1
	[ 52,  2,  2, 902 ],		# ;
	[ 52,  3,  3, 902 ],		# \n
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
	is( scalar(@$location), 4, "Token $i: ->location returns a 4 element ARRAY ref" );
	ok(
		($location->[0] > 0 and $location->[1] > 0 and $location->[2] > 0 and $location->[3] > 0),
		"Token $i: ->location returns four positive positions"
	);
	is_deeply( $tokens[$i]->location, $test_locations[$i], "Token $i: ->location matches expected" );
}

ok( $Document->flush_locations, '->flush_locations returns true' );
is( scalar(grep { defined $_->{_location} } $Document->tokens), 0, 'All _location attributes removed' );
