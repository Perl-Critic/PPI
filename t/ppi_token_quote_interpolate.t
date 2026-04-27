#!/usr/bin/perl

# Unit testing for PPI::Token::Quote::Interpolate

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 32 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


STRING: {
	my $Document = safe_new \"print qq{foo}, qq!bar!, qq <foo>;";
	my $Interpolate = $Document->find('Token::Quote::Interpolate');
	is( scalar(@$Interpolate), 3, '->find returns three objects' );
	isa_ok( $Interpolate->[0], 'PPI::Token::Quote::Interpolate' );
	isa_ok( $Interpolate->[1], 'PPI::Token::Quote::Interpolate' );
	isa_ok( $Interpolate->[2], 'PPI::Token::Quote::Interpolate' );
	is( $Interpolate->[0]->string, 'foo', '->string returns as expected' );
	is( $Interpolate->[1]->string, 'bar', '->string returns as expected' );
	is( $Interpolate->[2]->string, 'foo', '->string returns as expected' );
}


INTERPOLATIONS: {
	my $Document = safe_new \<<'END_PERL';
qq{no interpolations}
qq{no \@interpolations}
qq{has $interpolation}
qq{has @interpolation}
qq{has \\@interpolation}
qq{}
END_PERL
	my $strings = $Document->find('Token::Quote::Interpolate');
	is( scalar @{$strings}, 6, 'Found the 6 test strings' );
	is( $strings->[0]->interpolations, '', 'String 1: No interpolations'  );
	is( $strings->[1]->interpolations, '', 'String 2: No interpolations'  );
	is( $strings->[2]->interpolations, 1,  'String 3: Has interpolations' );
	is( $strings->[3]->interpolations, 1,  'String 4: Has interpolations' );
	is( $strings->[4]->interpolations, 1,  'String 5: Has interpolations' );
	is( $strings->[5]->interpolations, '', 'String 6: No interpolations'  );
}


SIMPLIFY: {
	my $Document = safe_new \<<'END_PERL';
qq{no special characters}
qq{has $interpolation}
qq{has @interpolation}
qq{has \\backslash}
qq{}
qq!simple with bangs!
END_PERL
	my $strings = $Document->find('Token::Quote::Interpolate');
	is( scalar @{$strings}, 6, 'Found the 6 test strings' );

	my $result = $strings->[0]->simplify;
	isa_ok( $result, 'PPI::Token::Quote::Literal' );
	is( $result->content, 'q{no special characters}', 'Simplified qq{} to q{}' );
	is( $result->string, 'no special characters', '->string works after simplify' );

	$result = $strings->[1]->simplify;
	isa_ok( $result, 'PPI::Token::Quote::Interpolate' );

	$result = $strings->[2]->simplify;
	isa_ok( $result, 'PPI::Token::Quote::Interpolate' );

	$result = $strings->[3]->simplify;
	isa_ok( $result, 'PPI::Token::Quote::Interpolate' );

	$result = $strings->[4]->simplify;
	isa_ok( $result, 'PPI::Token::Quote::Literal' );
	is( $result->content, 'q{}', 'Empty string simplified' );

	$result = $strings->[5]->simplify;
	isa_ok( $result, 'PPI::Token::Quote::Literal' );
	is( $result->content, 'q!simple with bangs!', 'Simplified qq!! to q!!' );
	is( $result->string, 'simple with bangs', '->string works after simplify with !' );
}
