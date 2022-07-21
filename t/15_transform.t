#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;

use File::Copy qw( copy );
use File::Spec::Functions qw( catdir catfile );
use File::Temp qw( tempdir );
use PPI ();
use PPI::Transform ();
use Scalar::Util qw( refaddr );
use Test::More 0.86 tests => 26 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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
my @files = sort grep { /\.pm$/ } readdir(TESTDIR);
closedir( TESTDIR ) or die "closedir: $!";
ok( scalar @files, 'Found at least one .pm file' );





#####################################################################
# Testing

my $tempdir = tempdir(CLEANUP => 1);
foreach my $input ( @files ) {
	# Prepare
	my $copy   = catfile($tempdir, "${input}_copy");
	my $copy2  = catfile($tempdir, "${input}_copy2");

	$input = catfile($testdir, $input);
	my $output = "${input}_out";

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


eval { PPI::Transform->document };
like $@, qr/PPI::Transform does not implement the required ->document method/,
  "transform classes need to implement ->document";





#####################################################################
# Support Code

# Test Transform class
package MyCleaner;

use Params::Util qw( _INSTANCE );
use PPI::Transform ();

our @ISA;
BEGIN {
	@ISA = 'PPI::Transform'; # in a BEGIN block due to being an inline package
}

sub document {
	my $self     = shift;
	my $Document = _INSTANCE(shift, 'PPI::Document') or return undef;
	$Document->prune( 'Token::Whitespace' );
	$Document;
}

package Foo;

use Helper 'safe_new';

sub new {
	bless { }, 'Foo';
}

our $VALUE = '';

sub get {
	safe_new \$VALUE;
}

sub set {
	$VALUE = $_[1]->serialize;
}
