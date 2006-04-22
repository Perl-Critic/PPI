#!/usr/bin/perl -w

# Tests the accuracy and features for location functionality

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

# Load the code to test
BEGIN { $PPI::XS_DISABLE = 1 }
use PPI;

# Execute the tests
use Test::More tests => 490;

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
    print "fluzz";
}

1;
END_PERL
my @test_locations = (
	[  1,  1,  1 ],		# my
	[  1,  3,  3 ],		# ' '
	[  1,  4,  4 ], 	# $foo
	[  1,  8,  8 ],     # ' '
	[  1,  9,  9 ],		# =
	[  1, 10, 10 ],		# ' '
	[  1, 11, 11 ],		# 'bar'
	[  1, 16, 16 ],		# ;
	[  1, 17, 17 ],		# \n

	[  2,  1,  1 ],		# \n

	[  3,  1,  1 ],		# # comment

	[  4,  1,  1 ],		# sub
	[  4,  4,  4 ],		# ' '
	[  4,  5,  5 ],		# foo
	[  4,  8,  8 ],		# ' '
	[  4,  9,  9 ],     # {
	[  4, 10, 10 ],		# \n

	[  5,  1,  1 ],		# '    '
	[  5,  5,  5 ],		# my
	[  5,  7,  7 ],     # ' '
	[  5,  8,  8 ],		# (
	[  5,  9,  9 ],		# $this
	[  5, 14, 14 ],     # ,
	[  5, 15, 15 ],     # ' '
	[  5, 16, 16 ],		# $that
	[  5, 21, 21 ],		# )
	[  5, 22, 22 ],		# ' '
	[  5, 23, 23 ],		# =
	[  5, 24, 24 ], 	# ' '
	[  5, 25, 25 ],		# (
	[  5, 26, 26 ],		# <<'THIS'
	[  5, 34, 34 ],		# ,
	[  5, 35, 35 ],		# ' '
	[  5, 36, 36 ],		# <<"THAT"
	[  5, 44, 44 ],		# )
	[  5, 45, 45 ],		# ;
	[  5, 46, 46 ],		# \n

	[ 13,  1,  1 ],		# }
	[ 13,  2,  2 ],		# \n

	[ 14,  1,  1 ],		# \n

	[ 15,  1,  1 ],     # sub
	[ 15,  4,  4 ],		# ' '
	[ 15,  5,  5 ],		# baz
	[ 15,  8,  8 ],		# ' '
	[ 15,  9,  9 ],		# {
	[ 15, 10, 10 ],		# \n

	[ 16,  1,  1 ],		# tab# sub baz contains *tabs*
	[ 17,  1,  1 ],		# tab
	[ 17,  2,  5 ],		# my
	[ 17,  4,  7 ],		# ' '
	[ 17,  5,  8 ],		# (
	[ 17,  6,  9 ],		# $one
	[ 17, 10, 13 ],		# ,
	[ 17, 11, 14 ],		# ' '
	[ 17, 12, 15 ],		# $other 
	[ 17, 18, 21 ],		# )
	[ 17, 19, 22 ],		# ' '
	[ 17, 20, 23 ],		# =
	[ 17, 21, 24 ],		# ' tab'
	[ 17, 23, 29 ],		# (
	[ 17, 24, 30 ],		# "one"
	[ 17, 29, 35 ],		# ,
	[ 17, 30, 36 ],		# tab 
	[ 17, 31, 37 ],		# "other"
	[ 17, 38, 44 ],		# )
	[ 17, 39, 45 ],		# ;
	[ 17, 40, 46 ],		# tab
	[ 17, 41, 49 ],		# # contains 3 tabs
	[ 17, 58, 66 ],		# \n

	[ 18,  1,  1 ],		# \n\t

	[ 19,  2,  5 ],		# foo
	[ 19,  5,  8 ],		# (
	[ 19,  6,  9 ],		# )
	[ 19,  7, 10 ],		# tab
	[ 19,  8, 13 ],		# ;
	[ 19,  9, 14 ],		# \n

	[ 20,  1,  1 ],		# {
	[ 20,  2,  2 ],		# \n

	[ 21,  1,  1 ],		# \n

	[ 22,  1,  1 ],		# sub
	[ 22,  4,  4 ],		# ' '
	[ 22,  5,  5 ],		# bar
	[ 22,  8,  8 ],		# ' '
	[ 22,  9,  9 ],		# {
	[ 22, 10, 10 ],		# \n

	[ 23,  1,  1 ],     # '    '
	[ 23,  5,  5 ],		# baz
	[ 23,  8,  8 ],		# (
	[ 23,  9,  9 ],		# )
	[ 23, 10, 10 ],		# ;
	[ 23, 11, 11 ],		# \n

	[ 24,  1,  1 ],		# \n

	[ 25,  1,  1 ],		# #Note that there are leading 4 x space, ...

	[ 26,  1,  1 ],		# '\n    '

	[ 27,  5,  5 ],		# bas
	[ 27,  8,  8 ],		# (
	[ 27,  9,  9 ],		# )
	[ 27, 10, 10 ],		# ;
	[ 27, 11, 11 ],		# \n

	[ 28,  1,  1 ],		# }
	[ 28,  2,  2 ],		# \n

	[ 29,  1,  1 ],		# \n

	[ 30,  1,  1 ],		# =head2 fluzz() ...

	[ 35,  1,  1 ],		# sub
	[ 35,  4,  4 ],		# ' '
	[ 35,  5,  5 ],		# fluzz
	[ 35, 10, 10 ],		# ' '
	[ 35, 11, 11 ],		# {
	[ 35, 12, 12 ],		# \n

	[ 36,  1,  1 ],		# '    '
	[ 36,  5,  5 ],		# print
	[ 36, 10, 10 ],		# ' '
	[ 36, 11, 11 ],		# "fluzz"
	[ 36, 18, 18 ],		# ;
	[ 36, 19, 19 ],		# \n

	[ 37,  1,  1 ],		# }
	[ 37,  2,  2 ],		# \n

	[ 38,  1,  1 ],		# \n

	[ 39,  1,  1 ],		# 1
	[ 39,  2,  2 ],		# ;
	[ 39,  3,  3 ],		# \n
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
	is( scalar(@$location), 3, "Token $i: ->location returns a 3 element ARRAY ref" );
	ok( ($location->[0] > 0 and $location->[1] > 0 and $location->[2] > 0), "Token $i: ->location returns three positive positions" );
	is_deeply( $tokens[$i]->location, $test_locations[$i], "Token $i: ->location matches expected" );
}

ok( $Document->flush_locations, '->flush_locations returns true' );
is( scalar(grep { defined $_->{_location} } $Document->tokens), 0, 'All _location attributes removed' );

1;
