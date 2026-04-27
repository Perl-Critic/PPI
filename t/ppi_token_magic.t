#!/usr/bin/perl

# Unit testing for PPI::Token::Magic

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 47 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI::Singletons '%MAGIC';

use PPI ();
use Helper 'safe_new';


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

DOLLAR_COLON_COLON_PIPE: {
	# GitHub #155: $::|=1; should NOT parse $::| as a magic variable.
	# $::| is not valid Perl syntax. The correct parse is $:: (Symbol)
	# followed by |= (Operator).
	my $TODO = "GitHub #155: \$::| is not a magic variable";
	my $doc = safe_new \q{$::|=1;};
	my @tokens = grep { $_->significant } $doc->child(0)->children;
	is( scalar @tokens, 4, "$TODO - four significant tokens" );
	is( ref $tokens[0], 'PPI::Token::Symbol', "$TODO - \$:: is a Symbol" );
	is( $tokens[0]->content, '$::', "$TODO - symbol content is \$::" );
	is( ref $tokens[1], 'PPI::Token::Operator', "$TODO - |= is an Operator" );
	is( $tokens[1]->content, '|=', "$TODO - operator content is |=" );
	ok( !$MAGIC{'$::|'}, "$TODO - \$::| is not in the MAGIC hash" );
}
