#!/usr/bin/perl -w

# Exhaustively test all possible Perl programs to a particular length

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

# Load the code to test
BEGIN { $PPI::XS_DISABLE = 1 }
use PPI;
use Carp 'croak';

use vars qw{$MAX_CHARS $ITERATIONS $LENGTH @ALL_CHARS};
BEGIN {
	# When distributing, keep this in to verify the test script
	# is working correctly, but limit to 2 (maaaaybe 3) so we
	# don't slow the install process down too much.
	$MAX_CHARS  = 2;
	$ITERATIONS = 1000;
	$LENGTH     = 190;
	@ALL_CHARS  = (
		qw{a b c f g m q r s t w x y z V W X 0 1 8 9},
		';', '[', ']', '{', '}', '(', ')', '=', '?', '|', '+', '<',
		'>', '.', '!', '~', '^', '*', '$', '@', '&', ':', '%', ',',
		'\\', '/', '_', ' ', "\n", "\t", '-',
		 "'", '"', '`', '#', # Comment out to make parsing more intense
		);
	#my @ALL_CHARS = (
	#	qw{a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H
	#	I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9},
	#	';', '[', ']', '{', '}', '(', ')', '=', '?', '|', '+', '<', '>', '.',
	#	'!', '~', '^', '*', '$', '@', '&', ':', '%', '#', ',', "'", '"', '`',
	#	'\\', '/', '_', ' ', "\n", "\t", '-',
	#	);
}





#####################################################################
# Prepare

use Test::More tests => ($MAX_CHARS + $ITERATIONS + 1);





#####################################################################
# Code/Dump Testing

my $failures   = 0;
my $last_index = scalar(@ALL_CHARS) - 1;
LENGTHLOOP:
foreach my $len ( 1 .. $MAX_CHARS ) {
	# Initialise the char array and failure count
	my $failures = 0;
	my @chars    = (0) x $len;

	# The main test loop
	CHARLOOP:
	while ( 1 ) {
		# Test the current set of chars
		my $code = join '', map { $ALL_CHARS[$_] } @chars;
		unless ( length($code) == $len ) {
			die "Failed sanity check. Error in the code generation mechanism";
		}
		test_code( $code );

		# Increment the last character
		$chars[$len - 1]++;

		# Cascade the wrapping as needed
		foreach ( reverse( 0 .. $len - 1 ) ) {
			next CHARLOOP unless $chars[$_] > $last_index;
			if ( $_ == 0 ) {
				# End of the iterations, move to the next length
				last CHARLOOP;
			}

			# Carry to the previous char
			$chars[$_] = 0;
			$chars[$_ - 1]++;
		}
	}
	is( $failures, 0, "No tokenizer failures for all $len-length programs" );
}





#####################################################################
# Test a series of random strings

my $count = 0;
foreach my $i ( 1 .. $ITERATIONS ) {
	# Generate a random string
	my $code = join( '',
		map { $ALL_CHARS[$_] }
		map { int(rand($last_index) + 1) }
		(1 .. $LENGTH)
		);

	# Test it as normal
	test_code2( $code );

	# Verify there are no stale %PARENT entries
	#my $quotable = quotable($code);
	#is( scalar(keys %PPI::Element::PARENT), 0,
	#	"%PARENT is clean \"$quotable\"" );
}

is( scalar(keys %PPI::Element::PARENT), 0,
	'No stale \%PARENT entries at the end of testing' );
%PPI::Element::PARENT = %PPI::Element::PARENT;




#####################################################################
# Support Functions

sub test_code2 {
	$failures    = 0;
	my $string   = shift;
	my $quotable = quotable($string);
	test_code( $string );
	is( $failures, 0, "String parses ok \"$quotable\"" );	
}

sub test_code {
	my $code      = shift;
	my $Document  = eval {
		# $SIG{__WARN__} = sub { croak('Triggered a warning') };
		PPI::Document->new(\$code);
	};

	# Version of the code for use in error messages
	my $quotable = quotable($code);
	if ( $PPI::Tokenizer::errstr ) {
		$failures++;
		diag( "\"$quotable\": Tokenizer returned an error" );
		my $short = quotable(quickcheck($code));
		diag( "Shortest failing substring: \"$short\"" );
		return;
	}
	unless ( isa($Document, 'PPI::Document') ) {
		$failures++;
		diag( "\"$quotable\": Parser did not return a Document" );
		return;
	}
	my $joined          = $Document->serialize;
	my $joined_quotable = quotable($joined);
	unless ( $joined eq $code ) {
		$failures++;
		diag( "\"$quotable\": Document round-trips ok" );
		diag( "\"$joined_quotable\" (round-trips to)" );
		return;
	}
}

# Find the shortest failing substring of known bad string
sub quickcheck {
	my $code       = shift;
	my $fails      = $code;
	# $SIG{__WARN__} = sub { croak('Triggered a warning') };

	while ( length $fails ) {
		chop $code;
		my $Document = PPI::Document->new(\$code) or last;
		$fails = $code;
	}

	while ( length $fails ) {
		substr( $code, 0, 1, '' );
		my $Document = PPI::Document->new(\$code) or return $fails;
		$fails = $code;
	}

	return $fails;
}

sub quotable {
	my $quotable = shift;
	$quotable =~ s/\\/\\\\/g;
	$quotable =~ s/\t/\\t/g;
	$quotable =~ s/\n/\\n/g;
	$quotable =~ s/\$/\\\$/g;
	$quotable =~ s/\@/\\\@/g;
	$quotable =~ s/\"/\\\"/g;
	return $quotable;
}

exit(0);
