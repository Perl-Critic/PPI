#!/usr/bin/perl

# Unit testing for PPI::Token::Magic

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 44 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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

HASH_SLASH: {
	local $TODO = '%/ not yet recognized as magic variable (GH #174)';
	my $doc = safe_new \q{is_deeply \%/, $target;};
	my $magic = $doc->find('PPI::Token::Magic');
	is( ref $magic, 'ARRAY', '%/ is parsed as PPI::Token::Magic' );
	is( $magic && $magic->[0], '%/', '%/ has the correct content' );
	my $regexps = $doc->find('PPI::Token::Regexp::Match');
	is( $regexps, '', 'No regexp tokens when parsing %/' );
}
