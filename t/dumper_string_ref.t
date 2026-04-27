#!/usr/bin/perl

# Test that PPI::Dumper accepts string references of source code

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 11 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use PPI::Dumper ();
use Helper 'safe_new';

my $code = '$a = 1;';

my $todo_reason = "PPI::Dumper does not yet accept string references";

TODO: {
	local $TODO = $todo_reason;

	# Create a dumper from a string reference
	my $Dumper = PPI::Dumper->new( \$code );
	isa_ok( $Dumper, 'PPI::Dumper', 'new(\\$code) returns a PPI::Dumper' );

	SKIP: {
		skip 'Dumper creation failed', 3 unless $Dumper;

		# Verify dump methods work
		my @list = $Dumper->list;
		ok( scalar @list, 'list() returns content from string ref dumper' );

		my $string = $Dumper->string;
		ok( defined $string, 'string() returns defined value from string ref dumper' );
		ok( length $string, 'string() returns non-empty string from string ref dumper' );
	}
}

# Create a dumper from a PPI::Element (existing behavior still works)
{
	my $doc = safe_new \$code;
	my $Dumper = PPI::Dumper->new( $doc );
	isa_ok( $Dumper, 'PPI::Dumper', 'new($element) still works' );
	my @list = $Dumper->list;
	ok( scalar @list, 'list() returns content from element dumper' );
}

TODO: {
	local $TODO = $todo_reason;

	# Output from string ref and element should be identical
	my $doc = PPI::Document->new( \$code );
	my $dumper_from_elem = PPI::Dumper->new( $doc );
	my $dumper_from_ref  = PPI::Dumper->new( \$code );

	SKIP: {
		skip 'Dumper creation from string ref failed', 1 unless $dumper_from_ref;
		is_deeply(
			[ $dumper_from_ref->list ],
			[ $dumper_from_elem->list ],
			'string ref and element produce identical dump output',
		);
	}
}

# Undef and invalid args still return undef
{
	my $bad1 = PPI::Dumper->new( undef );
	is( $bad1, undef, 'new(undef) returns undef' );

	my $bad2 = PPI::Dumper->new( 'not an element' );
	is( $bad2, undef, 'new("string") returns undef' );
}
