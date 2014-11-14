#!/usr/bin/perl

use t::lib::PPI::Test::pragmas;
use Test::More 0.86 tests => 24;

use File::Spec::Functions ':ALL';
use File::Remove;
use PPI;
use PPI::Transform;
use Scalar::Util 'refaddr';
use File::Copy;

# Files to clean up
my @cleanup;
END {
	foreach ( @cleanup ) {
		File::Remove::remove( \1, $_ );
	}
}





#####################################################################
# Begin Tests

APPLY: {
	my $code = 'my $foo = "bar";';

	my $rv = MyCleaner->apply( \$code );
	ok( $rv, 'MyCleaner->apply( \$code ) returns true' );
	is( $code, 'my$foo="bar";', 'MyCleaner->apply( \$code ) modifies code as expected' );

	ok(
		PPI::Transform->register_apply_handler( 'Foo', \&Foo::get, \&Foo::set ),
		"register_apply_handler worked",
	);
	$Foo::VALUE = 'my $foo = "bar";';
	my $Foo = Foo->new;
	isa_ok( $Foo, 'Foo' );
	ok( MyCleaner->apply( $Foo ), 'MyCleaner->apply( $Foo ) returns true' );
	is( $Foo::VALUE, 'my$foo="bar";', 'MyCleaner->apply( $Foo ) modifies code as expected' );
}





#####################################################################
# File transforms

my $testdir = catdir( 't', 'data', '15_transform');

# Does the test directory exist?
ok( (-e $testdir and -d $testdir and -r $testdir), "Test directory $testdir found" );

# Find the .pm test files
opendir( TESTDIR, $testdir ) or die "opendir: $!";
my @files = map { catfile( $testdir, $_ ) } sort grep { /\.pm$/ } readdir(TESTDIR);
closedir( TESTDIR ) or die "closedir: $!";
ok( scalar @files, 'Found at least one .pm file' );





#####################################################################
# Testing

foreach my $input ( @files ) {
	# Prepare
	my $output = "${input}_out";
	my $copy   = "${input}_copy";
	my $copy2  = "${input}_copy2";
	push @cleanup, $copy;
	push @cleanup, $copy2;
	ok( copy( $input, $copy ), "Copied $input to $copy" );

	my $Original = new_ok( 'PPI::Document' => [ $input  ] );
	my $Input    = new_ok( 'PPI::Document' => [ $input  ] );
	my $Output   = new_ok( 'PPI::Document' => [ $output ] );

	# Process the file
	my $rv = MyCleaner->document( $Input );
	isa_ok( $rv, 'PPI::Document' );
	is( refaddr($rv), refaddr($Input), '->document returns original document' );
	is_deeply( $Input, $Output, 'Transform works as expected' );

	# Squish to another location
	ok( MyCleaner->file( $copy, $copy2 ), '->file returned true' );
	my $Copy  = new_ok( 'PPI::Document' => [ $copy ] );
	is_deeply( $Copy, $Original, 'targeted transform leaves original unchanged' );
	my $Copy2 = new_ok( 'PPI::Document' => [ $copy2 ] );
	is_deeply( $Copy2, $Output, 'targeted transform works as expected' );

	# Copy the file and process in-place
	ok( MyCleaner->file( $copy ), '->file returned true' );
	$Copy = new_ok( 'PPI::Document' => [ $copy ] );
	is_deeply( $Copy, $Output, 'In-place transform works as expected' );
}





#####################################################################
# Support Code

# Test Transform class
package MyCleaner;

use Params::Util   qw{_INSTANCE};
use PPI::Transform ();

use vars qw{@ISA};
BEGIN {
	@ISA = 'PPI::Transform';
}

sub document {
	my $self     = shift;
	my $Document = _INSTANCE(shift, 'PPI::Document') or return undef;
	$Document->prune( 'Token::Whitespace' );
	$Document;
}

package Foo;

sub new {
	bless { }, 'Foo';
}

use vars qw{$VALUE};
BEGIN {
	$VALUE = '';
}

sub get {
	PPI::Document->new( \$VALUE );
}

sub set {
	$VALUE = $_[1]->serialize;
}
