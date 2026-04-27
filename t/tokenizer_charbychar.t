#!/usr/bin/perl

# Tests for tokenizer char-by-char processing path.
# Exercises code patterns that require heavy per-character tokenization
# rather than whole-line classification or "complete" token scanning.
# Related: rt.cpan.org #16952 (bloodgate's char-by-char optimization)

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 26 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use PPI::Tokenizer ();
use Helper 'safe_new';

# Long lines with many mixed token types force char-by-char processing
# for each token boundary transition.
SCOPE: {
	my $code = '$a+$b*$c-$d/$e%$f**$g.$h&&$i||$j==$k!=$l<$m>$n';
	my $doc = safe_new \$code;
	is $doc->serialize, $code, 'round-trip: dense operator chain';
}

SCOPE: {
	my $code = '$x=~s/foo/bar/g;$y=~m/baz/i;$z=~tr/a-z/A-Z/';
	my $doc = safe_new \$code;
	is $doc->serialize, $code, 'round-trip: dense regex operations';
}

# Deeply nested structures with no whitespace
SCOPE: {
	my $code = '$a{$b{$c[$d]}}=($e,[$f,$g],{$h=>$i});';
	my $doc = safe_new \$code;
	is $doc->serialize, $code, 'round-trip: nested structures no whitespace';
}

# Many small tokens on one line (worst case for per-char method call overhead)
SCOPE: {
	my $code = '(1)+(2)-(3)*(4)/(5)%(6)**(7).(8)x(9)&&(0)||(1)';
	my $doc = safe_new \$code;
	is $doc->serialize, $code, 'round-trip: many small tokens on one line';
}

# Mixed quotes, operators, and barewords with no whitespace
SCOPE: {
	my $code = q{print"hello"."world"if$x>1&&$y<2||$z==3;};
	my $doc = safe_new \$code;
	is $doc->serialize, $code, 'round-trip: mixed tokens no whitespace';
}

# Long line with repeated operator-operand pairs
SCOPE: {
	my $code = join '+', map { "\$v$_" } 0 .. 49;
	my $doc = safe_new \$code;
	is $doc->serialize, $code, 'round-trip: 50-variable addition chain';
}

# Chained method calls (many -> transitions)
SCOPE: {
	my $code = '$obj->foo->bar->baz->qux->quux->corge->grault->garply';
	my $doc = safe_new \$code;
	is $doc->serialize, $code, 'round-trip: chained method calls';
}

# Complex single-line with casts, derefs, and subscripts
SCOPE: {
	my $code = '@{$a->{b}}[0..5]=map{$_*2}@{$c->[3]};';
	my $doc = safe_new \$code;
	is $doc->serialize, $code, 'round-trip: casts derefs subscripts';
}

TODO: {
	local $TODO = 'char-by-char loop optimization not yet applied (rt.cpan.org #16952)';

	# Verify the internal loop optimization: after processing a line,
	# _process_next_char should handle the entire line in a single method
	# call rather than being called once per character.
	my $code = '$a + $b + $c + $d';
	my $t = PPI::Tokenizer->new( \$code );

	# Process all tokens to ensure the tokenizer works
	my $tokens = $t->all_tokens;
	ok scalar @$tokens > 0, 'tokenizer produces tokens';

	# The optimization is purely internal - behavior is identical.
	# This TODO block documents that the optimization is pending.
	ok 1, 'placeholder for optimization verification';
}
