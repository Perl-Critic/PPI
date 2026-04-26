#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More;
BEGIN {
	if ($] < 5.008007) {
		Test::More->import( skip_all => "Unicode support requires perl 5.8.7" );
		exit(0);
	}
	plan( tests => 59 + ($ENV{AUTHOR_TESTING} ? 1 : 0) );
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
	use Encode ();
	my $bytes = Encode::encode('utf8', 'use utf8; my %h = ( κλειδί => "Clé" );');
	ok(!utf8::is_utf8($bytes), "utf8 flag not set on byte string");
	good_ok( $bytes, "Hash with greek key in bytes string" );

	# Byte strings with "use utf8" are auto-decoded by the tokenizer (issue #310)
	my $accented_bytes = Encode::encode('utf8', 'use utf8; my %hétéroclite = (bergère => 888);');
	ok(!utf8::is_utf8($accented_bytes), "utf8 flag not set on accented byte string");
	good_ok( $accented_bytes, "Accented identifiers in byte string with use utf8" );

	my $hash_access_bytes = Encode::encode('utf8', 'use utf8; $hétéroclite{bergère}++;');
	good_ok( $hash_access_bytes, "Accented hash access in byte string with use utf8" );

	my $sub_bytes = Encode::encode('utf8', 'use utf8; sub résumé { return 1; }');
	good_ok( $sub_bytes, "Accented sub name in byte string with use utf8" );

	# Round-trip: serialized output should match the decoded input
	my $rt_source = Encode::encode('utf8', 'use utf8; my $café = 1;');
	my $rt_doc = PPI::Document->new(\$rt_source);
	ok( _INSTANCE($rt_doc, 'PPI::Document'), "Round-trip: parsed accented byte string" );
	my $rt_got = $rt_doc->serialize;
	my $rt_expected = Encode::decode('utf8', $rt_source);
	is( $rt_got, $rt_expected, "Round-trip: serialized matches decoded source" );

	# Without "use utf8", byte strings with accented chars should still
	# parse (as individual bytes), not crash
	my $no_utf8_bytes = Encode::encode('utf8', 'my $x = "café";');
	good_ok( $no_utf8_bytes, "Byte string without use utf8 still parses" );
}
