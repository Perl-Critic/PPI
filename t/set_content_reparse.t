#!/usr/bin/perl

# Regression tests for set_content on QuoteEngine::Full tokens
# https://github.com/Perl-Critic/PPI/issues/296

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 26 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';

QW_SET_CONTENT: {
	my $doc = safe_new \"my \@a = qw( 1 2 3);";
	my $qw = $doc->find_first('PPI::Token::QuoteLike::Words');

	is_deeply [ $qw->literal ], [ '1', '2', '3' ],
		'literal before set_content';

	my $new_content = $qw->content =~ s/ 2//r;
	$qw->set_content($new_content);

	is $qw->content, 'qw( 1 3)', 'content updated';
	is_deeply [ $qw->literal ], [ '1', '3' ],
		'literal after set_content reflects new content';
}

QW_SET_CONTENT_BRACES: {
	my $doc = safe_new \"my \@a = qw{ foo bar baz };";
	my $qw = $doc->find_first('PPI::Token::QuoteLike::Words');

	$qw->set_content('qw{ foo baz }');

	is_deeply [ $qw->literal ], [ 'foo', 'baz' ],
		'literal after set_content with braces';
}

QW_SET_CONTENT_SLASH: {
	my $doc = safe_new \"my \@a = qw/a b c/;";
	my $qw = $doc->find_first('PPI::Token::QuoteLike::Words');

	$qw->set_content('qw/a c/');

	is_deeply [ $qw->literal ], [ 'a', 'c' ],
		'literal after set_content with slash delimiters';
}

QW_SET_CONTENT_WITH_GAP: {
	my $doc = safe_new \"my \@a = qw ( x y z );";
	my $qw = $doc->find_first('PPI::Token::QuoteLike::Words');

	$qw->set_content('qw ( x z )');

	is_deeply [ $qw->literal ], [ 'x', 'z' ],
		'literal after set_content with gap between operator and delimiter';
}

REGEXP_SET_CONTENT: {
	my $doc = safe_new \"my \$x =~ m/foo/i;";
	my $re = $doc->find_first('PPI::Token::Regexp::Match');

	is $re->get_match_string, 'foo', 'match string before set_content';

	$re->set_content('m/bar/gi');

	is $re->get_match_string, 'bar',
		'match string after set_content on regexp';
	is_deeply { $re->get_modifiers }, { g => 1, i => 1 },
		'modifiers updated after set_content';
}

SUBSTITUTE_SET_CONTENT: {
	my $doc = safe_new \"my \$x =~ s/foo/bar/;";
	my $re = $doc->find_first('PPI::Token::Regexp::Substitute');

	is $re->get_match_string, 'foo', 'match string before set_content';
	is $re->get_substitute_string, 'bar', 'substitute string before set_content';

	$re->set_content('s/baz/qux/g');

	is $re->get_match_string, 'baz',
		'match string after set_content on substitute';
	is $re->get_substitute_string, 'qux',
		'substitute string after set_content';
	is_deeply { $re->get_modifiers }, { g => 1 },
		'modifiers updated after set_content on substitute';
}
