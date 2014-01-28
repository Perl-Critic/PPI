#!/usr/bin/perl

use warnings;
use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use PPI;

use Test::More tests => 4;

{
	# Create the test fragments
	my $one = PPI::Token::Pod->new("=pod\n\nOne\n\n=cut\n");
	my $two = PPI::Token::Pod->new("=pod\n\nTwo");
	isa_ok( $one, 'PPI::Token::Pod' );
	isa_ok( $two, 'PPI::Token::Pod' );

	# Create the combined Pod
	my $merged = PPI::Token::Pod->merge($one, $two);
	isa_ok( $merged, 'PPI::Token::Pod' );
	is( $merged->content, "=pod\n\nOne\n\nTwo\n\n=cut\n", 'Merged POD looks ok' );
}


1;
