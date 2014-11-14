#!/usr/bin/perl

# Unit testing for PPI::Token::Magic

use t::lib::PPI::Test::pragmas;
use Test::More tests => 39;

use PPI;


__TOKENIZER_ON_CHAR: {
	my $document = PPI::Document->new(\<<'END_PERL');
$[;                     # Magic  $[
$$;                     # Magic  $$
%-;                     # Magic  %-
$#-;                    # Magic  $#-
$$foo;                  # Symbol $foo   Dereference of $foo
$^W;                    # Magic  $^W
$^WIDE_SYSTEM_CALLS;    # Magic  $^WIDE_SYSTEM_CALLS
${^MATCH};              # Magic  ${^MATCH}
@{^_Bar};               # Magic  @{^_Bar}
${^_Bar}[0];            # Magic  @{^_Bar}
%{^_Baz};               # Magic  %{^_Baz}
${^_Baz}{burfle};       # Magic  %{^_Baz}
$${^MATCH};             # Magic  ${^MATCH}  Dereference of ${^MATCH}
\${^MATCH};             # Magic  ${^MATCH}
$0;                     # Magic  $0  -- program being executed
$0x2;                   # Magic  $0  -- program being executed
$10;                    # Magic  $10 -- capture variable
$1100;                  # Magic  $1100 -- capture variable
END_PERL

	isa_ok( $document, 'PPI::Document' );

	$document->index_locations();

	my $symbols = $document->find( 'PPI::Token::Symbol' );

	is( scalar(@$symbols), 18, 'Found the correct number of symbols' );
	my $comments = $document->find( 'PPI::Token::Comment' );

	foreach my $token ( @$symbols ) {
		my ($hash, $class, $name, $remk) =
			split /\s+/, $comments->[$token->line_number - 1], 4;
		isa_ok( $token, "PPI::Token::$class" );
		is( $token->symbol, $name, $remk || "The symbol is $name" );
	}
}
