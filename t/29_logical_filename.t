#!/usr/bin/perl

# Testing of PPI::Element->logical_filename

use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 21;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use PPI::Document;
use PPI::Document::File;
use PPI::Util ();


for my $class ( qw{ PPI::Document PPI::Document::File } ) {

	#####################################################################
	# Actual filename is used until #line directive

	SCOPE: {
		my $file = catfile('t', 'data', 'filename.pl');
		ok( -f $file, "$class, test file" );

		my $doc = $class->new( $file );
		my $items = $doc->find( 'Token::Quote' );
		is( @$items + 0, 2, "$class, number of items" );
		is( $items->[ 0 ]->logical_filename, "$file", "$class, filename" );
		is( $items->[ 1 ]->logical_filename, "moo.pl", "$class, filename" );
	}

	#####################################################################
	# filename attribute overrides actual filename

	SCOPE: {
		my $file = catfile('t', 'data', 'filename.pl');
		ok( -f $file, "$class, test file" );

		my $doc = $class->new( $file, filename => 'assa.pl' );
		my $items = $doc->find( 'Token::Quote' );
		is( @$items + 0, 2, "$class, number of items" );
		my $str = $items->[ 0 ];
		is( $items->[ 0 ]->logical_filename, "assa.pl", "$class, filename" );
		is( $items->[ 1 ]->logical_filename, "moo.pl", "$class, filename" );
	}

}

#####################################################################
# filename attribute works for strings too

SCOPE: {
	my $class = 'PPI::Document';
	my $file = catfile('t', 'data', 'filename.pl');
	ok( -f $file, "$class, test file" );
	my $text = PPI::Util::_slurp( $file );

	my $doc = $class->new( $text, filename => 'tadam.pl' );
	my $items = $doc->find( 'Token::Quote' );
	is( @$items + 0, 2, "$class, number of items" );
	my $str = $items->[ 0 ];
	is( $items->[ 0 ]->logical_filename, "tadam.pl", "$class, filename" );
	is( $items->[ 1 ]->logical_filename, "moo.pl", "$class, filename" );
}
