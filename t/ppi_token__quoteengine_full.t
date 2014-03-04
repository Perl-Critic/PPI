#!/usr/bin/perl

# Unit testing for PPI::Token::_QuoteEngine::Full

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 94;
use Test::NoWarnings;
use PPI;


NEW: {
	# Verify that Token::Quote, Token::QuoteLike and Token::Regexp
	# do not have ->new functions
	my $RE_SYMBOL  = qr/\A(?!\d)\w+\z/;
	foreach my $name ( qw{Token::Quote Token::QuoteLike Token::Regexp} ) {
		no strict 'refs';
		my @functions = sort
			grep { defined &{"${name}::$_"} }
			grep { /$RE_SYMBOL/o }
			keys %{"PPI::${name}::"};
		is( scalar(grep { $_ eq 'new' } @functions), 0,
			"$name does not have a new function" );
	}
}


# This primarily to ensure that qw() with non-balanced types
# are treated the same as those with balanced types.
QW: {
	my @seps   = ( undef, undef, '/', '#', ','  );
	my @types  = ( '()', '<>', '//', '##', ',,' );
	my @braced = ( qw{ 1 1 0 0 0 } );
	my $i      = 0;
	for my $q ('qw()', 'qw<>', 'qw//', 'qw##', 'qw,,') {
		my $d = PPI::Document->new(\$q);
		my $o = $d->{children}->[0]->{children}->[0];
		my $s = $o->{sections}->[0];
		is( $o->{operator},  'qw',      "$q correct operator"  );
		is( $o->{_sections}, 1,         "$q correct _sections" );
		is( $o->{braced}, $braced[$i],  "$q correct braced"    );
		is( $o->{separator}, $seps[$i], "$q correct separator" );
		is( $o->{content},   $q,        "$q correct content"   );
		is( $s->{position},  3,         "$q correct position"  );
		is( $s->{type}, $types[$i],     "$q correct type"      );
		is( $s->{size},      0,         "$q correct size"      );
		$i++;
	}
}


QW2: {
	my @stuff  = ( qw-( ) < > / / -, '#', '#', ',',',' );
	my @seps   = ( undef, undef, '/', '#', ','  );
	my @types  = ( '()', '<>', '//', '##', ',,' );
	my @braced = ( qw{ 1 1 0 0 0 } );
	my @secs   = ( qw{ 1 1 1 1 1 } );
	my $i      = 0;
	while ( @stuff ) {
		my $opener = shift @stuff;
		my $closer = shift @stuff;
		my $d = PPI::Document->new(\"qw${opener}a");
		my $o = $d->{children}->[0]->{children}->[0];
		my $s = $o->{sections}->[0];
		is( $o->{operator},  'qw',        "qw$opener correct operator"  );
		is( $o->{_sections}, $secs[$i],   "qw$opener correct _sections" );
		is( $o->{braced}, $braced[$i],    "qw$opener correct braced"    );
		is( $o->{separator}, $seps[$i],   "qw$opener correct separator" );
		is( $o->{content},   "qw${opener}a", "qw$opener correct content"   );
		if ( $secs[$i] ) {
			is( $s->{type}, "$opener$closer", "qw$opener correct type"	  );
		}
		$i++;
	}
}


OTHER: {
	foreach (
		[ '/foo/i',       'foo', undef, { i => 1 }, [ '//' ] ],
		[ 'm<foo>x',      'foo', undef, { x => 1 }, [ '<>' ] ],
		[ 's{foo}[bar]g', 'foo', 'bar', { g => 1 }, [ '{}', '[]' ] ],
		[ 'tr/fo/ba/',    'fo',  'ba',  {},         [ '//', '//' ] ],
		[ 'qr{foo}smx',   'foo', undef, { s => 1, m => 1, x => 1 },
							    [ '{}' ] ],
	) {
		my ( $code, $match, $subst, $mods, $delims ) = @{ $_ };
		my $doc = PPI::Document->new( \$code );
		$doc or warn "'$code' did not create a document";
		my $obj = $doc->child( 0 )->child( 0 );
		is( $obj->_section_content( 0 ), $match, "$code correct match" );
		is( $obj->_section_content( 1 ), $subst, "$code correct subst" );
		is_deeply( { $obj->_modifiers() }, $mods, "$code correct modifiers" );
		is_deeply( [ $obj->_delimiters() ], $delims, "$code correct delimiters" );
	}
}
