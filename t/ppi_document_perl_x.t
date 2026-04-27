#!/usr/bin/perl

# Tests for perl -x emulation via the perl_x option

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 29 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use PPI::Token::Preamble ();
use Helper 'safe_new';

our $TODO_MSG = "perl_x option not yet implemented";

#####################################################################
# Basic perl_x parsing — preamble before shebang

BASIC_PREAMBLE: {
	my $source = <<'END_SOURCE';
This is some random text
that appears before the perl script.
#!/usr/bin/perl
print "Hello World!\n";
END_SOURCE

	my $doc = PPI::Document->new(\$source, perl_x => 1);
	ok( $doc, 'document created with perl_x' );

	TODO: {
		local $TODO = $TODO_MSG;

		my $preamble = $doc->find_first('Token::Preamble');
		ok( $preamble, 'found a Preamble token' );
		is( ($preamble ? $preamble->content : undef),
			"This is some random text\nthat appears before the perl script.\n",
			'preamble content is correct' );
		ok( ($preamble ? !$preamble->significant : undef),
			'preamble is not significant' );

		my $code = $doc->find_first('Token::Word');
		is( ($code ? $code->content : undef), 'print',
			'first word after preamble is code, not preamble text' );
	}
}


#####################################################################
# Round-trip safety with batch file wrapper

ROUND_TRIP: {
	my $source = <<'END_SOURCE';
@echo off
rem This is a batch file wrapper
#!/usr/bin/perl -w
use strict;
print "works\n";
END_SOURCE

	my $doc = PPI::Document->new(\$source, perl_x => 1);
	ok( $doc, 'document created for round-trip test' );

	is( $doc->serialize, $source,
		'round-trip is safe with perl_x' );

	TODO: {
		local $TODO = $TODO_MSG;

		my $preamble = $doc->find_first('Token::Preamble');
		ok( $preamble, 'preamble found in batch wrapper' );
	}
}


#####################################################################
# No preamble — shebang on first line with perl_x enabled

NO_PREAMBLE: {
	my $source = <<'END_SOURCE';
#!/usr/bin/perl
print "Hello\n";
END_SOURCE

	my $doc = PPI::Document->new(\$source, perl_x => 1);
	ok( $doc, 'document created with shebang on first line' );

	my $preamble = $doc->find_first('Token::Preamble');
	ok( !$preamble, 'no preamble when shebang is on first line' );

	is( $doc->serialize, $source,
		'round-trip is safe when no preamble' );
}


#####################################################################
# No shebang at all — file should parse normally (no preamble token)

NO_SHEBANG: {
	my $source = "print 42;\n";

	my $doc = PPI::Document->new(\$source, perl_x => 1);
	ok( $doc, 'document created with no shebang' );

	my $preamble = $doc->find_first('Token::Preamble');
	ok( !$preamble, 'no preamble when no shebang exists' );

	is( $doc->serialize, $source,
		'round-trip is safe when no shebang' );
}


#####################################################################
# Shebang must contain "perl" — a non-perl shebang is not a match

NON_PERL_SHEBANG: {
	my $source = <<'END_SOURCE';
some text
#!/bin/bash
echo "not perl"
#!/usr/bin/perl
print "yes\n";
END_SOURCE

	my $doc = PPI::Document->new(\$source, perl_x => 1);
	ok( $doc, 'document created with non-perl shebang before perl one' );

	TODO: {
		local $TODO = $TODO_MSG;

		my $preamble = $doc->find_first('Token::Preamble');
		ok( $preamble, 'preamble found — skipped non-perl shebang' );
		is( ($preamble ? $preamble->content : undef),
			"some text\n#!/bin/bash\necho \"not perl\"\n",
			'preamble includes everything up to #!...perl line' );
	}
}


#####################################################################
# Without perl_x flag — no preamble tokens created

WITHOUT_FLAG: {
	my $source = <<'END_SOURCE';
#!/usr/bin/perl
print "Hello\n";
END_SOURCE

	my $doc = safe_new \$source;

	my $preamble = $doc->find_first('Token::Preamble');
	ok( !$preamble, 'no preamble token without perl_x flag' );
}


#####################################################################
# Preamble with file source (filename)

use File::Temp ();

PERL_X_FROM_FILE: {
	my $content = "garbage line\n#!/usr/bin/perl\nprint 1;\n";
	my $tmp = File::Temp->new(SUFFIX => '.pl', UNLINK => 1);
	print $tmp $content;
	close $tmp;

	my $doc = PPI::Document->new("$tmp", perl_x => 1);
	ok( $doc, 'document loaded from file with perl_x' );
	isa_ok( ($doc || 'PPI::Document'), 'PPI::Document' );

	TODO: {
		local $TODO = $TODO_MSG;

		my $preamble = $doc->find_first('Token::Preamble');
		ok( $preamble, 'preamble found when loading from file' );
	}
}


#####################################################################
# Single-line preamble

SINGLE_LINE_PREAMBLE: {
	my $source = "wrapper\n#!/usr/bin/perl\n1;\n";

	my $doc = PPI::Document->new(\$source, perl_x => 1);
	ok( $doc, 'document created for single-line preamble' );

	TODO: {
		local $TODO = $TODO_MSG;

		my $preamble = $doc->find_first('Token::Preamble');
		ok( $preamble, 'single-line preamble found' );
		is( ($preamble ? $preamble->content : undef), "wrapper\n",
			'single-line preamble content is correct' );
	}
}


#####################################################################
# Preamble with empty lines

EMPTY_LINE_PREAMBLE: {
	my $source = "\n\nsome text\n\n#!/usr/bin/perl\n1;\n";

	my $doc = PPI::Document->new(\$source, perl_x => 1);
	ok( $doc, 'document created for empty-line preamble' );

	TODO: {
		local $TODO = $TODO_MSG;

		my $preamble = $doc->find_first('Token::Preamble');
		ok( $preamble, 'preamble with empty lines found' );
		is( ($preamble ? $preamble->content : undef), "\n\nsome text\n\n",
			'preamble preserves empty lines' );
	}
}
