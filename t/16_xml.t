#!/usr/bin/perl

use t::lib::PPI::Test::pragmas;
use Test::More 0.86 tests => 17;

use PPI;





#####################################################################
# Begin Tests

my $code = 'print "Hello World";';
my $document = new_ok( 'PPI::Document' => [ \$code ] );

my @elements = $document->elements;
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
	is(
		$elements[$i]->_xml_name,
		$expect->[0],
		"Got _xml_name '$expect->[0]' as expected",
	);
	is_deeply(
		$elements[$i]->_xml_attr,
		$expect->[1],
		"Got _xml_attr as expected",
	);
	is(
		$elements[$i]->_xml_content,
		$expect->[2],
		"Got _xml_content '$expect->[2]' as expected",
	);
	$i++;
}
