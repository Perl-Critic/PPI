#!/usr/bin/perl

# Regression tests for Params::Util RT#75561: the XS versions of _ARRAY
# and _ARRAY0 do not exclude blessed references, unlike the pure-perl
# versions and the documentation. This let blessed arrayrefs slip past
# checks that are meant to reject "unknown" objects, and get misparsed
# as if they were an ARRAY of source lines instead.

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 6;

use PPI::Document ();
use PPI::Tokenizer ();
use PPI::Util qw{ _Document };

my $BUG = 'Params::Util XS _ARRAY0 does not reject blessed references (RT#75561)';

# A blessed arrayref is not a filename, a SCALAR ref, or a plain ARRAY
# ref, so none of these should treat it as a source of Perl code.
my $bogus = bless [ 'print 1;', 'print 2;' ], 'Test::BlessedArray::NotASource';

SCOPE: {
	my $doc = PPI::Document->new($bogus);

	TODO: {
		local $TODO = $BUG;
		ok( !defined($doc), 'PPI::Document->new rejects a blessed arrayref' );
	}
}

SCOPE: {
	PPI::Document->_clear;
	PPI::Document->new($bogus);

	TODO: {
		local $TODO = $BUG;
		ok( PPI::Document->errstr, 'PPI::Document->new records an error for a blessed arrayref' );
	}
}

SCOPE: {
	my $tokenizer = eval { PPI::Tokenizer->new($bogus) };
	my $exception = $@;

	TODO: {
		local $TODO = $BUG;
		ok( !defined($tokenizer), 'PPI::Tokenizer->new rejects a blessed arrayref' );
	}

	TODO: {
		local $TODO = $BUG;
		isa_ok( $exception, 'PPI::Exception' );
	}

	TODO: {
		local $TODO = $BUG;
		like(
			( ref($exception) && $exception->isa('PPI::Exception') ) ? $exception->message : '',
			qr/not supported as a source provider/,
			'PPI::Tokenizer->new explains why a blessed arrayref was rejected',
		);
	}
}

SCOPE: {
	my $doc = _Document($bogus);

	TODO: {
		local $TODO = $BUG;
		ok( !defined($doc), 'PPI::Util::_Document rejects a blessed arrayref' );
	}
}
