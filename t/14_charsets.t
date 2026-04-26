#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More;
BEGIN {
	if ($] < 5.008007) {
		Test::More->import( skip_all => "Unicode support requires perl 5.8.7" );
		exit(0);
	}
	plan( tests => 72 + ($ENV{AUTHOR_TESTING} ? 1 : 0) );
}

use utf8;  # perl version check above says this is okay
use Params::Util qw( _INSTANCE );
use PPI ();
use Helper 'safe_new';

sub good_ok {
	my $source  = shift;
	my $message = shift;
	my $doc = safe_new \$source;
	ok( _INSTANCE($doc, 'PPI::Document'), $message );
	if ( ! _INSTANCE($doc, 'PPI::Document') ) {
		diag($PPI::Document::errstr);
	}
}





#####################################################################
# Begin Tests

# We cannot reliably support Unicode on anything less than 5.8.5
SKIP: {
	# In some (weird) cases with custom locales, things aren't words
	# that should be
	unless ( "ä" =~ /\w/ ) {
		skip( "Unicode-incompatible locale in use (apparently)", 11 );
	}

	# Notorious test case.
	# In 1.203 this test case causes a memory leaking infinite loop
	# that consumes all available memory and then crashes the process.
	good_ok( '一();', "Function with Chinese characters" );

	# Byte order mark with no unicode content
	good_ok( "\xef\xbb\xbf1;\n", "BOM without actual unicode content" );

	# Testing accented characters in UTF-8
	good_ok( 'sub func { }',           "Parsed code without accented chars" );
	good_ok( 'rätselhaft();',          "Function with umlaut"               );
	good_ok( 'ätselhaft()',            "Starting with umlaut"               );
	good_ok( '"rätselhaft"',           "In double quotes"                   );
	good_ok( "'rätselhaft'",           "In single quotes"                   );
	good_ok( 'sub func { s/a/ä/g; }',  "Regex with umlaut"                  );
	good_ok( 'sub func { $ä=1; }',     "Variable with umlaut"               );
	good_ok( '$一 = "壹";',              "Variables with Chinese characters"  );
	good_ok( '$a=1; # ä is an umlaut', "Comment with umlaut"                );
	good_ok( <<'END_CODE',             "POD with umlaut"                    );
sub func { }

=pod

=head1 Umlauts like ä

} 
END_CODE

	ok(utf8::is_utf8('κλειδί'), "utf8 flag set on source string");
	good_ok( 'my %h = ( κλειδί => "Clé" );', "Hash with greek key in character string"          );
}

# Byte string tests (GitHub #226)
# Non-ASCII characters encoded as UTF-8 bytes without Perl's UTF-8 flag
SKIP: {
	unless ( "ä" =~ /\w/ ) {
		skip( "Unicode-incompatible locale in use (apparently)", 32 );
	}

	use Encode ();

	my $bytes = Encode::encode('utf8', 'use utf8; my %h = ( κλειδί => "Clé" );');
	ok(!utf8::is_utf8($bytes), "utf8 flag not set on greek byte string");
	good_ok( $bytes, "Hash with greek key in bytes string" );

	my $cyrillic_var = Encode::encode('utf8', 'my $дом = 1;');
	ok(!utf8::is_utf8($cyrillic_var), "utf8 flag not set on cyrillic var byte string");
	good_ok( $cyrillic_var, "Cyrillic scalar variable in bytes string" );

	my $czech_fat = Encode::encode('utf8', 'my %h = ( kůň => "horse" );');
	ok(!utf8::is_utf8($czech_fat), "utf8 flag not set on czech byte string");
	good_ok( $czech_fat, "Czech fat comma key in bytes string" );

	my $umlaut_func = Encode::encode('utf8', 'rätselhaft();');
	ok(!utf8::is_utf8($umlaut_func), "utf8 flag not set on umlaut func byte string");
	good_ok( $umlaut_func, "Function with umlaut in bytes string" );

	my $orig_issue = Encode::encode('utf8', 'my $дом = $_[0]; $дом =~ s/(\:\d+)$//; return $дом;');
	ok(!utf8::is_utf8($orig_issue), "utf8 flag not set on original issue byte string");
	good_ok( $orig_issue, "Original issue Cyrillic code in bytes string" );

	my $array_var = Encode::encode('utf8', 'my @données = (1, 2, 3);');
	ok(!utf8::is_utf8($array_var), "utf8 flag not set on array byte string");
	good_ok( $array_var, "Non-ASCII array variable in bytes string" );

	my $hash_var = Encode::encode('utf8', 'my %données = (a => 1);');
	ok(!utf8::is_utf8($hash_var), "utf8 flag not set on hash byte string");
	good_ok( $hash_var, "Non-ASCII hash variable in bytes string" );

	my $chinese_bytes = Encode::encode('utf8', '一();');
	ok(!utf8::is_utf8($chinese_bytes), "utf8 flag not set on chinese byte string");
	good_ok( $chinese_bytes, "Chinese function call in bytes string" );
}
