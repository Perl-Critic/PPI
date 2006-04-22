#!/usr/bin/perl -w

# Formal testing for PPI

# This test script only tests that the tree compiles

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

use Test::More tests => 18;





# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
BEGIN {
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Kill warning
}
use_all_ok( qw{
	PPI
	PPI::Tokenizer
	PPI::Lexer
	PPI::Dumper
	PPI::Find
	PPI::Normal
	PPI::Util
	PPI::Cache
	} );

sub use_all_ok {
	my @modules = @_;

	# Load each of the classes
	foreach my $module ( @modules ) {
		use_ok( $module );
	}

	# Check that all of the versions match
	my $main_module = shift(@modules);
	my $expected    = $main_module->VERSION;
	ok( $expected, "Found a version for the main module ($expected)" );

	foreach my $module ( @modules ) {
		is( $module->VERSION, $expected, "$main_module->VERSION matches $module->VERSION ($expected)" );
	}
}

ok( ! $PPI::XS::VERSION, 'PPI::XS is correctly NOT loaded' );

exit(0);
