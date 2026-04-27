#!/usr/bin/perl

# testing flush_locations and index_locations
# on just part of a Document

# this test scenario is directly from App::perlimports :
# an overly long use statement in a source document is replaced with
# one spread over multiple lines, conforming with perltidy's prerogatives
# (to reduce friction between the tools).

use lib 't/lib';
use PPI::Test::pragmas;

use PPI::Document ();
use Test::More tests => 2 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use Helper 'safe_new';

sub parse_statement {
	my $source = shift;

	# a location is a 6-element arrayref
	my $loc = @_ > 1 ? [@_] : shift @_;

	# line and pos are 1-indexed
	my ( $line, $pos, $filen ) = @{$loc}[ 0, 1, 4 ];
	my $text = "\n" x ( $line || 1 );
	substr( $text, -1 ) = " " x $pos
	  if $pos and $pos > 1;
	substr( $text, -1 ) = $source;
	die "couldnt parse PPI:Doc" unless    #
	  my $doc = PPI::Document->new( \$text, readonly => 1, filename => $filen );
	$doc->index_locations
	  if @{$loc};
	my $found = $doc->find_first('Statement');

	# tokens belong to the document, and will disappear
	# unless we clone them out of the doc
	return $found->clone;
}

subtest 'partial flush' => sub {
	my $file = "t/data/elem-loc.pl";
	die "no document" unless    #
	  my $Document = safe_new $file;

	my $includes = $Document->find('PPI::Statement::Include');
	my ( $include1, $include2, $include3 ) = @{$includes}[ 2, 3, 4 ];
	is_deeply $include1->location, [ 3, 5, 5, 3, $file, 32 ],
	  'location of 1st include';
	is_deeply $include2->location, [ 4, 1, 1, 4, $file, 75 ],
	  'location of 2nd include';
	is_deeply $include3->location, [ 5, 1, 1, 5, $file, 166 ],
	  'location of 3rd include';

	my $text = <<'EOSTM';
use Test::Script 1.27 qw(
    script_compiles
    script_runs
    script_stderr_is
    script_stderr_like
);
EOSTM
	chomp $text;
	my $replacement = parse_statement( $text, $include2->location );
	# parse_statement mimics line/column but not document offset
	is_deeply [@{$replacement->location}[0..4]], [@{$include2->location}[0..4]],
	  'mimicked start location correctly';
	is_deeply [@{$replacement->last_token->location}[0..4]], [ 9, 2, 2, 9, $file ],
	  'last token of replacement located correctly';

	$include2->replace($replacement);

	my $nextsib = $replacement->next_sibling;
	is_deeply $nextsib->location, [ 4, 91, 91, 4, $file, 165 ],
	  'next token location is stale';
	is_deeply $include3->location, [ 5, 1, 1, 5, $file, 166 ],
	  'location of 3rd include stale';

	my $res = eval { $nextsib->_flush_locations };
	is $@,   "", '_flush_locations lives';
	is $res, 1,  '.. and returns 1';

	is $nextsib->{_location}, undef, 'next token location cache deleted';
	is $include3->first_token->{_location}, undef,
	  '...next include stm location too';
};

subtest 'partial index' => sub {
	my $file = "t/data/elem-loc.pl";
	die "no document" unless    #
	  my $Document = safe_new $file;

	my $includes = $Document->find('PPI::Statement::Include');
	my ( $include1, $include2, $include3 ) = @{$includes}[ 2, 3, 4 ];

	# asking for any location, causes entire document to be indexed:
	is_deeply $include2->location, [ 4, 1, 1, 4, $file, 75 ],
	  'location of 2nd include';

	my $text = <<'EOSTM';
use Test::Script 1.27 qw(
    script_compiles
    script_runs
    script_stderr_is
    script_stderr_like
);
EOSTM
	chomp $text;
	my $replacement = parse_statement($text);
	is $replacement->first_token->{_location}, undef,
	  'replacement has no location data';
	is $replacement->location, undef,
	  'and it cant generate a default location when asked';

	$include2->replace($replacement);

	my $nextsib = $replacement->next_sibling;
	is_deeply $nextsib->location, [ 4, 91, 91, 4, $file, 165 ],
	  'next token location is stale';

	# now the $Document has a node without location, and all
	# subsequent elements have a stale cached location.

	# a partial reindex should fix all location caches:
	my $res = eval {
		use warnings 'FATAL';
		$Document->index_locations;
	};
	is $@,   "", 'no warning or exception from index_locations';
	is $res, 1,  '.. and returns 1';

	is_deeply $nextsib->location, [ 9, 3, 3, 9, $file, 183 ],
	  'next token location is now fresh';

	is_deeply $include3->location, [ 10, 1, 1, 10, $file, 184 ],
	  'location of 3rd include also refreshed';
};
