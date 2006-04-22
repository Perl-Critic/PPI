#!/usr/bin/perl -w

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

# Load the code to test
BEGIN { $PPI::XS_DISABLE = 1 }
use PPI;

use Test::More tests => 16;

sub new_ok {
	my $class = shift;
	my $object = $class->new( @_ );
	isa_ok( $object, $class );
	$object;
}





#####################################################################
# Begin Tests

my $code = 'print "Hello World";';
my $Document = new_ok( 'PPI::Document', \$code );

my @elements = $Document->elements;
push @elements, $elements[0]->elements;

my @expected = (
	[ 'statement',          {}, ''              ],
	[ 'token_word',         {}, 'print'         ],
	[ 'token_whitespace',   {}, ' '             ],
	[ 'token_quote_double', {}, '"Hello World"' ],
	[ 'token_structure',    {}, ';'             ],
	);
my $i = 0;
foreach my $expect ( @expected ) {
	is( $elements[$i]->_xml_name, $expect->[0], "Got _xml_name '$expect->[0]' as expected" );
	is_deeply( $elements[$i]->_xml_attr, $expect->[1], "Got _xml_attr as expected" );
	is( $elements[$i]->_xml_content, $expect->[2], "Got _xml_content '$expect->[2]' as expected" );
	$i++;
}

1;
