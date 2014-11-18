#!/usr/bin/perl

# Unit testing for PPI::Token::Pod

use t::lib::PPI::Test::pragmas;
use Test::More tests => 9;

use PPI;


MERGE: {
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


TOKENIZE: {
	foreach my $test (
		[ "=pod\n=cut", [ 'PPI::Token::Pod' ] ],
		[ "=pod\n=cut\n", [ 'PPI::Token::Pod' ] ],
		[ "=pod\n=cut\n\n", [ 'PPI::Token::Pod', 'PPI::Token::Whitespace' ] ],
		[ "=pod\n=Cut\n\n", [ 'PPI::Token::Pod' ] ],  # pod doesn't end, so no whitespace token
	) {
		my $T = PPI::Tokenizer->new( \$test->[0] );
		my @tokens = map { ref $_ } @{ $T->all_tokens };
		is_deeply( \@tokens, $test->[1], 'all tokens as expected' );
	}
}
