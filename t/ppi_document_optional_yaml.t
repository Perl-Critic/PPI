#!/usr/bin/perl

# PPI loads and parses without YAML::PP.  YAML::PP is needed only to read
# $ENV{PPI_CUSTOM_FEATURE_INCLUDES}, so a machine without it must still be
# able to use PPI; with the variable set, the error says what is missing.

BEGIN {
	# Refuse YAML::PP, as on a machine that does not have it installed.
	unshift @INC, sub {
		die "Can't locate YAML/PP.pm (refused by $0)\n" if $_[1] eq 'YAML/PP.pm';
		return;
	};
}

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 3 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

our $TODO;

delete $ENV{PPI_CUSTOM_FEATURE_INCLUDES};

TODO: {
	local $TODO = 'PPI::Document loads YAML::PP when it is compiled';
	ok( eval { require PPI; 1 }, 'PPI loads without YAML::PP' ) or diag $@;
	my $doc = eval { PPI::Document->new( \'my $x = 1;' ) };
	ok( $doc && $doc->serialize eq 'my $x = 1;', '... and parses a document' );
	local $ENV{PPI_CUSTOM_FEATURE_INCLUDES} = 'MyStrict: {signatures: perl}';
	my $ok = eval { PPI::Document->new( \'use MyStrict;' ); 1 };
	like( $ok ? '' : $@, qr{YAML/PP\.pm},
		'... and PPI_CUSTOM_FEATURE_INCLUDES without YAML::PP says YAML::PP is missing' );
}
