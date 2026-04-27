#!/usr/bin/perl

# Test that PPI parses broken/incomplete Perl code into best-effort
# documents rather than failing, and that the resulting documents
# contain appropriate indicator elements.

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 22 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';

{
	local $TODO = "best-effort parsing behavior not yet documented (GH #135)";
	fail "PPI::Document should document best-effort parsing of broken code";
}

# Unmatched closing brace produces a document, not undef
{
	my $doc = safe_new \'}';
	my $found = $doc->find('PPI::Statement::UnmatchedBrace');
	ok $found && @$found, 'unmatched closing brace produces UnmatchedBrace statement';
}

# Unmatched opening brace produces an incomplete Structure
{
	my $doc = safe_new \'if (1) {';
	is $doc->complete, '', 'unclosed brace makes document incomplete';
	my $structs = $doc->find('PPI::Structure');
	my @incomplete = grep { !$_->complete } @$structs;
	ok @incomplete, 'unclosed brace produces incomplete Structure';
}

# Broken subroutine declaration still parses
{
	my $doc = safe_new \'sub 1a {}';
	ok defined $doc->content, 'broken sub declaration produces parseable content';
}

# Missing semicolons still parse
{
	my $doc = safe_new \'my $x = 1
my $y = 2';
}

# Truncated heredoc produces a document with a damaged HereDoc token
{
	my $doc = safe_new \'print <<END;
hello';
	my $heredocs = $doc->find('PPI::Token::HereDoc');
	ok $heredocs && @$heredocs, 'truncated heredoc still produces HereDoc token';
}

# Round-trip safety: broken code serializes back identically
{
	my $broken = 'if (1) { my $x = }';
	my $doc = safe_new \$broken;
	is $doc->serialize, $broken, 'broken code round-trips through parse+serialize';
}

# Multiple problems in one document
{
	my $doc = safe_new \'}';
	my $unmatched = $doc->find('PPI::Statement::UnmatchedBrace');
	ok $unmatched && @$unmatched, 'stray closing brace found as UnmatchedBrace';
}
