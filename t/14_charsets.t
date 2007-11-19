#!/usr/bin/perl

BEGIN {
    if ($] < 5.008) {
        require Test::More;
        Test::More->import( skip_all => "Perl 5.8+ needed for Unicode support" );
        exit;
    }
}

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;
use Params::Util '_INSTANCE';
use Test::More tests => 11;
use utf8;

sub good_ok {
	my $source  = shift;
	my $message = shift;
	my $doc = PPI::Document->new( \$source );
	ok( _INSTANCE($doc, 'PPI::Document'), $message );
	if ( ! _INSTANCE($doc, 'PPI::Document') ) {
		diag($PPI::Document::errstr);
	}
}

#####################################################################
# Begin Tests

# We cannot reliably support Unicode on anything less than 5.8.5
SKIP: {
	eval { require 5.008005 };
	if ( $@ ) {
		skip( "Unicode support requires perl >= 5.8.5", 11 );
	}

	# In some (weird) cases with custom locales, things aren't words
	# that should be
	unless ( "ä" =~ /\w/ ) {
		skip( "Unicode-incompatible locale in use", 11 );
	}

	# Testing accented characters in UTF-8
	good_ok( 'sub func { }',           "Parsed code without accented chars" );
	good_ok( 'rätselhaft();',          "Function with umlaut"               );
	good_ok( '一();',                   "Function with Chinese characters"   );
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

}
