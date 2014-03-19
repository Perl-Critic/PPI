#!/usr/bin/perl

# Unit testing for PPI::Token::HereDoc

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 6;
use Test::NoWarnings;
use PPI;


HEREDOC: {
	my $tests = [
		{
			name    => 'Bareword terminator.',
			content => "my \$heredoc = <<HERE;\nLine 1\nLine 2\nHERE\n",
		},
		{
			name    => 'Single-quoted bareword terminator.',
			content => "my \$heredoc = <<'HERE';\nLine 1\nLine 2\n'HERE'\n",
		},
		{
			name    => 'Double-quoted bareword terminator.',
			content => "my \$heredoc = <<\"HERE\";\nLine 1\nLine 2\n\"HERE\"\n",
		},
		{
			name    => 'Command-quoted terminator.',
			content => "my \$heredoc = <<`HERE`;\nLine 1\nLine 2\n`HERE`\n",
		},
		{
			name    => 'Legacy escaped bareword terminator.',
			content => "my \$heredoc = <<\\HERE;\nLine 1\nLine 2\n\\HERE\n",
		},
	];

	foreach my $test ( @$tests ) {
		subtest(
			$test->{'name'},
			sub {
				plan( tests => 6 );

				my $document = PPI::Document->new( \$test->{'content'} );
				isa_ok( $document, 'PPI::Document' );

				my $heredocs = $document->find('Token::HereDoc');
				is( ref($heredocs), 'ARRAY', 'Found heredocs.' );
				is( scalar(@$heredocs), 1, 'Found 1 heredoc block.' );
				my $heredoc = $heredocs->[0];
				isa_ok( $heredoc, 'PPI::Token::HereDoc');
				can_ok( $heredoc, 'heredoc' );

				my @content = $heredoc->heredoc();
				unlike(
					$content[-1],
					qr/HERE/,
					'The returned content does not include the heredoc terminator.',
				) || diag( "heredoc() returned ", explain( \@content ) );
			}
		);
	}
}
