#!/usr/bin/perl

# Testing of PPI::Element->logical_filename

use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use File::Spec::Functions qw( catfile );
use PPI::Document ();
use PPI::Document::File ();
use PPI::Util ();
use Test::More tests => 30 + 1; # Test::NoWarnings
use Test::NoWarnings; ## no perlimports

for my $class ( ( PPI::Document::, PPI::Document::File:: ) ) {

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

	#####################################################################
	# filename accessor returns the correct value

	SCOPE: {
		my $file = catfile('t', 'data', 'filename.pl');
		my $doc = $class->new( $file );
		is( $doc->filename, $file, "$class, filename accessor matches source path" );
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

#####################################################################
# filename accessor works for string refs with filename param
# (Dist::Zilla use case from issue #180)

SCOPE: {
	my $class = 'PPI::Document';
	my $source = "my \$x = 1;\n";

	my $doc = $class->new( \$source, filename => 'lib/Foo.pm' );
	is( $doc->filename, 'lib/Foo.pm', "$class, filename accessor for string ref" );
	$doc->index_locations;
	my @tokens = $doc->tokens;
	is( $tokens[0]->logical_filename, 'lib/Foo.pm',
		"$class, logical_filename propagated from filename param" );
}

#####################################################################
# string ref without filename param returns undef

SCOPE: {
	my $class = 'PPI::Document';
	my $source = "my \$x = 1;\n";

	my $doc = $class->new( \$source );
	is( $doc->filename, undef, "$class, no filename for anonymous string ref" );
	$doc->index_locations;
	my @tokens = $doc->tokens;
	is( $tokens[0]->logical_filename, undef,
		"$class, logical_filename undef for anonymous string ref" );
}

#####################################################################
# logical_filename works without explicit index_locations call

SCOPE: {
	my $class = 'PPI::Document';
	my $source = "my \$x = 1;\n";

	my $doc = $class->new( \$source, filename => 'auto.pl' );
	my @tokens = $doc->tokens;
	is( $tokens[0]->logical_filename, 'auto.pl',
		"$class, logical_filename auto-indexes when needed" );
}

#####################################################################
# filename param does not interfere with #line directives

SCOPE: {
	my $class = 'PPI::Document';
	my $source = "my \$x = 1;\n#line 100 other.pl\nmy \$y = 2;\n";

	my $doc = $class->new( \$source, filename => 'orig.pl' );
	$doc->index_locations;
	my $vars = $doc->find( 'Statement::Variable' );
	is( @$vars + 0, 2, "$class, found both variable statements" );
	is( $vars->[0]->logical_filename, 'orig.pl',
		"$class, before #line uses filename param" );
	is( $vars->[1]->logical_filename, 'other.pl',
		"$class, after #line uses directive filename" );
}
