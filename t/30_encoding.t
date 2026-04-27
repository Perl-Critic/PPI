#!/usr/bin/perl

# Tests for encoding support in PPI::Document (GitHub issue #22)

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More;
BEGIN {
	if ($] < 5.008007) {
		Test::More->import( skip_all => "Unicode support requires perl 5.8.7" );
		exit(0);
	}
	plan( tests => 15 + ($ENV{AUTHOR_TESTING} ? 1 : 0) );
}

use utf8;
use File::Spec::Functions qw( catfile );
use File::Temp ();
use Encode ();
use PPI ();
use PPI::Document::File ();

sub _write_utf8_file {
	my ($code) = @_;
	my $utf8_bytes = Encode::encode('UTF-8', $code);
	my $tmp = File::Temp->new( SUFFIX => '.pl', UNLINK => 1 );
	binmode $tmp;
	print $tmp $utf8_bytes;
	close $tmp;
	return ($tmp, $utf8_bytes);
}


#####################################################################
# Test encoding parameter with PPI::Document->new($filename)
# "café" is 4 characters but 5 bytes in UTF-8. Without encoding
# support, PPI reads bytes, so the token content will have byte-level
# length (5 for the string, not 4).

ENCODING_FILE: {
	my ($tmp, $utf8_bytes) = _write_utf8_file(qq{my \$x = "caf\x{e9}";\n});

	local $TODO = 'encoding parameter not yet implemented';

	my $doc = PPI::Document->new( $tmp->filename, encoding => 'UTF-8' );
	ok( defined $doc, "Document loaded from UTF-8 file with encoding param" );

	SKIP: {
		skip "document not loaded", 2 unless $doc;
		my @strings = grep {
			$_->isa('PPI::Token::Quote::Double')
		} $doc->tokens;
		is( scalar @strings, 1, "found one string token" );
		is( length($strings[0]->content), length(qq{"caf\x{e9}"}),
			"string token has character-level length, not byte-level" );
	}
}


#####################################################################
# Test encoding parameter with PPI::Document::File

ENCODING_FILE_SUBCLASS: {
	my ($tmp) = _write_utf8_file(qq{my \$y = "\x{fc}ber";\n});

	local $TODO = 'encoding parameter not yet implemented';

	my $doc = PPI::Document::File->new( $tmp->filename, encoding => 'UTF-8' );
	ok( defined $doc, "Document::File loaded with encoding param" );
	SKIP: {
		skip "document not loaded", 1 unless $doc;
		isa_ok( $doc, 'PPI::Document::File' );
	}
}


#####################################################################
# Test UTF-8 file with wide characters in identifiers

ENCODING_WIDE_IDENTIFIERS: {
	my ($tmp) = _write_utf8_file(
		qq{use utf8;\nmy \$\x{e9}l\x{e8}ve = 1;\n}
	);

	local $TODO = 'encoding parameter not yet implemented';

	my $doc = PPI::Document->new( $tmp->filename, encoding => 'UTF-8' );
	ok( defined $doc, "Document with wide-char identifiers loaded" );

	SKIP: {
		skip "document not loaded", 2 unless $doc;
		my @symbols = grep {
			$_->isa('PPI::Token::Symbol')
		} $doc->tokens;
		ok( scalar @symbols, "found symbol tokens" );
		is( $symbols[0]->content, qq{\$\x{e9}l\x{e8}ve},
			"symbol contains decoded characters" );
	}
}


#####################################################################
# Test round-trip: load with encoding, save, reload

ENCODING_ROUND_TRIP: {
	my $code = qq{print "\x{263a}";\n};
	my ($tmp_in, $utf8_bytes) = _write_utf8_file($code);

	my $tmp_out = File::Temp->new( SUFFIX => '.pl', UNLINK => 1 );
	close $tmp_out;

	local $TODO = 'encoding parameter not yet implemented';

	my $doc = PPI::Document->new( $tmp_in->filename, encoding => 'UTF-8' );
	ok( defined $doc, "Document loaded for round-trip test" );

	SKIP: {
		skip "document not loaded", 2 unless $doc;
		my $saved = $doc->save( $tmp_out->filename );
		ok( $saved, "Document saved successfully" );
		open my $fh, '<:raw', $tmp_out->filename or die "open: $!";
		local $/;
		my $raw = <$fh>;
		close $fh;
		is( $raw, $utf8_bytes, "round-trip preserves UTF-8 bytes on disk" );
	}
}


#####################################################################
# Test that encoding accessor exists and returns the correct value

ENCODING_ACCESSOR: {
	local $TODO = 'encoding parameter not yet implemented';

	ok( PPI::Document->can('encoding'),
		"PPI::Document has encoding method" );
	SKIP: {
		skip "encoding method not available", 1
			unless PPI::Document->can('encoding');
		my $doc = PPI::Document->new( \"1;", encoding => 'UTF-8' );
		is( $doc->encoding, 'UTF-8',
			"encoding accessor returns correct value" );
	}
}


#####################################################################
# Backward compatibility: no encoding parameter still works

COMPAT_NO_ENCODING: {
	my $file = catfile('t', 'data', 'basic.pl');
	my $doc = PPI::Document->new( $file );
	ok( defined $doc,
		"Document loads without encoding param (backward compat)" );
	is( $doc->serialize, do {
		open my $fh, '<', $file or die "open: $!";
		local $/;
		<$fh>;
	}, "content matches raw file read" );
}
