#!/usr/bin/perl

# Tokenizer and lexer cases found by PCL (Perl to Common Lisp,
# https://github.com/Percolisp/pcl), one row per case, each checked against
# what perl itself does with the snippet.  The upstream copy of PCL's
# docs/ppi-bug-report.t; PCL's catalogue (docs/ppi-upstream-bugs.md) has a
# section per case, and every TODO below names that section.
#
# A row still inside a TODO block is a case this PPI gets wrong.  A fix
# removes the TODO block of exactly the rows it fixes.  Rows marked
# "(control)" are the neighbouring spelling PPI already gets right.

use lib 't/lib';
use PPI::Test::pragmas;
use utf8;
use Test::More tests => 91 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();

our $TODO;

# The descriptions below are UTF-8 (use utf8), and several snippets name
# variables in non-ASCII letters that their diagnostics print.
binmode $_, ':utf8' for Test::More->builder->output,
                        Test::More->builder->failure_output,
                        Test::More->builder->todo_output;

# A class name without its PPI::Token:: (or PPI::) prefix, for diagnostics.
sub short_class {
    my ($class) = @_;
    $class =~ s/^PPI::(?:Token::)?//;
    return $class;
}

# Whitespace runs collapsed to one space, for diagnostics.
sub squash {
    my ($s) = @_;
    $s =~ s/\s+/ /g;
    return $s;
}

# Significant tokens of a snippet, as "Class=content" strings.
sub toks {
    my $doc = PPI::Document->new(\$_[0]) or return ();
    return map { ref($_) . '=' . $_->content }
           grep { $_->significant } $doc->tokens;
}

# ── Bug 1: triple dereference $$$ref is mis-tokenized as the PID var $$ ────────
#
# $$$ref means ${ ${ $ref } } (a triple scalar deref).  Compare $$ref, which PPI
# correctly gives as Cast '$' + Symbol '$ref'.  For $$$ref PPI instead emits the
# special process-ID variable $$ (PPI::Token::Magic) + Symbol '$ref', so the
# extra dereference is lost and there is no PID variable in this code at all.
TODO: {
    local $TODO = 'PCL §1: $$$ref (triple dereference) tokenized as $$ + $ref';
    my @t = toks('$$$ref');
    ok( !grep(/^PPI::Token::Magic=\$\$$/, @t),
        '$$$ref should NOT tokenize as the PID variable $$ (it is a triple deref)' )
        or diag "got: @t";
}

# ── Bug 1b: $${EXPR} — the same mis-lex, plus a STRUCTURE error on the braces ──
#
# $${$ref} means ${ ${$ref} }.  PPI emits Magic '$$' again, and then — because
# the braces follow what it believes is a variable — structures them as a
# PPI::Structure::Subscript, i.e. a hash key.  Compare ${$ref}, which PPI
# correctly gives as Cast '$' + PPI::Structure::Block.  A consumer that repairs
# only the Magic still has a subscript with no base in front of it.
TODO: {
    local $TODO = 'PCL §1: $$$ref (triple dereference) tokenized as $$ + $ref';
    my $doc = PPI::Document->new(\'$${$ref}');
    my ($sub) = @{ $doc->find('PPI::Structure::Subscript') || [] };
    ok( !$sub,
        '$${$ref}: the braces are a deref BLOCK, not a Subscript' )
        or diag 'got a Subscript: ' . $sub->content;
}

# ── Bug 2: C99 hex-float literal 0x1.8p+1 is split into 5 tokens ───────────────
#
# Perl 5.22+ accepts hex floating-point literals; 0x1.8p+1 == 3.0 is ONE number.
# PPI splits it into  Number::Hex '0x1' + Number::Float '.8' + Word 'p' +
# Operator '+' + Number '1'.
TODO: {
    local $TODO = 'PCL §2: C99 hex-float literal 0x1.8p+1 split into 5 tokens';
    my @t = toks('my $n = 0x1.8p+1;');
    my @nums = grep { /^PPI::Token::Number/ } @t;
    is( scalar(@nums), 1,
        '0x1.8p+1 should be a single numeric token' )
        or diag "got: @t";
}

# ── Bug 3: 7%-3 mis-tokenized as the magic hash %- (modulo operator lost) ──────
#
# `%-`/`%+` are the named-capture magic *hashes*; they only ever appear in term
# position.  In `7%-3` the `%` follows a term (7) so it is the modulo operator
# and `-3` is its operand — exactly what PPI gives for the spaced form `7 % -3`.
# PPI instead emits Magic `%-`, losing the `%` operator.
{
    my @t = toks('7%-3');
    ok( !grep(/^PPI::Token::Magic=\%-$/, @t),
        '7%-3 should tokenize as 7 % -3, not as the magic hash %-' )
        or diag "got: @t";
}

# ── Bug 4: for ${*$f} (LIST) {} — LEXER DIES ("Illegal state in 'for' …") ──────
#
# A block-deref lvalue as the foreach loop variable is valid Perl (it aliases
# the glob's scalar slot per iteration):
#
#   $ perl -e 'no strict "refs"; my $f = "v"; for ${*$f} (5,11,33) { print "$v " }'
#   5 11 33
#
# (It appears in perl's own test suite: t/op/for.t, the low-refcount-package-var
# assert/SEGV regression test.)  PPI::Document->new returns undef on it —
# not a mis-tokenization but a hard lexer failure:
#   Lexer failed: Illegal state in 'for' compound statement
# Plain `for $x (…)` is fine; `foreach ${*$f} (…)` fails identically, as does
# the construct buried anywhere in a larger document (the whole parse dies).
TODO: {
    local $TODO = 'PCL §6: for ${*$f} (LIST) { } — LEXER DIES: "Illegal state in \'for\' compound statement"';
    my $src = 'no strict "refs"; my $f = "v"; for ${*$f} (5,11,33) { print }';
    my $doc = PPI::Document->new(\$src);
    ok( $doc,
        'for ${*$f} (LIST) {} should parse (valid Perl foreach lvalue)' )
        or diag "PPI errstr: " . PPI::Document->errstr;
}

# ── Bug 5: a VARIABLE declaration's attribute is not a Token::Attribute ────────
#
# `my $x : shared = 1;` is valid Perl (prints 1).  PPI produces a
# PPI::Token::Attribute for the same syntax on a SUB (`sub f : lvalue {…}`),
# but inside a PPI::Statement::Variable the attribute run comes back as a bare
# Operator ':' plus ordinary Words — indistinguishable from an unrelated
# expression fragment, so a consumer that supports `my $x <trailing expr>`
# silently takes ": shared = 1" as that expression.
TODO: {
    local $TODO = 'PCL §8: A variable declaration\'s ATTRIBUTE is not a Token::Attribute';
    my @t = toks('my $x : shared = 1;');
    ok( grep(/^PPI::Token::Attribute=/, @t),
        'my $x : shared = 1 should yield a Token::Attribute, as sub attributes do' )
        or diag "got: @t";
}

# ── Bug 6: ${ PUNCTUATION } is a variable, but lexes as Cast + Block ───────────
#
# Perl's ${ NAME } accepts a punctuation name, so @{+} IS the magic array @+
# (and ${!} is $!, %{+} is %+):
#
#   $ perl -e '"ab" =~ /(a)/; print "@{+}"'
#   a
#
# PPI already folds the IDENTIFIER spelling (@{foo} -> @foo) and the caret
# spelling, but leaves the punctuation ones as Cast + Block{lone Operator}.  A
# deref block holding exactly one Operator token can never be an expression, so
# the fold is unambiguous.
TODO: {
    local $TODO = 'PCL §9: ${ PUNCTUATION } is a variable, but lexes as Cast + Block';
    my @t = toks('@{+}');
    ok( !grep(/^PPI::Token::Structure=\{$/, @t),
        '@{+} should fold to the magic array @+, as @{foo} folds to @foo' )
        or diag "got: @t";
}

# ── Bug 7: `for` takes only [my] $scalar, and swallows the rest of the file ────
#
# Both of these are valid Perl — `for \my %e (@l)` (refaliasing, 5.22+) and
# `for my ($q, $r) (@l)` (n-at-a-time, 5.36+).  PPI's loop-variable slot accepts
# neither, and unlike bug 4 it does not fail loudly: the Statement::Compound
# keeps ONLY the keyword, and the rest of the construct plus every following
# statement up to the next ';' is swallowed into one flat sibling statement.  So
# a consumer sees a `for` with no list and no block, and loses unrelated code
# with it.  (Compare `for my $q (@l) { A() } print "x";`, which parses into two
# statements as expected.)
TODO: {
    local $TODO = 'PCL §10: for accepts only [my] $scalar as its loop variable';
    my $src = 'for my ($q, $r) (@l) { A() } print "x";';
    my $doc = PPI::Document->new(\$src);
    my ($first) = $doc ? $doc->schildren : ();
    ok( $doc && $first && $first->content =~ /\{/,
        'for my ($q,$r) (LIST) {…} should keep its list and block in the Compound' )
        or diag "compound was: " . ($first ? $first->content : '(no parse)');
}

# ── Bug 8: /PATTERN/ after a paren-less WORD is read as division ───────────────
#
# After a bareword that is not a known unary operator, perl expects a TERM, so
# the `/` starts a match against $_:
#
#   $ perl -e 'sub ok { print "ok(@_)\n" } $_ = "aa"; ok /a/, "desc"'
#   ok(1 desc)
#   $ perl -e '$_ = "aa"; print /a/, "\n"'      # print, a core list operator
#   1
#
# PPI already gets this right after `grep`, `return`, `(` and `=`, but after any
# other Word it emits Operator '/' + Word + Operator '/' — i.e. two divisions —
# so the match, and the whole argument list with it, is lost.  A consumer cannot
# recover it: the pattern's own text has been re-tokenized as code.
TODO: {
    local $TODO = 'PCL §11: /PATTERN/ after a paren-less WORD is tokenized as division';
    my @t = toks('ok /x/, "d";');
    ok( grep(/^PPI::Token::Regexp::Match=/, @t),
        '/x/ after a paren-less word should be a match, as it is after grep/return' )
        or diag "got: @t";
}
# The statement MODIFIERS are the same bug and the same fix: `if` and `unless`
# are right, `while` and `until` are not.  Their damage is worse than `ok`'s,
# because a `(…)` group inside the pattern puts PPI back in term position — so
# the CLOSING delimiter starts a match of its own and swallows the rest of the
# FILE into one token.
TODO: {
    local $TODO = 'PCL §11: /PATTERN/ after a paren-less WORD is tokenized as division';
    my $src = '1 while /(a+b?)x/g;' . "\n" . 'print "next\n";';
    my $doc = PPI::Document->new(\$src);
    my @st  = $doc ? $doc->schildren : ();
    is( scalar(@st), 2,
        '`1 while /(a+b?)x/g;` must not swallow the following statement' )
        or diag "statements: " . join(' | ', map { my $c = $_->content; $c =~ s/\n/\\n/g; $c } @st);
}
TODO: {
    local $TODO = 'PCL §11: /PATTERN/ after a paren-less WORD is tokenized as division';
    my @t = toks('1 while /b(?{$n++})c/g;');
    ok( grep(/^PPI::Token::Regexp::Match=/, @t),
        '/…/ after the `while` statement modifier should be a match' )
        or diag "got: @t";
}
# The control: `if` is the same grammatical position and PPI reads it right.
{
    my @t = toks('1 if /(a+b?)x/;');
    ok( grep(/^PPI::Token::Regexp::Match=/, @t),
        '/…/ after `if` IS lexed as a match (the control)' )
        or diag "got: @t";
}
# Bug 8b: the damage CASCADES, and it manufactures tokens that were never
# written.  Having passed the closing `/` PPI is back in TERM position, so the
# NEXT `/` opens a match that runs to the one after it — two adjacent `ok /…/`
# statements collapse into ONE, with the second `ok` buried inside a
# Regexp::Match token, and everything after them swallowed as well.
TODO: {
    local $TODO = 'PCL §11: /PATTERN/ after a paren-less WORD is tokenized as division';
    my $src = qq{sub ok { 1 }\n\$_ = 'aaabccc';\n ok /a+b?c+/, "one";\n}
            . qq{ ok /a*b?c*/, "two";\nprint "done\\n";\n};
    my $doc = PPI::Document->new(\$src);
    my @st  = $doc ? $doc->schildren : ();
    is( scalar(@st), 5,
        'two adjacent `ok /…/` statements must stay FIVE statements, not three' )
        or diag "statements: " . join(' | ',
            map { my $c = $_->content; $c =~ s/\n/\\n/g; $c } @st);
}
# …and the pattern text between the two delimiters is tokenized as CODE, so a
# `*` inside the SECOND pattern becomes a typeglob SYMBOL that appears nowhere
# in the source.  A consumer that repairs `)*name` (bug 9) will faithfully
# rewrite it, splicing a space into the middle of a regular expression.
TODO: {
    local $TODO = 'PCL §11: /PATTERN/ after a paren-less WORD is tokenized as division';
    my $src = qq{sub ok { 1 }\n\$_ = 'aaabccc';\n ok /a+b?c+/, "one";\n}
            . qq{ ok /a*b?c*/, "two";\n};
    my $doc = PPI::Document->new(\$src);
    my @sym = $doc ? grep { $_->isa('PPI::Token::Symbol') } $doc->tokens : ();
    is( join(',', map { $_->content } @sym), '$_',
        'no typeglob symbol may be manufactured out of the second pattern' )
        or diag "symbols: " . join(', ', map { $_->content } @sym);
}
# Bug 8c: the worst spelling of the same manufacture.  When the pattern starts
# with a QUOTE-LIKE LETTER, the token PPI builds after reading the `/` as
# division is a quote-like OPERATOR, and it swallows the closing delimiter and
# the rest of the file inside itself — so there is no closing-`/` token at all
# for a consumer to find.  perl reads `ok /q*/, "four";` as a match of `q*`
# against $_ and prints "ok - four".
TODO: {
    local $TODO = 'PCL §11: /PATTERN/ after a paren-less WORD is tokenized as division';
    my $src = qq{sub ok { 1 }\n\$_ = "zzz";\nok /q*/, "four";\n};
    my $doc = PPI::Document->new(\$src);
    my @t   = $doc ? map { ref } grep { $_->significant } $doc->tokens : ();
    ok( !grep(/^PPI::Token::Quote::Literal$/, @t),
        'a pattern starting with `q` must not become a Quote::Literal' )
        or diag "tokens: @t";
}
# …and the class of the manufactured token follows the LETTER: `m`/`s`/`y`/`tr`
# give a Regexp:: token instead of a Quote:: one, so a consumer cannot even key
# on one class.  `x` is not a quote-like letter and is lexed correctly, which is
# the control.
TODO: {
    local $TODO = 'PCL §11: /PATTERN/ after a paren-less WORD is tokenized as division';
    my %want = ('q'  => 'PPI::Token::Quote::Literal',
                'qq' => 'PPI::Token::Quote::Interpolate',
                'm'  => 'PPI::Token::Regexp::Match',
                's'  => 'PPI::Token::Regexp::Substitute',
                'y'  => 'PPI::Token::Regexp::Transliterate');
    my @bad;
    for my $letter (sort keys %want) {
        my $src = qq{sub ok { 1 }\n\$_ = "zzz";\nok /$letter*/, "four";\n};
        my $doc = PPI::Document->new(\$src);
        my @t   = $doc ? map { ref } grep { $_->significant } $doc->tokens : ();
        push @bad, "$letter -> $want{$letter}" if grep { $_ eq $want{$letter} } @t;
    }
    is( join(', ', @bad), '',
        'no quote-like letter at the head of a pattern may manufacture a quote token' );
}

# ── Bug 9: `)*name` is lexed as a GLOB instead of multiplication ──────────────
#
# A `*` where a term has just ENDED can only be multiplication; a glob starts
# where a TERM can.  perl agrees:
#
#   $ perl -e 'my ($s,$k)=(0,"ab"); $s += length($k)*length($k); print "$s\n"'
#   4
#
# PPI makes `*length` one Token::Symbol when the previous token ends a term —
# after `)`, `]`, a subscript `}`, a Symbol or a Quote.  With a NUMBER on the
# left (`2*length($k)`) or a single space (`) * length`) it is correct, which is
# what makes this easy to miss.  A consumer sees `Word List Symbol List` and has
# no way back: the multiplication is gone.
{
    my @t = toks('$s += length($k)*length($k);');
    ok( !grep(/^PPI::Token::Symbol=\*/, @t),
        ')*name after a term should be Operator(*) + Word, not a glob Symbol' )
        or diag "got: @t";
}

# ── Bug 10: parsing depends on $/ — a trailing __END__ gains a newline ────────
#
# `$/` is the input-record separator for READING; it has no business affecting
# how source text is tokenized.  With `$/` undef (slurp mode — what code that
# has just read the source with `local $/` leaves behind), a document whose last
# line is `__END__`/`__DATA__` comes back one byte longer: serialize is no
# longer the identity, and the DATA section gains a line the file never had.
TODO: {
    local $TODO = 'PCL §13: Tokenization of a trailing __END__/__DATA__ section depends on $/';
    my $src = "# c\n__END__\n";
    my $slurped = do { local $/; PPI::Document->new(\$src)->serialize };
    is( $slurped, $src,
        'serialize round-trips a trailing __END__ section regardless of $/' );
}

# ── Bug 11: <FH> / <glob> after a list operator or a block is lexed as < … > ──
#
# `<…>` in TERM position is a readline/glob wherever that position comes from.
# perl:
#
#   $ echo x | perl -e 'print <STDIN>'
#   x
#
# PPI gets it right after `=` and after a comma, and wrong after a
# list-operator Word (`sort <STDIN>`, `print <STDIN>`) or after a closing brace
# it took for the end of a term (`map { $h{$_}++ } <op/*>`), where it emits
# Operator('<') … Operator('>') — a comparison chain.  This is the same
# operator-vs-term error as bugs 8 and 9, in the third direction.
TODO: {
    local $TODO = 'PCL §14: <FH> / <glob> after a list operator or a block is lexed as < … >';
    my @t = toks('sort <STDIN>;');
    ok( grep(/^PPI::Token::QuoteLike::Readline=/, @t),
        '<STDIN> after a list operator should be a readline, as it is after a comma' )
        or diag "got: @t";
}
#
# THE CASCADE, which is the expensive half: once `>` has been taken for an
# operator, the NEXT `/` is in term position too, so it starts a match — and
# an unterminated one swallows the rest of the statement.
#
#   $ perl -e 'open(my $f,"<","/etc/hostname"); my $x = 1 ? <$f> // "" : ""; print $x'
#   <the first line of /etc/hostname>
#
TODO: {
    local $TODO = 'PCL §14: <FH> / <glob> after a list operator or a block is lexed as < … >';
    my @t = toks('my $x = $ok ? <$f> // "" : "";');
    ok( !grep(/^PPI::Token::Regexp::Match=/, @t),
        '`<$f> // ""` in a ternary branch: the // is defined-or, not an empty match' )
        or diag "got: @t";
}
TODO: {
    local $TODO = 'PCL §14: <FH> / <glob> after a list operator or a block is lexed as < … >';
    my @t = toks('my $x = $ok ? <$f> / 2 : 0;');
    ok( !grep(m{^PPI::Token::Regexp::Match=/ 2 : 0;$}, @t),
        '`<$f> / 2` in a ternary branch: the / is division, and must not eat the statement' )
        or diag "got: @t";
}
#
# THE CASCADE IS WORSE WHEN THE BODY IS A GLOB PATTERN, because the `/` that
# starts the match is INSIDE the diamond — so the closing `>` is swallowed too,
# and the match runs on to the next `/`, which is usually lines away:
#
#   $ ls ./nope-*-xyz ; perl -e 'my @f = sort <./nope-*-xyz>; print "ok\n"'
#   ok
#
# `sort <./nope-*-xyz>; print "y"; print "z";` is FOUR tokens to PPI, the last
# of them a Regexp::Match holding both prints.
TODO: {
    local $TODO = 'PCL §14: <FH> / <glob> after a list operator or a block is lexed as < … >';
    my @t = toks('my @f = sort <./nope-*-xyz>;');
    ok( grep(/^PPI::Token::QuoteLike::Readline=/, @t),
        '`sort <./nope-*-xyz>` — a `.`-relative glob pattern should be a readline token' )
        or diag "got: @t";
}
TODO: {
    local $TODO = 'PCL §14: <FH> / <glob> after a list operator or a block is lexed as < … >';
    my @t = toks('my @f = sort <./a-*>; print "y";');
    ok( !grep(m{^PPI::Token::Regexp::Match=/a-\*>; print "y";$}, @t),
        'the glob-pattern cascade must not swallow the statements that follow' )
        or diag "got: @t";
}

# ── Bug 12: `)` followed by -1 swallows the operator into a negative NUMBER ───
#
#   $ perl -e 'print( (1+2)-1 )'
#   2
#
# After `)` a term has ENDED, so `-` is an operator.  PPI emits Number('-1'),
# and the subtraction is gone: the consumer sees two adjacent terms.  With a
# space (`(1+2) - 1`) it is correct, which is what makes it easy to miss.
{
    my @t = toks('my $x = (1+2)-1;');
    ok( !grep(/^PPI::Token::Number=-1$/, @t),
        ')-1 should be Operator(-) + Number(1), not a negative literal' )
        or diag "got: @t";
}

# ── Bug 13: perl 5.40's `^^` (logical XOR) is two `^` operators ───────────────
#
# 5.40 added `^^`.  PPI emits Operator('^') twice, which is a different
# expression (bitwise XOR applied twice) and cannot be told apart from one.
{
    my @t = toks('my $r = $a ^^ $b;');
    ok( grep(/^PPI::Token::Operator=\^\^$/, @t),
        '^^ should be one logical-XOR operator token' )
        or diag "got: @t";
}

# ── Bug 14: a SUBSCRIPT after a deref / a KV slice gets the wrong structure ───
#
# `${$r}[0]` is element 0 of @$r and `%h{...}` (5.20+) is a key/value slice: the
# bracketed part SUBSCRIPTS what precedes it.  PPI builds Structure::Constructor
# (an anonymous arrayref) and Structure::Block (a code block) instead — while
# the sibling `@h{...}` correctly gets a Structure::Subscript.
TODO: {
    local $TODO = 'PCL §17: A SUBSCRIPT after a deref or a KV slice is structured as something else';
    my $doc = PPI::Document->new(\'my $v = ${$r}[0];');
    my @s = map { ref } @{ $doc->find(sub { $_[1]->isa('PPI::Structure') }) || [] };
    ok( (grep { $_ eq 'PPI::Structure::Subscript' } @s),
        '[0] after a braced deref should be a Subscript, not a Constructor' )
        or diag "got: @s";
}

# ── Bug 15: `finally {…}` is not part of the try statement, and eats the next ─
#
# With `use feature 'try'` in scope, `try {…} catch (VAR) {…} finally {…}` is
# ONE self-terminating statement.  PPI builds a Statement::Compound for the
# try/catch part and stops; `finally {…}` starts an unterminated statement that
# then swallows everything up to the next `;` — here, a whole assertion.
TODO: {
    local $TODO = 'PCL §18: finally { … } is not part of the try statement — and eats the next one';
    my $doc = PPI::Document->new(\<<'PERL');
use feature 'try';
try { foo(); } catch ($e) { bar($e); } finally { baz(); }
is($x, 1, 'desc');
PERL
    my @s = grep { $_->isa('PPI::Statement') } $doc->schildren;
    ok( (grep { $_->content =~ /^is\(/ } @s),
        'the statement after a finally block should be its own statement' )
        or diag "got: " . join(' | ', map { squash($_->content) } @s);
}

# ── Bug 16: a call to a sub named `x` is lexed as the repetition operator ────
#
# `x` is both an operator and a legal sub name, and perl decides by asking
# whether a complete TERM precedes it.  After a list operator there is none, so
# `print x(), "|\n"` calls x() — PPI counts the Word `print` as a term and
# emits Operator(x), which reads as "print $_ repeated () times".
TODO: {
    local $TODO = 'PCL §19: A call to a sub named x after a list operator is lexed as the repetition operator';
    my $doc = PPI::Document->new(\'sub x { "PKG" } print x(), "|\n";');
    my ($op) = grep { $_->isa('PPI::Token::Operator') && $_->content eq 'x' }
               $doc->tokens;
    ok( !$op, '`x` after a list operator should be a Word (a call), not an Operator' )
        or diag "got Operator(x) at: " . join(' ',
             map { ref($_) . '[' . $_->content . ']' }
             grep { $_->significant } $doc->tokens);
}
# ── Bug 16b: the same `x` STARTING a statement ──────────────────────────────
#
# `x` is INFIX, so a statement cannot begin with it — yet PPI begins one with it
# whenever the previous token is a sub definition's closing brace, which is
# exactly how a sub named `x` is called with neither parens nor arguments.
# perl's own t/op/lexsub.t writes `{ my sub x {…} x }` twice.
TODO: {
    local $TODO = 'PCL §19: A call to a sub named x after a list operator is lexed as the repetition operator';
    my $doc = PPI::Document->new(\'sub x { print "PKG\n" } x');
    my ($op) = grep { $_->isa('PPI::Token::Operator') && $_->content eq 'x' }
               $doc->tokens;
    ok( !$op, 'a statement cannot BEGIN with the infix `x` — it is a call' )
        or diag "got Operator(x) at: " . join(' ',
             map { ref($_) . '[' . $_->content . ']' }
             grep { $_->significant } $doc->tokens);
}
TODO: {
    local $TODO = 'PCL §19: A call to a sub named x after a list operator is lexed as the repetition operator';
    my $doc = PPI::Document->new(\'my sub x { print "LEX\n" } x');
    my ($op) = grep { $_->isa('PPI::Token::Operator') && $_->content eq 'x' }
               $doc->tokens;
    ok( !$op, 'the lexical-sub spelling lexes the same way (t/op/lexsub.t)' );
}
# The `;` spelling proves the intent: one added semicolon and PPI lexes the
# very same `x` as the Word it is.
{
    my $doc = PPI::Document->new(\'sub x { print "PKG\n" }; x');
    ok( (grep { $_->isa('PPI::Token::Word') && $_->content eq 'x' } $doc->tokens) >= 2,
        '`}; x` lexes the call as a Word (the control)' );
}

# ── Bug 17: only one of perl's three ways to enable `try` is recognised ──────
#
# `use feature 'try'`, `use experimental 'try'` and the version bundles
# `use v5.40` / `use 5.040` all enable the same feature in perl.  PPI knows only
# the first, so under the other two the construct lexes like the no-pragma case:
# ONE unterminated statement that swallows the statement after it.
TODO: {
    local $TODO = 'PCL §20: Two of perl\'s three ways to enable try are not recognised, so the construct mis-lexes';
    my $doc = PPI::Document->new(\<<'PERL');
use v5.40;
try { foo(); } catch ($e) { bar($e); }
is($x, 1, 'desc');
PERL
    my @s = grep { $_->isa('PPI::Statement') } $doc->schildren;
    ok( (grep { $_->content =~ /^is\(/ } @s),
        'a version bundle >= 5.39 should enable try (its bundle contains it)' )
        or diag "got: " . join(' | ', map { squash($_->content) } @s);
}
TODO: {
    local $TODO = 'PCL §20: Two of perl\'s three ways to enable try are not recognised, so the construct mis-lexes';
    my $doc = PPI::Document->new(\<<'PERL');
use experimental 'try';
try { foo(); } catch ($e) { bar($e); }
is($x, 1, 'desc');
PERL
    my @s = grep { $_->isa('PPI::Statement') } $doc->schildren;
    ok( (grep { $_->content =~ /^is\(/ } @s),
        "use experimental 'try' should enable try (it IS feature->import)" )
        or diag "got: " . join(' | ', map { squash($_->content) } @s);
}
# …and it must not answer about a feature it was not asked about: the
# experimental branch returns `signatures => 0` for ANY argument list, so this
# turns OFF the signatures the line before switched on.
TODO: {
    local $TODO = 'PCL §20: Two of perl\'s three ways to enable try are not recognised, so the construct mis-lexes';
    my $doc = PPI::Document->new(\"use feature 'signatures';\nuse experimental 'try';\n");
    my (undef, $exp) = @{ $doc->find('PPI::Statement::Include') || [] };
    my $mods = $exp->feature_mods || {};
    ok( !exists $mods->{signatures},
        "use experimental 'try' should say nothing about signatures" )
        or diag "got: " . join(', ', map { "$_=$mods->{$_}" } sort keys %$mods);
}

# ── Bug 20: a term-initial `~~` is lexed as the smart-match operator ─────────
# `~~` is the smart match only where an operator may stand.  Where a TERM is
# expected perl reads two complements — `~(~$x)`, the "numify" idiom that
# perl's own t/op/bop.t asserts twice.  PPI gives one Operator token in every
# position, so a statement that starts an argument with it has a binary
# operator with no left operand.  (PPI already makes exactly this
# term-or-not decision correctly for `x` and for `/PATTERN/`.)
TODO: {
    local $TODO = 'PCL §21: A term-initial ~~ is lexed as the smart-match operator';
    my $doc = PPI::Document->new(\'is(~~$y, 3);');
    my @ops = grep { $_->isa('PPI::Token::Operator') } $doc->tokens;
    ok( !(grep { $_->content eq '~~' } @ops),
        'a `~~` with no term before it should lex as two `~` complements' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}

# ── Bug 21: a filetest after a SCALAR filehandle is split into `-` + WORD ────
# `print FILEHANDLE LIST` takes a bareword, a scalar or a block as the handle,
# and a leading `-X` in the LIST is ONE filetest operator in all three (perl
# -MO=Deparse agrees).  PPI gets the bareword right and splits the scalar and
# block forms into Operator('-') + Word('e') — a subtraction of a call.  There
# is no competing reading to protect: `-e` cannot be a binary operator at all,
# and `$n -e $b` is a perl syntax error.  Adjacency is the discriminator —
# `print $fh - e $f` really IS `-(e($f))`, and perl honours the space.
TODO: {
    local $TODO = 'PCL §22: A filetest after a SCALAR filehandle is split into - + WORD';
    my $doc = PPI::Document->new(\'print $fh -e $f;');
    my @ops = grep { $_->isa('PPI::Token::Operator') } $doc->tokens;
    ok( (grep { $_->content eq '-e' } @ops),
        'a filetest after a scalar filehandle should lex as one `-e` operator' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# The block-handle form splits the same way…
TODO: {
    local $TODO = 'PCL §22: A filetest after a SCALAR filehandle is split into - + WORD';
    my $doc = PPI::Document->new(\'print {$x} -e $f;');
    my @ops = grep { $_->isa('PPI::Token::Operator') } $doc->tokens;
    ok( (grep { $_->content eq '-e' } @ops),
        'a filetest after a block filehandle should lex as one `-e` operator' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# …while the BAREWORD handle already lexes correctly — the inverse that shows
# the two paths disagree about the same operator.
{
    my $doc = PPI::Document->new(\'print STDERR -e $f;');
    my @ops = grep { $_->isa('PPI::Token::Operator') } $doc->tokens;
    ok( (grep { $_->content eq '-e' } @ops),
        'a filetest after a BAREWORD filehandle lexes as one `-e` (control)' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}

# ── Bug 22: a `$` scalar with a NON-ASCII name splits into Cast + Word ───────
# perl has allowed unicode identifiers since 5.8.  PPI reads them for every
# sigil except `$`: PPI/Token/Unknown.pm's `$` branch tests /[a-z_]/i where its
# `*`, `%`, `&` and `@` siblings test /[\w:]/.  The name itself is fine — once
# the token is classed Symbol, PPI::Token::Symbol consumes it with
# m/\G([\w:\']+)/gc.
TODO: {
    local $TODO = 'PCL §23: A $ scalar with a NON-ASCII name is split into Cast + Word';
    my $doc = PPI::Document->new(\"use utf8;\n\$\x{ff38} = 1;\n");
    my @sym = grep { $_->isa('PPI::Token::Symbol') } $doc->tokens;
    ok( (grep { $_->content eq "\$\x{ff38}" } @sym),
        'a scalar with a non-ASCII name should lex as one Symbol' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# The same name under `%` lexes correctly — the inverse that shows the two
# paths disagree about the same identifier.
{
    my $doc = PPI::Document->new(\"use utf8;\n%\x{ff38} = ();\n");
    my @sym = grep { $_->isa('PPI::Token::Symbol') } $doc->tokens;
    ok( (grep { $_->content eq "%\x{ff38}" } @sym),
        'a HASH with a non-ASCII name lexes as one Symbol (control)' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# Second-order: because the lexer sees a bareword, the subscript that follows
# is built as a BLOCK (and `[…]` as an anonymous-array constructor), so the
# statement is not a subscripted variable at all.
TODO: {
    local $TODO = 'PCL §23: A $ scalar with a NON-ASCII name is split into Cast + Word';
    my $doc = PPI::Document->new(\"use utf8;\n\$\x{ff38}{a} = 1;\n");
    ok( scalar @{ $doc->find('PPI::Structure::Subscript') || [] },
        'the `{…}` after a non-ASCII scalar should be a Subscript' )
        or diag "got: " . join(' ', map { ref($_) } grep { $_->significant } $doc->tokens);
}
# Same bug, worse consequence: a non-ASCII FOREACH loop variable makes the LEXER
# fail the whole document ("Illegal state in 'foreach' compound statement"),
# because the foreach-slot state machine sees the Cast the `$` split produced
# where it expects a Symbol.  `for (my $X=0;...)` and `while (my $X = ...)`
# lex fine.  PPI::Document->new returns undef, so no repair is possible.
TODO: {
    local $TODO = 'PCL §23: A $ scalar with a NON-ASCII name is split into Cast + Word';
    my $doc = PPI::Document->new(\"use utf8;\nfor my \$\x{ff29} (1,2) { 1 }\n");
    ok( defined $doc,
        'a foreach with a non-ASCII loop variable should lex at all' )
        or diag "errstr: " . (defined PPI::Document->errstr ? PPI::Document->errstr : '(none)');
}

# ── Bug 24: a PUNCTUATION-named array is split into Cast + Operator ───────────
#
# perl lets any punctuation character name a global, and real code writes them:
# t/re/subst.t:346 is `ok( ! @?, 'parsing of split subst with comment' );`.
# PPI has %MAGIC entries for the arrays perl documents (@-, @+, @*, @_, …) and
# its Symbol name regex is word-bounded, so every OTHER punctuation name falls
# through to the `@` CAST branch and the next character is tokenized alone.
#
# It is not a missing feature: in valid perl a `@` Cast is only ever followed by
# `$`, `{` or an identifier, so `Cast + Operator` is a parse of no legal program
# at all.  perl accepts @? @! @. @/ @~ @^ @& @% @= @< @> (probed, 5.40.3).
TODO: {
    local $TODO = 'PCL §24: A PUNCTUATION-named array @? is split into Cast + Operator';
    my $doc = PPI::Document->new(\'@? = (1,2);');
    my @sym = grep { $_->isa('PPI::Token::Symbol') } $doc->tokens;
    ok( (grep { $_->content eq '@?' } @sym),
        'a punctuation-named array `@?` should lex as one Symbol' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# The documented siblings prove the intent — @- and @+ ARE single Magic tokens,
# so the name rule is an enumeration where perl has a character class.
TODO: {
    local $TODO = 'PCL §24: A PUNCTUATION-named array @? is split into Cast + Operator';
    my $doc = PPI::Document->new(\'my $n = scalar(@!);');
    my @sym = grep { $_->isa('PPI::Token::Symbol') || $_->isa('PPI::Token::Magic') }
                   $doc->tokens;
    ok( (grep { $_->content eq '@!' } @sym),
        'a punctuation-named array `@!` should lex as one token, as `@-` does' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# The `%` sigil is worse, because there is no Cast to notice: `keys %?` comes
# out as Word(keys) Operator(%) Operator(?), i.e. a modulus of nothing.  perl
# decides by POSITION, and the surprise is which way it goes:
#
#   $ perl -e 'sub f { 7 } print f % 3, "\n"'
#   7                        # `%3, "\n"` is the HASH %3, passed to f
#   $ perl -e 'sub f { 7 } print f() % 3, "\n"'
#   1                        # after `)` a term has ended: modulo
TODO: {
    local $TODO = 'PCL §24: A PUNCTUATION-named array @? is split into Cast + Operator';
    my $doc = PPI::Document->new(\'my @k = keys %?;');
    my @sym = grep { $_->isa('PPI::Token::Symbol') } $doc->tokens;
    ok( (grep { $_->content eq '%?' } @sym),
        'a punctuation-named hash `%?` should lex as one Symbol after `keys`' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}

# ── Bug 25: `-name` after a token that ENDS A TERM is one negative-bareword ───
#
# The third sibling of bugs 12 (`)*name`) and 15 (`)-1`).  After a `)` a term
# has ended, so `-` is binary minus; the negative-bareword string form can only
# start where a TERM can.  perl -MO=Deparse gives `length('abc') - length('a')`.
# A space fixes the lexing, and PPI already makes exactly this operator-vs-term
# decision correctly for `x` and for `/PATTERN/`.
{
    my $doc = PPI::Document->new(\'my $z = length("abc")-length("a");');
    ok( !(grep { $_->isa('PPI::Token::Word') && $_->content eq '-length' } $doc->tokens),
        '`)-length` should lex as Operator(-) + Word(length), not one Word' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# The spaced spelling proves the intent: the SAME source with one blank added
# lexes the way perl reads both of them.
{
    my $doc = PPI::Document->new(\'my $z = length("abc") - length("a");');
    ok( (grep { $_->isa('PPI::Token::Operator') && $_->content eq '-' } $doc->tokens),
        '`) - length` lexes as a minus operator (the control)' );
}

# ── Bug 26: a glob named by PUNCTUATION or DIGITS is split into two tokens ────
#
# perl names a glob with whatever names a variable, and punctuation and digits
# name variables, so `*-`, `*!` and `*1` are globs.  perl's own test suite
# writes them: `*X = *-;` (t/re/reg_namedcapture.t:18) aliases the
# named-capture hash, `local *a = *1;` (t/re/subst.t:951) aliases $1.
#
#   $ perl -e '"X"=~/(?<X>X)/; our %X; *X = *-; print keys %X'
#   X
#
# PPI::Token::Symbol's name is word-bounded, so only `*word` is a Symbol; the
# rest arrive as Operator('*') + Operator/Number.  Same class as bug 24
# (`@?` → Cast + Operator), one sigil over.
TODO: {
    local $TODO = 'PCL §26: A glob whose NAME is punctuation or a digit run is split into two operators';
    my $doc = PPI::Document->new(\'our %X; *X = *-;');
    ok( (grep { $_->isa('PPI::Token::Symbol') && $_->content eq '*-' } $doc->tokens),
        '`*-` should lex as one Symbol, as `*foo` does' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
TODO: {
    local $TODO = 'PCL §26: A glob whose NAME is punctuation or a digit run is split into two operators';
    my $doc = PPI::Document->new(\'local *a = *1;');
    ok( (grep { $_->isa('PPI::Token::Symbol') && $_->content eq '*1' } $doc->tokens),
        '`*1` should lex as one Symbol — a digit run names a glob too' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# Two more spellings of the same bug.  `*^R` is perl's caret convention for the
# glob named chr(18) — the one `$^R` reads — so it is three tokens, not two:
#
#   $ perl -e 'our $s = "V"; *^R = *s; print $^R'
#   V
#
# and `*]` (t/op/tie_fetch_count.t:189) is the glob whose scalar slot is `$]`,
# where PPI hands the bracket over as a Token::Structure parked in a
# PPI::Statement::UnmatchedBrace.
TODO: {
    local $TODO = 'PCL §26: A glob whose NAME is punctuation or a digit run is split into two operators';
    my $doc = PPI::Document->new(\'*^R = *g;');
    ok( (grep { $_->isa('PPI::Token::Symbol') && $_->content eq '*^R' } $doc->tokens),
        '`*^R` should lex as one Symbol — the caret convention names a glob too' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
TODO: {
    local $TODO = 'PCL §26: A glob whose NAME is punctuation or a digit run is split into two operators';
    my $doc = PPI::Document->new(\'tie my $v => "main", *];');
    ok( (grep { $_->isa('PPI::Token::Symbol') && $_->content eq '*]' } $doc->tokens),
        '`*]` should lex as one Symbol — a closing bracket names the glob holding $]' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# And the SIGIL spelling, where NEITHER token is an Operator: `$@` is a
# variable, so `*@` is the glob that holds it — but `@` is also a sigil, so PPI
# makes both tokens Casts.  perl-tests/local.t:828 is `local *@;`.
#
#   $ perl -e 'eval { die "b\n" }; { local *@; } print "kept=[$@]"'
#   kept=[b
#   ]
TODO: {
    local $TODO = 'PCL §26: A glob whose NAME is punctuation or a digit run is split into two operators';
    my $doc = PPI::Document->new(\'local *@;');
    ok( (grep { $_->isa('PPI::Token::Symbol') && $_->content eq '*@' } $doc->tokens),
        '`*@` should lex as one Symbol — a sigil character names a glob too' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}

# ── Bug 27: ->symbol answers `%x` for the `$x` in `*$x{SLOT}` ────────────────
# NOT a mis-tokenization — the token stream for `*$x{SCALAR}` is right
# (Cast(*) Symbol($x) Structure::Subscript({SCALAR})).  It is ->symbol, the
# method documented to return "the ACTUAL symbol this token refers to", which
# resolves `$foo{…}` to `%foo` UNLESS a cast trumps the braces — and its cast
# set is `qw{ $ @ % }`, so `*` is missing.  But `*$x{SCALAR}` is perl's
# glob-slot syntax, `*{$x}{SCALAR}`, whose operand is the SCALAR $x:
#
#   $ perl -e 'our $n = "g"; *{$n} = \10; print ${*$n{SCALAR}}'
#   10
#
# and `*$x[0]{…}` is not valid perl at all, so braces after a `*` cast are
# never an element access.  Five sites in core Carp.pm depend on it
# (`*$_{HASH}`, `${*$_{SCALAR}}`), plus t/op/filetest.t, t/op/stat.t,
# t/op/gv.t and t/uni/parser.t.  One-token fix: add `*` to
# %cast_which_trumps_braces in PPI/Token/Symbol.pm.
TODO: {
    local $TODO = 'PCL §27: ->symbol answers %x for the $x in *$x{SLOT}';
    my $doc = PPI::Document->new(\'my $x = *$a{SCALAR};');
    my ($sym) = grep { $_->isa('PPI::Token::Symbol') && $_->content eq '$a' } $doc->tokens;
    is( ($sym ? $sym->symbol : '(no token)'), '$a',
        '`$a` under a `*` cast is the SCALAR $a — the glob-slot operand' );
}
TODO: {
    local $TODO = 'PCL §27: ->symbol answers %x for the $x in *$x{SLOT}';
    my $doc = PPI::Document->new(\'return *$_{HASH};');
    my ($sym) = grep { $_->isa('PPI::Token::Magic') && $_->content eq '$_' } $doc->tokens;
    is( ($sym ? $sym->symbol : '(no token)'), '$_',
        '`$_` under a `*` cast is $_, not %_ (core Carp.pm:34)' );
}

# ── Bug 28: `$x.2` — the `.` is absorbed into a Number::Float ────────────────
#
# The fourth sibling of bugs 12 (`)*name`), 15 (`)-1`) and 25 (`)-name`), and
# the same operator-vs-term decision.  perl starts a number at `.` only where a
# TERM is expected; after a complete term the `.` is concatenation, so `$_.2` is
# `$_ . 2` (perl -MO=Deparse says so).  PPI leaves NO operator in the stream at
# all, so a consumer sees two juxtaposed terms.  A space or a non-digit on the
# right fixes it — the bug needs the digit adjacent.
TODO: {
    local $TODO = 'PCL §28: $x.2 — a . followed by a digit after a term is lexed as a Number::Float, so the concatenation OPERATOR disappears';
    my $doc = PPI::Document->new(\'my $x = $_.2;');
    ok( !(grep { $_->isa('PPI::Token::Number') && $_->content eq '.2' } $doc->tokens),
        '`$_.2` should lex as Operator(.) + Number(2), not one Number::Float' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
TODO: {
    local $TODO = 'PCL §28: $x.2 — a . followed by a digit after a term is lexed as a Number::Float, so the concatenation OPERATOR disappears';
    my $doc = PPI::Document->new(\'my $z = $y[1].3;');
    ok( (grep { $_->isa('PPI::Token::Operator') && $_->content eq '.' } $doc->tokens),
        '`].3` should carry a concatenation operator' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# The spaced spelling proves the intent: the SAME source with one blank added
# lexes the way perl reads both of them.
{
    my $doc = PPI::Document->new(\'my $x = $_ . 2;');
    ok( (grep { $_->isa('PPI::Token::Operator') && $_->content eq '.' } $doc->tokens),
        '`$_ . 2` lexes as a concatenation operator (the control)' );
}
# …and the NEGATIVE, which PPI gets right and must keep getting right: where a
# TERM is expected, `.5` really is the number one half.
{
    my $doc = PPI::Document->new(\'my $x = .5;');
    ok( (grep { $_->isa('PPI::Token::Number') && $_->content eq '.5' } $doc->tokens),
        '`= .5` is the NUMBER 0.5 (the negative control)' );
}

# ── Bug 29: a DEREFERENCE as the foreach loop variable fails the LEXER ────────
#
# perl accepts any lvalue as the foreach loop variable; a dereference is the
# documented way to alias a symbol-ref target for the loop's duration:
#   our $z = 7; my $f = "z"; no strict "refs";
#   for $$f (5,11) { ... }        # perl: aliases $z, restores it afterwards
# PPI does not merely mis-tokenize these — PPI::Document->new returns undef
# ("Lexer failed: Illegal state in 'for' compound statement"), so the WHOLE
# FILE is lost.  The same dereference outside a for head lexes fine, so the
# fault is in the for-compound lexer's loop-variable slot.
TODO: {
    local $TODO = 'PCL §29: A DEREFERENCE as the foreach loop variable fails the LEXER: "Illegal state in \'for\' compound statement"';
    for my $src ('for $$f (1,2) { }',
                 'for ${$f} (1,2) { }',
                 'for ${*$f} (5,11,33) { }') {
        my $doc = PPI::Document->new(\$src);
        ok( defined $doc, "`$src` should lex (perl accepts a deref as the loop variable)" )
            or diag "errstr: " . PPI::Document->errstr;
    }
}
# The controls PPI gets right and must keep getting right.
{
    my $doc = PPI::Document->new(\'my $x = ${*$f};');
    ok( defined $doc, '`my $x = ${*$f};` lexes — the deref alone is fine (control)' );
}
{
    my $doc = PPI::Document->new(\'for $x (1,2) { }');
    ok( defined $doc, '`for $x (1,2) { }` lexes — a plain Symbol is fine (control)' );
}

# ── Bug 29a: a DECLARED REF as the foreach loop variable falls OUT of the
# compound ───────────────────────────────────────────────────────────────────
#
# The same for-compound lexer, one step milder.  `for my \$x (LIST) {…}` (the
# `declared_refs` feature, perl 5.26+) does not fail the lexer — it builds a
# Statement::Compound holding ONLY the two Words and leaves the loop variable,
# the list and the block in a SIBLING PPI::Statement, so the document exists
# and is silently wrong-shaped.  perl runs the loop, aliasing $x to each
# element's referent.
TODO: {
    local $TODO = 'PCL §29: A DEREFERENCE as the foreach loop variable fails the LEXER: "Illegal state in \'for\' compound statement"';
    for my $src ('for my \$x (\$main::y) { 1 }',
                 'foreach my \@a (\@main::b) { 1 }') {
        my $doc = PPI::Document->new(\$src) or do {
            fail("`$src` should lex at all"); next;
        };
        my ($cmp) = grep { $_->isa('PPI::Statement::Compound') } $doc->schildren;
        ok( $cmp && $cmp->find_any('PPI::Structure::List')
                 && $cmp->find_any('PPI::Structure::Block'),
            "`$src`: the list and the block belong INSIDE the for compound" )
            or diag "compound children: "
                  . ($cmp ? join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                          $cmp->schildren)
                          : "(no Statement::Compound at all)");
    }
}
# The control PPI gets right and must keep getting right: `my` plus a PLAIN
# symbol stays inside the compound.
{
    my $doc = PPI::Document->new(\'for my $x (1,2) { 1 }');
    my ($cmp) = grep { $_->isa('PPI::Statement::Compound') } $doc->schildren;
    ok( $cmp && $cmp->find_any('PPI::Structure::List')
             && $cmp->find_any('PPI::Structure::Block'),
        '`for my $x (1,2) { 1 }`: list and block inside the compound (control)' );
}

# ── Bug 30: an indented here-doc's INDENTATION over-counts when the delimiter
#            itself begins with whitespace, or is empty ──────────────────────
#
# perl strips the whitespace standing BEFORE the delimiter TEXT on the
# terminator line.  PPI::Token::HereDoc::_indent takes `^(\s*)` of the WHOLE
# terminator line, so `<<~' EOF'` counts the delimiter's own leading space as
# indentation (and `<<~''` counts the NEWLINE); _is_match_indent then fails and
# the body is left unstripped — or, when the body is indented as far as the
# over-count, it is stripped one character too many.
TODO: {
    local $TODO = 'PCL §30: An indented here-doc\'s INDENTATION is ^(\s*) of the whole terminator line, so a delimiter that begins with whitespace (or is empty) over-counts';
    for my $c (
      # [ source, what heredoc() should give, label ]
      [ "print <<~' EOF'\n  some data\n   EOF\n", "some data\n",
        "<<~' EOF' strips the 2 spaces before the delimiter" ],
      [ "print <<~' EOF '\n  some data\n   EOF \n", "some data\n",
        "<<~' EOF ' strips the 2 spaces before the delimiter" ],
      [ "print <<~\"  EOF\"\n    some data\n      EOF\n", "some data\n",
        '<<~"  EOF" strips the 4 spaces before the delimiter' ],
      [ "print <<~' EOF'\n   some data\n   EOF\n", " some data\n",
        "<<~' EOF' over a 3-space body leaves one space (no over-strip)" ],
      [ "print <<~''\n  some data\n  \n", "some data\n",
        "<<~'' strips the terminator line's 2 spaces" ],
    ) {
        my ($src, $want, $label) = @$c;
        my $doc = PPI::Document->new(\$src);
        my ($hd) = @{ $doc ? ($doc->find('PPI::Token::HereDoc') || []) : [] };
        is( ($hd ? join('', $hd->heredoc) : '(no here-doc token)'), $want, $label );
    }
}
# The CONTROL PPI gets right and must keep getting right: a delimiter with no
# leading whitespace.
{
    my $src = "print <<~EOF\n  some data\n  EOF\n";
    my $doc = PPI::Document->new(\$src);
    my ($hd) = @{ $doc->find('PPI::Token::HereDoc') || [] };
    is( join('', $hd->heredoc), "some data\n",
        '<<~EOF strips the terminator line indentation (control)' );
}
# The second face of the same bug: serialize() rebuilds each body line as
# `indentation . line`, so the over-count is ADDED and the document grows.
TODO: {
    local $TODO = 'PCL §30: An indented here-doc\'s INDENTATION is ^(\s*) of the whole terminator line, so a delimiter that begins with whitespace (or is empty) over-counts';
    my $src = "print <<~' EOF'\n  some data\n   EOF\n";
    my $doc = PPI::Document->new(\$src);
    is( $doc->serialize, $src,
        "a <<~' EOF' document round-trips through serialize" );
}

# ── Bug 31: `sub _ { … }` — the NAME `_` after `sub` is lexed as Token::Magic,
#            so no Statement::Sub is built and the NEXT statement is swallowed ─
#
# `_` is an ordinary subroutine name; it keeps its magic meaning (the stat
# buffer) only in filetest operand position.  PPI classifies it as
# Token::Magic everywhere, and PPI::Lexer's Statement::Sub rule needs a
# Token::Word there, so `sub _ { "x" } print 1;` becomes ONE plain
# PPI::Statement spanning both halves.
TODO: {
    local $TODO = 'PCL §31: sub _ { … } — the NAME _ after sub is lexed as Token::Magic, so no Statement::Sub is built and the FOLLOWING statement is swallowed';
    my $doc = PPI::Document->new(\q{sub _ { "x" } print 1;});
    my @st  = $doc->schildren;
    is( scalar @st, 2,
        'sub _ { … } and the statement after it are TWO statements' );
    is( ref($st[0]), 'PPI::Statement::Sub',
        'sub _ { … } lexes as a PPI::Statement::Sub' );
    my ($name) = grep { $_->content eq '_' } $doc->tokens;
    is( ref($name), 'PPI::Token::Word',
        'the `_` naming the sub is a Token::Word, not Token::Magic' );
}
# The forward declaration is the same shape.
TODO: {
    local $TODO = 'PCL §31: sub _ { … } — the NAME _ after sub is lexed as Token::Magic, so no Statement::Sub is built and the FOLLOWING statement is swallowed';
    my $doc = PPI::Document->new(\q{sub _; print 1;});
    my @st  = $doc->schildren;
    is( ref($st[0]), 'PPI::Statement::Sub',
        'sub _; lexes as a PPI::Statement::Sub' );
}
# The CONTROL: a QUALIFIED name with the same last segment lexes correctly, so
# the trigger really is the bare `_`.
{
    my $doc = PPI::Document->new(\q{sub main::_ { "x" } print 1;});
    my @st  = $doc->schildren;
    is( ref($st[0]), 'PPI::Statement::Sub',
        'sub main::_ { … } lexes as a PPI::Statement::Sub (control)' );
}

# ---------------------------------------------------------------------------
# 32.  `$)` under the `signatures` feature  (ppi-upstream-bugs.md 32)
#
# Once the feature is on, PPI decides `$` + `)` from FILE-REGION state rather
# than from "the tokenizer is inside a signature", so the magic variable `$)`
# is split EVERYWHERE -- and the stray `)` reaches the lexer, which uses it to
# close a structure.  `$(` is not affected, and without the pragma `$)` is a
# single Magic token.
TODO: {
    local $TODO = 'PCL §32: $) is tokenized as Symbol:$ + Structure:) ANYWHERE once the signatures feature is on';
    my $src = qq{use v5.36;\nmy \$e = \$);\n};
    my $doc = PPI::Document->new(\$src);
    my ($tok) = grep { $_->content eq '$)' } $doc->tokens;
    is( ref($tok), 'PPI::Token::Magic',
        '`$)` under the signatures feature is ONE Token::Magic' );
}
{
    # The structural damage: the stray `)` closes blocks that are not closed.
    my $src = qq{use v5.36;\nsub f {\n  if (1) {\n    my \$x = \$)\n  }\n  return 1;\n}\n};
    my $doc = PPI::Document->new(\$src);
    my @unmatched = grep { $_->isa('PPI::Statement::UnmatchedBrace') }
                    $doc->schildren;
    TODO: {
        local $TODO = 'PCL §32: $) is tokenized as Symbol:$ + Structure:) ANYWHERE once the signatures feature is on';
        is( scalar @unmatched, 0,
            '`$)` inside a nested block leaves no UnmatchedBrace statements' );
    }
    my @subs = grep { $_->isa('PPI::Statement::Sub') } $doc->schildren;
    is( scalar @subs, 1, 'the sub holding `$)` is still one Statement::Sub' );
}
{
    # The CONTROL: `$(` takes the correct branch in the same document.
    my $src = qq{use v5.36;\nmy \$g = \$(;\n};
    my $doc = PPI::Document->new(\$src);
    my ($tok) = grep { $_->content eq '$(' } $doc->tokens;
    is( ref($tok), 'PPI::Token::Magic',
        '`$(` under the same feature is a Token::Magic (control)' );
}

# §33 -- a `*` right after a compound statement's block is lexed as an
# OPERATOR when the block's last statement ends in a hash subscript, although
# the `}` ends the statement and the `*` starts a glob assignment.
TODO: {
    local $TODO = 'PCL §33: A * right after a BLOCK\'s } is lexed as MULTIPLICATION when the block\'s last statement ends in a hash subscript';
    my $src = qq{for (1) { \$h{\$_}; }\n*{"main::x"} = sub { 7 };\n};
    my $doc = PPI::Document->new(\$src);
    my ($tok) = grep { $_->content eq '*' } $doc->tokens;
    is( ref($tok), 'PPI::Token::Cast',
        '`*` after a block ending in `$h{$_};` is a Token::Cast' );
}

# §34 -- after a Float / Exp / Hex number, `-N` is taken as a negative NUMBER
# although the previous token ends a term (the integer tokenizer gets it right:
# `2-0.5` has its Operator).  perl: `1.5-0.5` is 1, `1e3-1` is 999.
for my $src ('1.5-0.5;', '1e3-1;') {
    my $doc = PPI::Document->new(\$src);
    my @ops = grep { $_->isa('PPI::Token::Operator') && $_->content eq '-' }
              $doc->tokens;
    is( scalar @ops, 1, "`$src` has a subtraction Operator token" );
}

# §35 -- a filetest right after a `BEGIN { … }` block is split into Operator(-)
# + Word, although the block's `}` ends the statement and `-e` starts a new
# one.  perl: `BEGIN { 1 } -e _; print "x\n"` prints x.
TODO: {
    local $TODO = 'PCL §35: A filetest right after a BEGIN { … } block on the same line is split into - + WORD';
    my $doc = PPI::Document->new(\'BEGIN { 1 } -e _; print "x\n";');
    my @ops = grep { $_->isa('PPI::Token::Operator') } $doc->tokens;
    ok( (grep { $_->content eq '-e' } @ops),
        'a filetest after a BEGIN block should lex as one `-e` operator' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}

# §36 -- the `[1]` of a braced element `${a}[1]` is lexed as an anonymous-array
# Constructor, while `${h}{k}` gets a Subscript.  perl: `@a = (1, 2, 3);
# print ${a}[1]` prints 2.
TODO: {
    local $TODO = 'PCL §36: The [i] of a braced element ${name}[i] is lexed as an anonymous-array CONSTRUCTOR';
    my $doc = PPI::Document->new(\q{@a = (1, 2, 3); print ${a}[1];});
    my ($st) = grep { $_->start && $_->start->content eq q{[} }
               @{ $doc->find(q{PPI::Structure}) || [] };
    is( ref($st), q{PPI::Structure::Subscript},
        q{the `[1]` after `${a}` is a Structure::Subscript} );
}

# §37 -- `print({$fh} LIST)`: PPI splits the parens' content into a compound
# statement holding the block plus a second statement (print, say), or makes the
# block an anonymous-hash Constructor followed directly by a term (printf).
# perl: `my $fh = \*STDOUT; print({$fh} "a", "b")` prints ab.
TODO: {
    local $TODO = 'PCL §37: print({$fh} LIST) -- the parenthesised block filehandle -- is split into two statements, or its block is a CONSTRUCTOR';
    my $doc = PPI::Document->new(\q{print({$fh} "a", "b");});
    my ($list) = @{ $doc->find(q{PPI::Structure::List}) || [] };
    my @st = $list->schildren;
    is( scalar @st, 1, q{the content of print({$fh} "a", "b") is ONE statement} );
    my $doc2 = PPI::Document->new(\q{printf({$fh} "%s", 1);});
    my ($br) = grep { $_->start && $_->start->content eq q[{] }
               @{ $doc2->find(q{PPI::Structure}) || [] };
    is( ref($br), q{PPI::Structure::Block},
        q{the {$fh} of printf({$fh} "%s", 1) is a Structure::Block} );
}

# §38 -- a statement that begins with `*$name` after a bare block whose first
# token is a scalar: the `*` is lexed as the multiplication Operator.
# perl: `{ my $c = 1; $c++ } *$o->{A} = 7;` stores into the glob's hash.
TODO: {
    local $TODO = 'PCL §38: A statement that begins with *$name after a bare block is lexed with a multiplication OPERATOR';
    my $doc = PPI::Document->new(\qq{{ \$c = \$b; }\n*\$o->{A} = 1;\n});
    my ($star) = grep { $_->content eq q{*} } $doc->tokens;
    is( ref($star), q{PPI::Token::Cast},
        q{the statement-initial `*` of `*$o->{A} = 1` after a block is a Cast} );
}
# §38, the code-sigil twin: `{ 1 while $x; } &$cb(7);` -- perl calls $cb.
TODO: {
    local $TODO = 'PCL §38: A statement that begins with *$name after a bare block is lexed with a multiplication OPERATOR';
    my $doc = PPI::Document->new(\qq{{ 1 while \$x; }\n&\$cb(7);\n});
    my ($amp) = grep { $_->content eq q{&} } $doc->tokens;
    is( ref($amp), q{PPI::Token::Cast},
        q{the statement-initial `&` of `&$cb(7)` after a block is a Cast} );
}
