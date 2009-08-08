#!/usr/bin/perl

# Load ALL of the PPI files, lex them in, dump them
# out, and verify that the code goes in and out cleanly.

use strict;
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use Test::More; # Plan comes later
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use PPI;





#####################################################################
# Prepare

# Find all of the files to be checked
my %tests = map { $_ => $INC{$_} } grep { ! /\bXS\.pm/ } grep { /^PPI\b/ } keys %INC;
my @files = sort values %tests;
unless ( @files ) {
	Test::More::plan( tests => 2 );
	ok( undef, "Failed to find any files to test" );
	exit();
}

# Find all the testable perl files in t/data
foreach my $dir (
	'05_lexer',
	'07_token',
	'08_regression',
	'11_util',
	'13_data',
	'15_transform'
) {
	my @perl = find_files( catdir( 't', 'data', $dir ) );
	push @files, @perl;
}

# Add the test scripts themselves
push @files, find_files( 't' );

# Declare our plan
Test::More::plan( tests => 1 + scalar(@files) * 9 );





#####################################################################
# Run the Tests

foreach my $file ( @files ) {
	roundtrip_ok( $file );
}





#####################################################################
# Test Functions

sub roundtrip_ok {
	my $file = shift;
	local *FILE;
	my $rv = open( FILE, '<', $file );
	ok( $rv, "$file: Found file " );
	SKIP: {
		skip "No file to test", 7 unless $rv;
		my $source = do { local $/ = undef; <FILE> };
		close FILE;
		ok( length $source, "$file: Loaded cleanly" );
		$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;

		# Load the file as a Document
		SKIP: {
			skip( 'Ignoring 14_charset.t', 7 ) if $file =~ /14_charset/;

			my $Document = PPI::Document->new( $file );
			ok( $Document, "$file: ->new returned true" );
			isa_ok( $Document, 'PPI::Document' );

			# Serialize it back out, and compare with the raw version
			skip( "Ignoring failed parse of $file", 5 ) unless defined $Document;
			my $content = $Document->serialize;
			ok( length($content), "$file: PPI::Document serializes" );
			is( $content, $source, "$file: Round trip was successful" );

			# Are there any unknown things?
			is( $Document->find_any('Token::Unknown'), '',
				"$file: Contains no PPI::Token::Unknown elements" );
			is( $Document->find_any('Structure::Unknown'), '',
				"$file: Contains no PPI::Structure::Unknown elements" );
			is( $Document->find_any('Statement::Unknown'), '',
				"$file: Contains no PPI::Statement::Unknown elements" );
		}
	}	
}

# Find file names in named t/data dirs
sub find_files {
	my $testdir  = shift;
	
	# Does the test directory exist?
	-e $testdir and -d $testdir and -r $testdir or die "Failed to find test directory $testdir";
	
	# Find the .code test files
	opendir( TESTDIR, $testdir ) or die "opendir: $!";
	my @perl = map { catfile( $testdir, $_ ) } sort grep { /\.(?:code|pm|t)$/ } readdir(TESTDIR);
	closedir( TESTDIR ) or die "closedir: $!";
	return @perl;
}
