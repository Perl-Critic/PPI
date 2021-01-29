#!/usr/bin/perl

# Unit testing for PPI::Token::HereDoc

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 30 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI;
use Test::Deep;

sub h;

# List of tests to perform. Each test requires the following information:
#     - 'name': the name of the test in the output.
#     - 'content': the Perl string to parse using PPI.
#     - 'expected': a hashref with the keys being property names on the
#       PPI::Token::HereDoc object, and the values being the expected value of
#       that property after the heredoc block has been parsed. Key 'heredoc'
#       is a special case, and is an array ref holding the expected value of
#       heredoc(), and defaulting to [ "Line 1\n", "Line 2\n" ].

	# Tests with a carriage return after the termination marker.
h	{
		name     => 'Bareword terminator.',
		content  => "my \$heredoc = <<HERE;\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Single-quoted bareword terminator.',
		content  => "my \$heredoc = <<'HERE';\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Single-quoted bareword terminator with space.',
		content  => "my \$heredoc = << 'HERE';\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Double-quoted bareword terminator.',
		content  => "my \$heredoc = <<\"HERE\";\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Double-quoted bareword terminator with space.',
		content  => "my \$heredoc = << \"HERE\";\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Command-quoted terminator.',
		content  => "my \$heredoc = <<`HERE`;\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'command',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Command-quoted terminator with space.',
		content  => "my \$heredoc = << `HERE`;\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'command',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Legacy escaped bareword terminator.',
		content  => "my \$heredoc = <<\\HERE;\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => undef,
			_indentation     => undef,
		},
	};

	# Tests without a carriage return after the termination marker.
h	{
		name     => 'Bareword terminator (no return).',
		content  => "my \$heredoc = <<HERE;\nLine 1\nLine 2\nHERE",
		expected => {
			_terminator_line => 'HERE',
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Single-quoted bareword terminator (no return).',
		content  => "my \$heredoc = <<'HERE';\nLine 1\nLine 2\nHERE",
		expected => {
			_terminator_line => "HERE",
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Double-quoted bareword terminator (no return).',
		content  => "my \$heredoc = <<\"HERE\";\nLine 1\nLine 2\nHERE",
		expected => {
			_terminator_line => 'HERE',
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Command-quoted terminator (no return).',
		content  => "my \$heredoc = <<`HERE`;\nLine 1\nLine 2\nHERE",
		expected => {
			_terminator_line => 'HERE',
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'command',
			_indented        => undef,
			_indentation     => undef,
		},
	};
h	{
		name     => 'Legacy escaped bareword terminator (no return).',
		content  => "my \$heredoc = <<\\HERE;\nLine 1\nLine 2\nHERE",
		expected => {
			_terminator_line => 'HERE',
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => undef,
			_indentation     => undef,
		},
	};

	# Tests without a terminator.
h	{
		name     => 'Unterminated heredoc block.',
		content  => "my \$heredoc = <<HERE;\nLine 1\nLine 2\n",
		expected => {
			_terminator_line => undef,
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => undef,
			_indentation     => undef,
		},
	};

	# Tests indented here-document with a carriage return after the termination marker.
h	{
		name     => 'Bareword terminator (indented).',
		content  => "my \$heredoc = <<~HERE;\n\t \tLine 1\n\t \tLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Single-quoted bareword terminator (indented).',
		content  => "my \$heredoc = <<~'HERE';\n\t \tLine 1\n\t \tLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Single-quoted bareword terminator with space (indented).',
		content  => "my \$heredoc = <<~ 'HERE';\n\t \tLine 1\n\t \tLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Double-quoted bareword terminator (indented).',
		content  => "my \$heredoc = <<~\"HERE\";\n\t \tLine 1\n\t \tLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Double-quoted bareword terminator with space (indented).',
		content  => "my \$heredoc = <<~ \"HERE\";\n\t \tLine 1\n\t \tLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Command-quoted terminator (indented).',
		content  => "my \$heredoc = <<~`HERE`;\n\t \tLine 1\n\t \tLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'command',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Command-quoted terminator with space (indented).',
		content  => "my \$heredoc = <<~ `HERE`;\n\t \tLine 1\n\t \tLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'command',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Legacy escaped bareword terminator (indented).',
		content  => "my \$heredoc = <<~\\HERE;\n\t \tLine 1\n\t \tLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};

	# Tests indented here-document without a carriage return after the termination marker.
h	{
		name     => 'Bareword terminator (indented and no return).',
		content  => "my \$heredoc = <<~HERE;\n\t \tLine 1\n\t \tLine 2\n\t \tHERE",
		expected => {
			_terminator_line => 'HERE',
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Single-quoted bareword terminator (indented and no return).',
		content  => "my \$heredoc = <<~'HERE';\n\t \tLine 1\n\t \tLine 2\n\t \tHERE",
		expected => {
			_terminator_line => "HERE",
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Double-quoted bareword terminator (indented and no return).',
		content  => "my \$heredoc = <<~\"HERE\";\n\t \tLine 1\n\t \tLine 2\n\t \tHERE",
		expected => {
			_terminator_line => 'HERE',
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Command-quoted terminator (indented and no return).',
		content  => "my \$heredoc = <<~`HERE`;\n\t \tLine 1\n\t \tLine 2\n\t \tHERE",
		expected => {
			_terminator_line => 'HERE',
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'command',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};
h	{
		name     => 'Legacy escaped bareword terminator (indented and no return).',
		content  => "my \$heredoc = <<~\\HERE;\n\t \tLine 1\n\t \tLine 2\n\t \tHERE",
		expected => {
			_terminator_line => 'HERE',
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'literal',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};

	# Tests indented here-document without a terminator.
h	{
		name     => 'Unterminated heredoc block (indented).',
		content  => "my \$heredoc = <<~HERE;\nLine 1\nLine 2\n",
		expected => {
			_terminator_line => undef,
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => 1,
			_indentation     => undef,
		},
	};

	# Tests indented here-document where indentation doesn't match
h	{
		name     => 'Unterminated heredoc block (indented).',
		content  => "my \$heredoc = <<~HERE;\nLine 1\nLine 2\n\t \tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => 1,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => 1,
			_indentation     => "\t \t",
		},
	};

	# Tests indented here-document with empty line
h	{
		name	=> 'Indented heredoc with empty line.',
		content	=> "my \$heredoc = <<~HERE;\n\tLine 1\n\n\tLine 3\n\tHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
			_indented        => 1,
			heredoc          => [ "Line 1\n", "\n", "Line 3\n" ],
			_indentation     => "\t",
		},
	};


sub h {
    my ( $test ) = @_;
    my %exception = map { $_ => 1 } qw{ heredoc };
	subtest(
		$test->{name},
		sub {
			my $exceptions = grep { $exception{$_} } keys %{ $test->{expected} };
			plan tests => 7 - $exceptions + keys %{ $test->{expected} };

			my $document = PPI::Document->new( \$test->{content} );
			isa_ok( $document, 'PPI::Document' );

			SKIP: {
				skip 'Damaged document', 1 if $test->{expected}{_damaged};
				is( $document->serialize(), $test->{content}, 'Document serializes correctly' );
			}

			my $heredocs = $document->find( 'Token::HereDoc' );
			is( ref $heredocs,     'ARRAY', 'Found heredocs.' );
			is( scalar @$heredocs, 1,       'Found 1 heredoc block.' );

			my $heredoc = $heredocs->[0];
			isa_ok( $heredoc, 'PPI::Token::HereDoc' );
			can_ok( $heredoc, 'heredoc' );

			my @content = $heredoc->heredoc;
			my @expected_heredoc = @{ $test->{expected}{heredoc} || [ "Line 1\n", "Line 2\n", ] };
			is_deeply(
				\@content,
				\@expected_heredoc,
				'The returned content does not include the heredoc terminator.',
			) or diag "heredoc() returned ", explain \@content;

			is( $heredoc->{$_}, $test->{expected}{$_}, "property '$_'" ) for grep { ! $exception{$_} } keys %{ $test->{expected} };
		}
	);
}
