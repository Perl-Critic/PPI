#!/usr/bin/perl

# code/dump-style regression tests for known lexing problems.

# Some other regressions tests are included here for simplicity.

use strict;
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}

use File::Spec::Functions ':ALL';

use PPI::Lexer;
use PPI::Dumper;
use Carp 'croak';
use Params::Util qw{_INSTANCE};

sub pause {
	local $@;
	eval { require Time::HiRes; };
	$@ ? sleep(1) : Time::HiRes::sleep(0.1);
}





#####################################################################
# Prepare

use vars qw{@FAILURES};
BEGIN {
	@FAILURES = (
		# Failed cases 3 chars or less
		'!%:', '!%:',  '!%:',  '!%:',  '!*:', '!@:',  '%:',  '%:,',
		'%:;', '*:',   '*:,',  '*::',  '*:;', '+%:',  '+*:', '+@:',
		'-%:', '-*:',  '-@:',  ';%:',  ';*:', ';@:',  '@:',  '@:,',
		'@::', '@:;',  '\%:',  '\&:',  '\*:', '\@:',  '~%:', '~*:',
		'~@:', '(<',   '(<',   '=<',   'm(',  'm(',   'm<',  'm[',
		'm{',  'q(',   'q<',   'q[',   'q{',  's(',   's<',  's[',
		's{',  'y(',   'y<',   'y[',   'y{',  '$\'0', '009', '0bB',
		'0xX', '009;', '0bB;', '0xX;', "<<'", '<<"',  '<<`', '&::',
		'<<a', '<<V',  '<<s',  '<<y',  '<<_',

		# Failed cases 4 chars long.
		# This isn't the complete set, as they tend to fail in groups
		# of 50 or so, but I've used a representative sample.
		'm;;_', 'm[]_', 'm]]_', 'm{}_', 'm}}_', 'm--_', 's[]a', 's[]b',
		's[]0', 's[];', 's[]]', 's[]=', 's[].', 's[]_', 's{}]', 's{}?',
		's<>s', 's<>-',
		'*::0', '*::1', '*:::', '*::\'', '$::0',  '$:::', '$::\'',
		'@::0', '@::1', '@:::', '&::0',  '&::\'', '%:::', '%::\'',

		# More-specific single cases thrown up during the heavy testing
		'$:::z', '*:::z', "\\\@::'9:!", "} mz}~<<ts", "<\@<<q-r8\n/",
		"W<<s`[\n(", "X<<f+X;g(<~\" \n1\n*", "c<<t* 9\ns\n~^{s ",
		"<<V=-<<Wt", "[<<g/.<<r>\nV"
		);
}

use Test::More tests => 1 + scalar(@FAILURES) * 3;
use Test::NoWarnings;





#####################################################################
# Code/Dump Testing

foreach my $code ( @FAILURES ) {
	test_code( $code );

	# Verify there are no stale %PARENT entries
	my $quotable = quotable($code);
	is( scalar(keys %PPI::Element::PARENT), 0,
		"\"$quotable\": No stale %PARENT entries" );
	%PPI::Element::PARENT = %PPI::Element::PARENT;
}

exit(0);





#####################################################################
# Support Functions

my $failures = 0;

sub test_code {
	my $code     = shift;
	my $quotable = quotable($code);
	my $Document = eval {
		# $SIG{__WARN__} = sub { croak('Triggered a warning') };
		PPI::Document->new(\$code);
	};
	ok( _INSTANCE($Document, 'PPI::Document'),
		"\"$quotable\": Document parses ok" );
	unless ( _INSTANCE($Document, 'PPI::Document') ) {
		diag( "\"$quotable\": Parsing failed" );
		my $short = quotable(quickcheck($code));
		diag( "Shortest failing substring: \"$short\"" );
		return;		
	}

	# Version of the code for use in error messages
	my $joined          = $Document->serialize;
	my $joined_quotable = quotable($joined);
	is( $joined, $code,
		"\"$quotable\": Document round-trips ok: \"$joined_quotable\"" );
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
	return $quotable;
}
