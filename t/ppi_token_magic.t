#!/usr/bin/perl

# Unit testing for PPI::Token::Magic

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 79 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


MAGIC_SYMBOL_BOUNDARY: {
	my @cases = (
		[ '$_;',     'PPI::Token::Magic',  '$_'     ],
		[ '@_;',     'PPI::Token::Magic',  '@_'     ],
		[ '$_foo;',  'PPI::Token::Symbol', '$_foo'  ],
		[ '@_bar;',  'PPI::Token::Symbol', '@_bar'  ],
		[ '$::;',    'PPI::Token::Symbol', '$::'    ],
		[ '$::|;',   'PPI::Token::Magic',  '$::|'   ],
		[ '$::foo;', 'PPI::Token::Symbol', '$::foo' ],
		[ '@10;',    'PPI::Token::Magic',  '@10'    ],
	);

	for my $case (@cases) {
		my ($code, $expected_class, $expected_content) = @$case;
		my $doc = safe_new \$code;
		my $tokens = $doc->find( 'PPI::Token::Symbol' ) || [];
		is( scalar @$tokens, 1, "$expected_content: found one symbol-like token" );
		is( ref $tokens->[0], $expected_class, "$expected_content: correct class" );
		is( $tokens->[0]->content, $expected_content, "$expected_content: correct content" );
	}
}

__TOKENIZER_ON_CHAR: {
	my $document = safe_new \<<'END_PERL';
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
