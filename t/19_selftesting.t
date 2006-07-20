#!/usr/bin/perl -w

# Load ALL of the PPI files, and look for a collection
# of known problems, implemented using PPI itself.

# Using PPI to analyse it's own code at install-time? Fuck yeah! :)

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;
use Class::Inspector;
use constant CI => 'Class::Inspector';
use Params::Util '_CLASS', '_ARRAY', '_INSTANCE';
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

# Find all the testable perl files in t/data
foreach my $dir ( '05_lexer_practical', '08_regression', '11_util', '13_data', '15_transform' ) {
	my @perl = find_files( $dir );
	push @files, @perl;
}

# Declare our plan
Test::More::plan( tests => scalar(@files) * 2 + 3 );





#####################################################################
# Self-test the search functions before we use them

# Check this actually finds something bad
my $sample = PPI::Document->new(\<<'END_PERL');
isa($foo, 'Bad::Class1');
isa($foo, 'PPI::Document');
$foo->isa('Bad::Class2');
$foo->isa("Bad::Class3");
isa($foo, 'ARRAY'); # Not bad
isa($foo->thing, qq <Bad::Class4> # ok?
);
END_PERL
isa_ok( $sample, 'PPI::Document' );

my $bad = $sample->find( \&bug_bad_isa_class_name );
ok( _ARRAY($bad), 'Found bad things' );
@$bad = map { $_->string } @$bad;
is_deeply( $bad, [ 'Bad::Class1', 'Bad::Class2', 'Bad::Class3', 'Bad::Class4' ],
	'Found all found known bad things' );





#####################################################################
# Run the Tests

foreach my $file ( @files ) {
	my $Document = PPI::Document->new($file);
	ok( _INSTANCE($Document, 'PPI::Document'), "$file: Parsed ok" );

	# By this point, everything should have parsed properly at least
	# once, so no need to skip.
	my $rv = $Document->find( \&bug_bad_isa_class_name );
	if ( $rv ) {
		foreach ( @$rv ) {
			print "# $file: Found bad class "
				. $_->string
				. "\n";
		}
	}
	is_deeply( $rv, '', "$file: All class names in ->isa calls exist" );
}





#####################################################################
# Test Functions

# Find file names in named t/data dirs
sub find_files {
	my $dir  = shift;
	my $testdir = catdir( 't', 'data', $dir );
	
	# Does the test directory exist?
	-e $testdir and -d $testdir and -r $testdir or die "Failed to find test directory $testdir";
	
	# Find the .code test files
	opendir( TESTDIR, $testdir ) or die "opendir: $!";
	my @perl = map { catfile( $testdir, $_ ) } sort grep { /\.(?:code|pm)$/ } readdir(TESTDIR);
	closedir( TESTDIR ) or die "closedir: $!";
	return @perl;
}

# Check for accidental use of illegal or non-existant classes in
# ->isa calls. This has happened at least once, presumably because
# PPI has a LOT of classes and it can get confusing.
sub bug_bad_isa_class_name {
	my ($Document, $Element) = @_;

	# Find a quote containing a class name
	$Element->isa('PPI::Token::Quote')             or return '';
	_CLASS($Element->string)                       or return '';
	if ( $Element->string =~ /^(?:ARRAY|HASH|CODE|SCALAR|REF|GLOB)$/ ) {
		return '';
	}

	# It should be the last thing in an expression in a list
	my $Expression = $Element->parent              or return '';
	$Expression->isa('PPI::Statement::Expression') or return '';
	$Element == $Expression->schild(-1)            or return '';

	my $List = $Expression->parent                 or return '';
	$List->isa('PPI::Structure::List')             or return '';
	$List->schildren == 1                          or return '';

	# The list should be the params list for an isa call
	my $Word = $List->sprevious_sibling            or return '';
	$Word->isa('PPI::Token::Word')                 or return '';
	$Word->content =~ /^(?:UNIVERSAL::)?isa$/s     or return '';

	# Is the class real and loaded?
	CI->loaded($Element->string)                  and return '';

	# Looks like we found a class that doesn't exist in
	# an isa call.
	return 1;
}

1;
