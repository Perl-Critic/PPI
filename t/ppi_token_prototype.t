#!/usr/bin/perl

# Unit testing for PPI::Token::Prototype

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::More tests => 801;
use Test::NoWarnings;
use PPI;


PARSING: {
	for my $name (
		'sub foo',
		'sub foo ',
		'sub',
		'sub ',
		'sub AUTOLOAD',
		'sub AUTOLOAD ',
		'sub DESTROY',
		'sub DESTROY ',
	) {
		for my $block ( '{1;}', ';' ) {
			for my $proto_and_expected (
				[ '',            '',            '' ],
				[ '()',          '()',          '' ],
				[ '( )',         '( )',         '' ],
				[ ' () ',,       '()',          '' ],
				[ '(+@)',        '(+@)',        '+@' ],
				[ ' (+@) ',      '(+@)',        '+@' ],
				[ '(\[$;$_@])',  '(\[$;$_@])',  '\[$;$_@]' ],
				[ '(\ [ $ ])',   '(\ [ $ ])',   '\[$]' ],
				[ '(\\\ [ $ ])', '(\\\ [ $ ])', '\\\[$]' ],  # nonsense, but perl accepts it
				[ '($ _ %)',     '($ _ %)',     '$_%' ],
				[ '( Z)',        '( Z)',        'Z' ],  # invalid chars in prototype
				[ '(!-=|)',      '(!-=|)',      '!-=|' ],  # invalid chars in prototype
				[ '(()',         '(()',         '(' ],  # perl refuses to compile this
			) {
				my ( $code_prototype, $expected_content, $expected_prototype ) = @$proto_and_expected;
				my $code = "$name$code_prototype$block";
				my $document = PPI::Document->new( \$code );
				isa_ok( $document, 'PPI::Document', $code );

				my $all_prototypes = $document->find( 'PPI::Token::Prototype' );
				if ( $code_prototype eq '' ) {
					is( $all_prototypes, "", "$code: got no prototypes" );
				}
				else {
					$all_prototypes = [] if !ref $all_prototypes;
					is( scalar(@$all_prototypes), 1, "$code: got exactly one prototype" );
					my $prototype_obj = $all_prototypes->[0];
					is( $prototype_obj, $expected_content, "$code: prototype object content matches" );
					is( $prototype_obj->prototype, $expected_prototype, "$code: prototype characters match" );
				}
			}
		}
	}
}
