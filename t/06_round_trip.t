#!/usr/bin/perl -w

# Load ALL of the PPI files, lex them in, dump them
# out, and verify that the code goes in and out cleanly.

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
use Test::More; # Plan comes later






#####################################################################
# Prepare

# Find all of the files to be checked
my %tests = map { $_ => $INC{$_} } grep { ! /\bXS\.pm/ } grep { /^PPI\b/ } keys %INC;
unless ( %tests ) {
	Test::More::plan( tests => 1 );
	ok( undef, "Failed to find any files to test" );
	exit();
}
my @files = sort values %tests;

# Find all the testable perl files in t.data
foreach my $dir ( '05_lexer_practical', '08_regression', '11_util', '13_data', '15_transform' ) {
	my @perl = find_files( $dir );
	push @files, @perl;
}

# Declare our plan
Test::More::plan( tests => scalar(@files) * 8 );





#####################################################################
# Run the Tests

foreach my $file ( @files ) {
	roundtrip_ok( $file );
}





#####################################################################
# Test Functions

sub roundtrip_ok {
	my $file = shift;
	my $rv   = open( FILE, '<', $file );
	ok( $rv, "$file: Found file " );
	SKIP: {
		skip "No file to test", 7 unless $rv;
		my $source = do { local $/ = undef; <FILE> };
		close FILE;
		ok( length $source, "$file: Loaded cleanly" );
		$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;

		# Load the file as a Document
		my $Document = PPI::Document->new( $file );
		ok( isa(ref $Document, 'PPI::Document' ), "$file: PPI::Document object created" );

		# Serialize it back out, and compare with the raw version
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

# Find file names in named t.data dirs
sub find_files {
	my $dir  = shift;
	my $testdir = catdir( 't.data', $dir );
	
	# Does the test directory exist?
	-e $testdir and -d $testdir and -r $testdir or die "Failed to find test directory $testdir";
	
	# Find the .code test files
	opendir( TESTDIR, $testdir ) or die "opendir: $!";
	my @perl = map { catfile( $testdir, $_ ) } sort grep { /\.(?:code|pm)$/ } readdir(TESTDIR);
	closedir( TESTDIR ) or die "closedir: $!";
	return @perl;
}

1;
