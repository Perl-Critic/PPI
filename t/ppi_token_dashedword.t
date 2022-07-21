#!/usr/bin/perl

# Unit testing for PPI::Token::DashedWord

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 12 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


LITERAL: {
	my @pairs = (
		"-foo",        '-foo',
		"-Foo::Bar",   '-Foo::Bar',
		"-Foo'Bar",    '-Foo::Bar',
	);
	while ( @pairs ) {
		my $from  = shift @pairs;
		my $to    = shift @pairs;
		my $doc   = safe_new \"( $from => 1 );";
		my $word = $doc->find_first('Token::DashedWord');
		SKIP: {
			skip( "PPI::Token::DashedWord is deactivated", 2 );
			isa_ok( $word, 'PPI::Token::DashedWord' );
			is( $word && $word->literal, $to, "The source $from becomes $to ok" );
		}
	}
}
