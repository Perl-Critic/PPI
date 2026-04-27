#!/usr/bin/perl

# Unit testing for interpolated_fragments() method on
# PPI::Token::Quote::Double, PPI::Token::Quote::Interpolate,
# and PPI::Token::HereDoc

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 71 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


DOUBLE_SIMPLE_SCALAR: {
	my $doc = safe_new \<<'END_PERL';
"Hello $name"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: simple scalar - one fragment' );
	isa_ok( $frags[0], 'PPI::Document::Fragment' );
	is( eval { $frags[0]->content }, '$name', 'Double: simple scalar - content' );
}


DOUBLE_SIMPLE_ARRAY: {
	my $doc = safe_new \<<'END_PERL';
"Hello @names"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: simple array - one fragment' );
	is( eval { $frags[0]->content }, '@names', 'Double: simple array - content' );
}


DOUBLE_MULTIPLE: {
	my $doc = safe_new \<<'END_PERL';
"$a and $b"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 2, 'Double: multiple - two fragments' );
	is( eval { $frags[0]->content }, '$a', 'Double: multiple - first content' );
	is( eval { $frags[1]->content }, '$b', 'Double: multiple - second content' );
}


DOUBLE_NO_INTERPOLATION: {
	my $doc = safe_new \<<'END_PERL';
"just text"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 0, 'Double: no interpolation' );
}


DOUBLE_ESCAPED_SIGIL: {
	my $doc = safe_new \<<'END_PERL';
"Hello \$name"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 0, 'Double: escaped sigil - no fragments' );
}


DOUBLE_ESCAPED_BACKSLASH: {
	my $doc = safe_new \<<'END_PERL';
"Hello \\$name"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: escaped backslash - one fragment' );
	is( eval { $frags[0]->content }, '$name', 'Double: escaped backslash - content' );
}


DOUBLE_HASH_SUBSCRIPT: {
	my $doc = safe_new \<<'END_PERL';
"Hello $hash{key}"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: hash subscript - one fragment' );
	is( eval { $frags[0]->content }, '$hash{key}', 'Double: hash subscript - content' );
}


DOUBLE_ARRAY_SUBSCRIPT: {
	my $doc = safe_new \<<'END_PERL';
"Hello $array[0]"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: array subscript - one fragment' );
	is( eval { $frags[0]->content }, '$array[0]', 'Double: array subscript - content' );
}


DOUBLE_ARROW_DEREF: {
	my $doc = safe_new \<<'END_PERL';
"Hello $ref->{key}"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: arrow deref - one fragment' );
	is( eval { $frags[0]->content }, '$ref->{key}', 'Double: arrow deref - content' );
}


DOUBLE_BRACED_SCALAR: {
	my $doc = safe_new \<<'END_PERL';
"Hello ${name}"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: braced scalar - one fragment' );
	is( eval { $frags[0]->content }, '${name}', 'Double: braced scalar - content' );
}


DOUBLE_COMPLEX_EXPR: {
	my $doc = safe_new \<<'END_PERL';
"Total: ${\ $a + $b }"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: complex expr - one fragment' );
	is( eval { $frags[0]->content }, '${\ $a + $b }', 'Double: complex expr - content' );
}


DOUBLE_ARRAY_EXPR: {
	my $doc = safe_new \<<'END_PERL';
"Items: @{[ @list ]}"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: array expr - one fragment' );
	is( eval { $frags[0]->content }, '@{[ @list ]}', 'Double: array expr - content' );
}


DOUBLE_MAGIC: {
	my $doc = safe_new \<<'END_PERL';
"PID: $$"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: magic var - one fragment' );
	is( eval { $frags[0]->content }, '$$', 'Double: magic var - content' );
}


DOUBLE_NAMESPACED: {
	my $doc = safe_new \<<'END_PERL';
"Hello $Foo::bar"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'Double: namespaced - one fragment' );
	is( eval { $frags[0]->content }, '$Foo::bar', 'Double: namespaced - content' );
}


DOUBLE_FRAGMENT_TYPES: {
	my $doc = safe_new \<<'END_PERL';
"Hello $name"
END_PERL
	my $token = $doc->find_first('Token::Quote::Double');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	my $symbols = eval { $frags[0]->find('Token::Symbol') } || [];
	is( scalar @{$symbols}, 1, 'Double: fragment contains one Symbol' );
	is( eval { $symbols->[0]->content }, '$name', 'Double: fragment Symbol content' );
}


QQ_SIMPLE: {
	my $doc = safe_new \<<'END_PERL';
qq{Hello $name}
END_PERL
	my $token = $doc->find_first('Token::Quote::Interpolate');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'qq{}: simple - one fragment' );
	is( eval { $frags[0]->content }, '$name', 'qq{}: simple - content' );
}


HEREDOC_INTERPOLATE: {
	my $doc = safe_new \<<'END_PERL';
my $x = <<EOT;
Hello $name
EOT
END_PERL
	my $token = $doc->find_first('Token::HereDoc');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 1, 'HereDoc: interpolate - one fragment' );
	is( eval { $frags[0]->content }, '$name', 'HereDoc: interpolate - content' );
}


HEREDOC_LITERAL: {
	my $doc = safe_new \<<'END_PERL';
my $x = <<'EOT';
Hello $name
EOT
END_PERL
	my $token = $doc->find_first('Token::HereDoc');
	local $TODO = "interpolated_fragments not yet implemented";
	my @frags = eval { $token->interpolated_fragments };
	is( scalar @frags, 0, 'HereDoc: literal - no fragments' );
}
