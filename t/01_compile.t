#!/usr/bin/perl

# This test script only tests that the tree compiles

use t::lib::PPI::Test::pragmas;
use Test::More tests => 18;


# Do the modules load
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
