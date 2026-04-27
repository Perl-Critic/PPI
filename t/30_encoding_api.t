#!/usr/bin/perl

# Tests for the encoding-aware constructor APIs (GitHub issue #26)

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 29 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use File::Spec::Functions qw( catfile );
use PPI ();
use Helper 'safe_new';


#####################################################################
# new_from_string

NEW_FROM_STRING: {
	my $code = "my \$x = 1;\n";
	my $doc = PPI::Document->new_from_string($code);
	ok( $doc, 'new_from_string returns a document' );
	isa_ok( $doc, 'PPI::Document' );
	is( $doc->serialize, $code, 'new_from_string round-trips correctly' );
}

NEW_FROM_STRING_EMPTY: {
	my $doc = PPI::Document->new_from_string('');
	ok( $doc, 'new_from_string handles empty string' );
	isa_ok( $doc, 'PPI::Document' );
	is( $doc->serialize, '', 'empty string round-trips' );
}

NEW_FROM_STRING_UNDEF: {
	my $doc = PPI::Document->new_from_string(undef);
	ok( !$doc, 'new_from_string returns undef for undef input' );
}

NEW_FROM_STRING_UNICODE: {
	SKIP: {
		skip "Unicode support requires perl 5.8.7", 3 if $] < 5.008007;
		skip "Unicode-incompatible locale", 3 unless "\x{e4}" =~ /\w/;

		my $code = "my \$x = \"H\x{e9}llo\";\n";
		my $doc = PPI::Document->new_from_string($code);
		ok( $doc, 'new_from_string handles unicode characters' );
		isa_ok( $doc, 'PPI::Document' );
		is( $doc->serialize, $code,
			'new_from_string round-trips unicode' );
	}
}


#####################################################################
# new_from_file with encoding

NEW_FROM_FILE_UTF8: {
	SKIP: {
		skip "Unicode support requires perl 5.8.7", 4 if $] < 5.008007;

		my $file = catfile(qw( t data 30_encoding_api utf8.pl ));
		ok( -f $file, 'Found utf8.pl test file' );

		my $doc = PPI::Document->new_from_file(
			$file, encoding => 'UTF-8'
		);
		ok( $doc, 'new_from_file with encoding returns a document' );
		isa_ok( $doc, 'PPI::Document' );
		is( $doc->encoding, 'UTF-8',
			'encoding accessor returns the encoding' );
	}
}

NEW_FROM_FILE_LATIN1: {
	SKIP: {
		skip "Unicode support requires perl 5.8.7", 3 if $] < 5.008007;

		my $file = catfile(qw( t data 30_encoding_api latin1.pl ));
		ok( -f $file, 'Found latin1.pl test file' );

		my $doc = PPI::Document->new_from_file(
			$file, encoding => 'iso-8859-1'
		);
		ok( $doc,
			'new_from_file with latin1 encoding returns a document' );
		my $content = $doc->serialize;
		like( $content, qr/H\x{e9}llo/,
			'latin1 content decoded to characters' );
	}
}

NEW_FROM_FILE_MISSING: {
	my $doc = PPI::Document->new_from_file('nonexistent_file_12345.pl');
	ok( !$doc, 'new_from_file returns undef for missing file' );
}

NEW_FROM_FILE_UNDEF: {
	my $doc = PPI::Document->new_from_file(undef);
	ok( !$doc, 'new_from_file returns undef for undef filename' );
}


#####################################################################
# new_from_handle

NEW_FROM_HANDLE: {
	my $code = "print 1;\n";
	open my $fh, '<', \$code or die "Cannot open scalar ref: $!";
	my $doc = PPI::Document->new_from_handle($fh);
	close $fh;
	ok( $doc, 'new_from_handle returns a document' );
	isa_ok( $doc, 'PPI::Document' );
	is( $doc->serialize, $code,
		'new_from_handle round-trips correctly' );
}

NEW_FROM_HANDLE_UTF8: {
	SKIP: {
		skip "Unicode support requires perl 5.8.7", 3 if $] < 5.008007;

		my $file = catfile(qw( t data 30_encoding_api utf8.pl ));
		open my $fh, '<:encoding(UTF-8)', $file
			or die "Cannot open $file: $!";
		my $doc = PPI::Document->new_from_handle($fh);
		close $fh;
		ok( $doc,
			'new_from_handle with encoded fh returns a document' );
		isa_ok( $doc, 'PPI::Document' );
		like( $doc->serialize, qr/H\x{e9}llo/,
			'handle with encoding layer decodes content' );
	}
}

NEW_FROM_HANDLE_UNDEF: {
	my $doc = PPI::Document->new_from_handle(undef);
	ok( !$doc, 'new_from_handle returns undef for undef handle' );
}


#####################################################################
# encoding accessor

ENCODING_ACCESSOR: {
	PPI::Document->_clear;
	my $doc = safe_new \"my \$x = 1;";
	is( $doc->encoding, undef,
		'encoding is undef for documents without explicit encoding' );
}
