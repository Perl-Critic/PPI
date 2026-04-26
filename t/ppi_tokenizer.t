#!/usr/bin/perl

# Unit testing for PPI::Tokenizer

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 2 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI::Tokenizer ();

ALL_TOKENS_EXCEPTION_MESSAGE: {
	my $Tokenizer = PPI::Tokenizer->new( \"1" );

	no warnings 'redefine';
	local *PPI::Tokenizer::_process_next_line = sub { undef };

	my $ok = eval { $Tokenizer->all_tokens; 1 };
	my $err = $@;

	ok( !$ok, "all_tokens dies on error" );

	TODO: {
		local $TODO = 'all_tokens wraps PPI::Exception in another PPI::Exception';
		ok( !ref $err->message, "all_tokens exception message is a plain string" );
	}
}
