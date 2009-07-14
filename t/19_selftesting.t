#!/usr/bin/perl

# Load ALL of the PPI files, and look for a collection
# of known problems, implemented using PPI itself.

# Using PPI to analyse its own code at install-time? Fuck yeah! :)

use strict;
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}

use Test::More; # Plan comes later
use Test::NoWarnings;
use Test::Object;
use File::Spec::Functions ':ALL';
use Params::Util qw{_CLASS _ARRAY _INSTANCE _IDENTIFIER};
use Class::Inspector;
use PPI;
use t::lib::PPI;

use constant CI => 'Class::Inspector';





#####################################################################
# Prepare

# Find all of the files to be checked
my %tests = map { $_ => $INC{$_} } grep { ! /\bXS\.pm/ } grep { /^PPI\b/ } keys %INC;
unless ( %tests ) {
	Test::More::plan( tests => 2 );
	ok( undef, "Failed to find any files to test" );
	exit();
}
my @files = sort values %tests;

# Find all the testable perl files in t/data
foreach my $dir ( '05_lexer', '08_regression', '11_util', '13_data', '15_transform' ) {
	my @perl = find_files( $dir );
	push @files, @perl;
}

# Declare our plan
Test::More::plan( tests => scalar(@files) * 13 + 4 );





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
	# MD5 the raw file
	my $md5a = PPI::Util::md5hex_file($file);
	like( $md5a, qr/^[0-9a-f]{32}\z/, 'md5hex_file ok' );

	# Load the file
	my $Document = PPI::Document->new($file);
	ok( _INSTANCE($Document, 'PPI::Document'), "$file: Parsed ok" );

	# Compare the preload signature to the post-load value
	my $md5b = $Document->hex_id;
	is( $md5b, $md5a, '->hex_id matches md5hex' );

	# By this point, everything should have parsed properly at least
	# once, so no need to skip.
	SCOPE: {
		my $rv = $Document->find( \&bug_bad_isa_class_name );
		if ( $rv ) {
			$Document->index_locations;
			foreach ( @$rv ) {
				print "# $file: Found bad class "
					. $_->content
					. "\n";
			}
		}
		is_deeply( $rv, '', "$file: All class names in ->isa calls exist" );
	}
	SCOPE: {
		my $rv = $Document->find( \&bad_static_method );
		if ( $rv ) {
			$Document->index_locations;
			foreach ( @$rv ) {
				my $c = $_->sprevious_sibling->content;
				my $m = $_->snext_sibling->content;
				my $l = $_->location;
				print "# $file: Found bad call ${c}->${m} at line $l->[0], col $l->[1]\n";
			}
		}
		is_deeply( $rv, '', "$file: All class names in static method calls" );
	}

	# Test with Test::Object stuff
	object_ok( $Document );
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
	$Word->content =~ /^(?:UNIVERSAL::)?isa\z/s    or return '';

	# Is the class real and loaded?
	CI->loaded($Element->string)                  and return '';

	# Looks like we found a class that doesn't exist in
	# an isa call.
	return 1;
}

# Check for the use of a method that doesn't exist
sub bad_static_method {
	my ($document, $element) = @_;

	# Find a quote containing a class name
	$element->isa('PPI::Token::Operator')   or return '';
	$element->content eq '->'               or return '';

	# Check the method
	my $method = $element->snext_sibling    or return '';
	$method->isa('PPI::Token::Word')        or return '';
	_IDENTIFIER($method->content)           or return '';

	# Check the class
	my $class = $element->sprevious_sibling or return '';
	$class->isa('PPI::Token::Word')         or return '';
	_CLASS($class->content)                 or return '';

	# It's usually a deep class
	$class  = $class->content;
	$method = $method->content;
	$class =~ /::/                          or return '';

	# Check the method exists
	$class->can($method)                   and return '';

	return 1;
}

1;
