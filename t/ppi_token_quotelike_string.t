#!/usr/bin/perl

# Unit testing for PPI::Token::QuoteLike ->string method

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 45 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


BACKTICK: {
	my $Document = safe_new \"my \$x = \`foo\`;";
	my $found = $Document->find( 'PPI::Token::QuoteLike::Backtick' );
	is( ref $found, 'ARRAY', 'Backtick: found token' );
	is( scalar @$found, 1, 'Backtick: found 1 token' );
	my $token = $found->[0];
	TODO: {
		local $TODO = 'string method not yet implemented on QuoteLike classes';
		can_ok( $token, 'string' );
		is( eval { $token->string }, 'foo', 'Backtick: ->string returns content without delimiters' );
	}
}

COMMAND: {
	my $Document = safe_new \"my \$x = qx{foo};";
	my $found = $Document->find( 'PPI::Token::QuoteLike::Command' );
	is( ref $found, 'ARRAY', 'Command: found token' );
	is( scalar @$found, 1, 'Command: found 1 token' );
	my $token = $found->[0];
	TODO: {
		local $TODO = 'string method not yet implemented on QuoteLike classes';
		can_ok( $token, 'string' );
		is( eval { $token->string }, 'foo', 'Command: ->string returns content without delimiters' );
	}
}

COMMAND_SLASH: {
	my $Document = safe_new \"my \$x = qx/bar/;";
	my $found = $Document->find( 'PPI::Token::QuoteLike::Command' );
	is( ref $found, 'ARRAY', 'Command slash: found token' );
	is( scalar @$found, 1, 'Command slash: found 1 token' );
	my $token = $found->[0];
	TODO: {
		local $TODO = 'string method not yet implemented on QuoteLike classes';
		is( eval { $token->string }, 'bar', 'Command slash: ->string returns content without delimiters' );
	}
}

REGEXP: {
	my $Document = safe_new \"my \$x = qr{foo}i;";
	my $found = $Document->find( 'PPI::Token::QuoteLike::Regexp' );
	is( ref $found, 'ARRAY', 'Regexp: found token' );
	is( scalar @$found, 1, 'Regexp: found 1 token' );
	my $token = $found->[0];
	TODO: {
		local $TODO = 'string method not yet implemented on QuoteLike classes';
		can_ok( $token, 'string' );
		is( eval { $token->string }, 'foo', 'Regexp: ->string returns content without delimiters' );
	}
}

REGEXP_SLASH: {
	my $Document = safe_new \"my \$x = qr/baz/;";
	my $found = $Document->find( 'PPI::Token::QuoteLike::Regexp' );
	is( ref $found, 'ARRAY', 'Regexp slash: found token' );
	is( scalar @$found, 1, 'Regexp slash: found 1 token' );
	my $token = $found->[0];
	TODO: {
		local $TODO = 'string method not yet implemented on QuoteLike classes';
		is( eval { $token->string }, 'baz', 'Regexp slash: ->string returns content without delimiters' );
	}
}

WORDS: {
	my $Document = safe_new \"my \@x = qw{foo bar baz};";
	my $found = $Document->find( 'PPI::Token::QuoteLike::Words' );
	is( ref $found, 'ARRAY', 'Words: found token' );
	is( scalar @$found, 1, 'Words: found 1 token' );
	my $token = $found->[0];
	TODO: {
		local $TODO = 'string method not yet implemented on QuoteLike classes';
		can_ok( $token, 'string' );
		is( eval { $token->string }, 'foo bar baz', 'Words: ->string returns content without delimiters' );
	}
}

WORDS_SLASH: {
	my $Document = safe_new \"my \@x = qw/a b c/;";
	my $found = $Document->find( 'PPI::Token::QuoteLike::Words' );
	is( ref $found, 'ARRAY', 'Words slash: found token' );
	is( scalar @$found, 1, 'Words slash: found 1 token' );
	my $token = $found->[0];
	TODO: {
		local $TODO = 'string method not yet implemented on QuoteLike classes';
		is( eval { $token->string }, 'a b c', 'Words slash: ->string returns content without delimiters' );
	}
}

READLINE: {
	my $Document = safe_new \"my \$x = <STDIN>;";
	my $found = $Document->find( 'PPI::Token::QuoteLike::Readline' );
	is( ref $found, 'ARRAY', 'Readline: found token' );
	is( scalar @$found, 1, 'Readline: found 1 token' );
	my $token = $found->[0];
	TODO: {
		local $TODO = 'string method not yet implemented on QuoteLike classes';
		can_ok( $token, 'string' );
		is( eval { $token->string }, 'STDIN', 'Readline: ->string returns content without delimiters' );
	}
}
