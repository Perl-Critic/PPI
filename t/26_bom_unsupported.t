#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 9 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI::Document ();

{
	my $utf16_be = "\xfe\xff" . "p r i n t   1 ;";
	my $doc = PPI::Document->new(\$utf16_be);
	my $err = PPI::Document->errstr;
	PPI::Document->_clear;
	ok !$doc, "UTF-16 BE BOM: document not created";
	like $err, qr/UTF-16 is not supported/,
		"UTF-16 BE BOM: error message mentions UTF-16";
}

{
	my $utf16_le = "\xff\xfe" . "p\x00r\x00i\x00n\x00t\x00";
	my $doc = PPI::Document->new(\$utf16_le);
	my $err = PPI::Document->errstr;
	PPI::Document->_clear;
	ok !$doc, "UTF-16 LE BOM: document not created";
	like $err, qr/UTF-16 is not supported/,
		"UTF-16 LE BOM: error message mentions UTF-16";
}

{
	my $utf32_be = "\x00\x00\xfe\xff" . "\x00\x00\x00p";
	my $doc = PPI::Document->new(\$utf32_be);
	my $err = PPI::Document->errstr;
	PPI::Document->_clear;
	ok !$doc, "UTF-32 BE BOM: document not created";
	like $err, qr/UTF-32 is not supported/,
		"UTF-32 BE BOM: error message mentions UTF-32";
}

{
	my $utf8 = "\xef\xbb\xbf" . "print 1;";
	my $doc = PPI::Document->new(\$utf8);
	my $err = PPI::Document->errstr;
	PPI::Document->_clear;
	is $err, '', "UTF-8 BOM: no error";
	ok $doc, "UTF-8 BOM: document created successfully";
	isa_ok $doc, 'PPI::Document';
}
