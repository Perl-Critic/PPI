#!/usr/bin/perl

# Structures always have a start (opening) brace.
# The constructor requires one and PDOM manipulation cannot remove it.
# Guards that check for missing start braces are dead code.
# See https://github.com/Perl-Critic/PPI/issues/24

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 49 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';

# Complete documents: every structure has start and braces()
COMPLETE: {
	my $doc = safe_new \"my \@a = (1, 2); my \$h = {a => 1}; my \$x = \$a[0];";

	my $structs = $doc->find('PPI::Structure');
	ok $structs && @$structs == 3, 'found three structures';

	for my $s (@$structs) {
		ok defined $s->start,  ref($s) . ' has start brace';
		ok defined $s->braces, ref($s) . ' braces() returns defined value';
	}
}

# Incomplete document (missing closing brace): start is still always present
INCOMPLETE: {
	my $doc = safe_new \"sub foo {";

	my $structs = $doc->find('PPI::Structure');
	ok $structs && @$structs >= 1, 'found structure in incomplete doc';

	my $s = $structs->[0];
	ok  defined $s->start,  'incomplete structure has start brace';
	ok !defined $s->finish, 'incomplete structure lacks finish brace';
	ok  defined $s->braces, 'incomplete structure braces() still returns defined value';
	is $s->braces, '{}',    'incomplete structure braces() returns correct type';
}

# first_element is always the start brace for a structure
FIRST_ELEMENT: {
	my $doc = safe_new \"(1)";

	my $s = $doc->find_first('PPI::Structure');
	ok $s, 'found structure';

	TODO: {
		local $TODO = "start brace guards are dead code to be removed";
		is $s->first_element, $s->start, 'first_element is always the start brace';
	}
}

# braces() never returns undef for a parsed structure
BRACES: {
	for my $code ( '()', '[]', '{}', 'sub {1}', 'my @a = (1)', '$h->{x}', '$a[0]' ) {
		my $doc = safe_new \$code;
		my $s = $doc->find_first('PPI::Structure') or next;

		TODO: {
			local $TODO = "start brace guards are dead code to be removed";
			ok defined $s->braces, "braces() defined for: $code";
		}
	}
}

# complete() is false when only finish is missing, true otherwise
COMPLETE_METHOD: {
	my $complete_doc = safe_new \"(1)";
	my $cs = $complete_doc->find_first('PPI::Structure');
	ok $cs, 'found complete structure';
	ok $cs->complete, 'complete() is true when both braces present';

	my $incomplete_doc = safe_new \"(1";
	my $is = $incomplete_doc->find_first('PPI::Structure');
	ok $is, 'found incomplete structure';
	ok !$is->complete, 'complete() is false when finish brace missing';
}
