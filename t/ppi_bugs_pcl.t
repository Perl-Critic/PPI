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
use Test::More tests => 266 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

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
{
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
{
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
{
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
{
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
{
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
{
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
{
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
{
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
{
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
{
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
{
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
{
    my $doc = PPI::Document->new(\'print $fh -e $f;');
    my @ops = grep { $_->isa('PPI::Token::Operator') } $doc->tokens;
    ok( (grep { $_->content eq '-e' } @ops),
        'a filetest after a scalar filehandle should lex as one `-e` operator' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# The block-handle form splits the same way…
{
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
{
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
{
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
{
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
{
    my $doc = PPI::Document->new(\'@? = (1,2);');
    my @sym = grep { $_->isa('PPI::Token::Symbol') } $doc->tokens;
    ok( (grep { $_->content eq '@?' } @sym),
        'a punctuation-named array `@?` should lex as one Symbol' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
# The documented siblings prove the intent — @- and @+ ARE single Magic tokens,
# so the name rule is an enumeration where perl has a character class.
{
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
{
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
{
    my $doc = PPI::Document->new(\'our %X; *X = *-;');
    ok( (grep { $_->isa('PPI::Token::Symbol') && $_->content eq '*-' } $doc->tokens),
        '`*-` should lex as one Symbol, as `*foo` does' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
{
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
{
    my $doc = PPI::Document->new(\'*^R = *g;');
    ok( (grep { $_->isa('PPI::Token::Symbol') && $_->content eq '*^R' } $doc->tokens),
        '`*^R` should lex as one Symbol — the caret convention names a glob too' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
{
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
{
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
{
    my $doc = PPI::Document->new(\'my $x = *$a{SCALAR};');
    my ($sym) = grep { $_->isa('PPI::Token::Symbol') && $_->content eq '$a' } $doc->tokens;
    is( ($sym ? $sym->symbol : '(no token)'), '$a',
        '`$a` under a `*` cast is the SCALAR $a — the glob-slot operand' );
}
{
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
{
    my $doc = PPI::Document->new(\'my $x = $_.2;');
    ok( !(grep { $_->isa('PPI::Token::Number') && $_->content eq '.2' } $doc->tokens),
        '`$_.2` should lex as Operator(.) + Number(2), not one Number::Float' )
        or diag "got: " . join(' ', map { short_class(ref $_) . "[" . $_->content . "]" }
                                    grep { $_->significant } $doc->tokens);
}
{
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
{
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
{
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
{
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
{
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
{
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
{
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
{
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
    {
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
{
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
{
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
{
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
{
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
{
    my $doc = PPI::Document->new(\qq{{ \$c = \$b; }\n*\$o->{A} = 1;\n});
    my ($star) = grep { $_->content eq q{*} } $doc->tokens;
    is( ref($star), q{PPI::Token::Cast},
        q{the statement-initial `*` of `*$o->{A} = 1` after a block is a Cast} );
}
# §38, the code-sigil twin: `{ 1 while $x; } &$cb(7);` -- perl calls $cb.
{
    my $doc = PPI::Document->new(\qq{{ 1 while \$x; }\n&\$cb(7);\n});
    my ($amp) = grep { $_->content eq q{&} } $doc->tokens;
    is( ref($amp), q{PPI::Token::Cast},
        q{the statement-initial `&` of `&$cb(7)` after a block is a Cast} );
}

# ── Bug 55: a method name, a postfix ++/--, and a subscript's } END A TERM ──
#
#   $ perl -e 'package O; sub w {10} package main; my $o = bless {}, "O";
#              sub w {2} my %h = (a => 5); my $i = 5;
#              print $o->w*w(), " ", $i++*w(), " ", $h{a}%-1, "\n"'
#   20 10 0
#
# After a term perl expects an operator (toke.c: PL_expect is XOPERATOR).  PPI
# knows that for a symbol, a number, a quote and a closing ) or ], but not
# for three other ends of a term: a method name after -> (a Word), a postfix
# ++ or -- (an Operator), and the } of a subscript or of a dereference block.
# After them PPI lexes *w as a glob, %- as the magic hash, .2 and -1 as
# numbers and / as the start of a match.  Rows marked (control) are the
# spellings where a term has NOT ended and that must keep their meaning.
{
    my @rows = (
        [ '$o->w*w()',      'Operator=*', 'a method name ends a term: * multiplies' ],
        [ '$o->name.2',     'Operator=.', 'a method name ends a term: . concatenates' ],
        [ '$o->w-1',        'Operator=-', 'a method name ends a term: - subtracts' ],
        [ '$o->h%-1',       'Operator=%', 'a method name ends a term: % is modulo' ],
        [ '$i++*f()',       'Operator=*', 'a postfix ++ ends a term: * multiplies' ],
        [ '$i++ / 2',       'Operator=/', 'a postfix ++ ends a term: / divides' ],
        [ '$i++.2',         'Operator=.', 'a postfix ++ ends a term: . concatenates' ],
        [ '$i--%-1',        'Operator=%', 'a postfix -- ends a term: % is modulo' ],
        [ '$h{a}*f()',      'Operator=*', "a subscript's } ends a term: * multiplies" ],
        [ '$h{a}%-1',       'Operator=%', "a subscript's } ends a term: % is modulo" ],
        [ '$x->{a}{b}*f()', 'Operator=*', "a chained subscript's } ends a term" ],
        [ '@{$h}*$x',       'Operator=*', "a dereference block's } ends a term: * multiplies" ],
        [ '${$x}%$y',       'Operator=%', "a dereference block's } ends a term: % is modulo" ],
        [ 'do { 1 }*f()',   'Operator=*', "do BLOCK's } ends a term: * multiplies" ],
        [ 'print {$fh} .5',      'Number::Float=.5', "a block filehandle's } does not end a term: .5 is a number" ],
    );
    my @controls = (
        [ '++$i*$x',               'Symbol=$i',     'a prefix ++ opens a term (control)' ],
        [ 'sub f {} *bar = \&f;',  'Symbol=*bar',   "after a sub body's } a glob starts the statement (control)" ],
        [ 'if ($x) { } *g = \&f;', 'Symbol=*g',     "after a block's } a glob starts the statement (control)" ],
        [ 'map { $_ } *STDOUT',    'Symbol=*STDOUT', "after map's block a glob is the list (control)" ],
        [ 'print $fh %h',          'Symbol=%h',     'after a scalar filehandle a hash is the list (control)' ],
        [ 'foo *bar',              'Symbol=*bar',   'after a plain word a glob is its argument (control)' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
    for my $r (@controls) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}

# §55, the block-after-block case: a { right after a block's } opens the next
# BLOCK, not a subscript, so a glob after the second block starts the next
# statement (perl-tests/array.t: `{ ... }\n\n{ ... }\n\n*trit = *scile;`).
{
    my @t = map { short_class($_) } toks('{ my $y = 1; } { my %h; } *trit = *scile;');
    ok( grep( $_ eq 'Symbol=*trit', @t ),
        'a glob after two consecutive blocks starts the next statement' )
        or diag "got: @t";
}
{
    my @t = map { short_class($_) } toks('${$r}{a}*f()');
    ok( grep( $_ eq 'Operator=*', @t ),
        "a subscript after a dereference block ends a term: * multiplies (control)" )
        or diag "got: @t";
}

# §21, after a BLOCK: the } of a block does not end a term, so a ~~ after it
# is two complements.  perl -e 'my $y = 3; my @a = map { $_ } ~~$y; print "@a"'
# prints 3, and so does print {$fh} ~~$y.  After a SCALAR filehandle perl reads
# the smart match (print $fh ~~$y prints the empty string), and after a
# subscript's } too.
{
    my @rows = (
        [ 'my @a = map { $_ } ~~$y;', 1, "after map's block ~~ is two complements" ],
        [ 'print {$fh} ~~$y;',        1, 'after a block filehandle ~~ is two complements' ],
        [ 'if ($x) { 1 } ~~$y;',      1, "after a compound statement's block ~~ is two complements" ],
        [ 'print $fh ~~$y;',          0, 'after a scalar filehandle ~~ is the smart match, as perl reads it (control)' ],
        [ '$h{a} ~~ @a',              0, "after a subscript's } ~~ is the smart match (control)" ],
    );
    for my $r (@rows) {
        my ( $code, $split, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        my $smart = grep( $_ eq 'Operator=~~', @t );
        ok( $split ? !$smart : $smart, "$code: $desc" ) or diag "got: @t";
    }
}

# §24, every punctuation name: perl accepts @X and %X for each of these
# characters in term position (probed 5.40.3, `scalar(@X)` / `scalar(%X)`),
# as it accepts $X.  A @ cast is only ever followed by $, { or a name, so
# there is no second reading; after a term a % is still the modulo operator.
{
    my @names = ( map( "\@$_", split //, q{!./~&%=<>,|@\\} ),
                  map( "%$_",  split //, q{?./~&%=<>,|@\\} ) );
    for my $name (@names) {
        my $code = "my \@k = (scalar($name));";
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq "Magic=$name", @t ), "`$name` in term position is one Magic token" )
            or diag "got: @t";
    }
    my @controls = (
        [ '$x %= 3;',   'Operator=%=', 'after a term %= is the assignment operator (control)' ],
        [ '$h{a}%.5;',  'Operator=%',  'after a subscript % is modulo, .5 a number (control)' ],
        [ '$z = 7 %.5;', 'Operator=%',  'after a number % is modulo (control)' ],
        [ 'my $n = @{$r};', 'Cast=@',  'a @ before { stays a cast (control)' ],
    );
    for my $r (@controls) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}

# §55, a builtin that takes no operand is a whole TERM: time, wait,
# wantarray, fork, getppid, ... (perl -e 'print time.2' prints the time
# with a 2 appended; `time %.5e1` is a modulo).  After one of them the
# tokenizer is in operator position.
{
    my @rows = (
        [ '$t = time %.5e1;', 'Operator=%', 'after time % is modulo' ],
        [ '$t = time.2;',     'Operator=.', 'after time . concatenates' ],
        [ '$t = wait-1;',     'Operator=-', 'after wait - subtracts' ],
        [ '$t = time %~$y;',  'Operator=%', 'after time %~ is modulo of a complement' ],
        [ '$t = time*f();',   'Operator=*', 'after time * multiplies' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
    my @t = map { short_class($_) } toks('my %h = (time => 1);');
    ok( grep( $_ eq 'Word=time', @t ), 'time before => stays a word (control)' ) or diag "got: @t";
}

# §24, the caret: perl -e '@^ = (1,2); print scalar(@^)' prints 2.  The
# hash spelling %^ stays two tokens here: a % before ^ starts the caret
# names (%^H), and only %^H is one.
{
    my @t = map { short_class($_) } toks('my @k = (scalar(@^));');
    ok( grep( $_ eq 'Magic=@^', @t ), '`@^` in term position is one Magic token' )
        or diag "got: @t";
}
{
    my @t = map { short_class($_) } toks('my $n = scalar(%^H);');
    ok( grep( $_ eq 'Magic=%^H', @t ), '`%^H` stays one Magic token (control)' )
        or diag "got: @t";
}

# §22 and §35, the rest of the rule.  perl reads a - as the start of a TERM
# (toke.c: PL_expect = XTERM) in two places where PPI's operator context says
# subtraction: in the filehandle slot of print $fh LIST, when whitespace
# stands before the - and none after it (perl -e 'print $fh -1' prints -1 to
# $fh), and after the } of a block that ends a statement or takes a list
# (BEGIN { 1 } -e $f, { 1 } -e $f, sort { $a <=> $b } -1, 2).
{
    my @rows = (
        [ 'print $fh -1;',                'Number=-1',   'print $fh -1 prints the number -1 to $fh' ],
        [ '{ 1 } -e $f;',                 'Operator=-e', 'a filetest after a bare block' ],
        [ 'END { 1 } -e $f;',             'Operator=-e', 'a filetest after an END block' ],
        [ '@s = sort { $a <=> $b } -1, 2;', 'Number=-1', 'sort BLOCK -1, 2 sorts the number -1' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}
# The controls: a spaced - after the handle, a - after an anonymous sub and a
# - after a subscript stay subtractions.
{
    my @rows = (
        [ 'print $fh - e $f;',       'Word=e',     'print $fh - e $f subtracts a call of e (control)' ],
        [ 'my $s = sub { 1 } - 1;',  'Operator=-', 'an anonymous sub minus 1 subtracts (control)' ],
        [ '$x = $h{a} -1;',          'Operator=-', 'a subscript minus 1 subtracts (control)' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}

# §56 -- the same rule for a /: after the } of a block that opens a
# statement or follows a word, a / starts a match.  perl:
# $_ = "x"; BEGIN { 1 } /x/ and print "m\n" prints m, and
# grep { 1 } /(x)/ is the list of the match's groups.
{
    my @rows = (
        [ 'BEGIN { 1 } /x/ and print;', 'Regexp::Match=/x/', 'a match after a BEGIN block' ],
        [ '{ 1 } /x/ and print;',       'Regexp::Match=/x/', 'a match after a bare block' ],
        [ '@a = grep { 1 } /(x)/;',     'Regexp::Match=/(x)/', 'a match after a grep block' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}
# The controls: after a subscript, a dereference block and an anonymous sub
# a / divides.
{
    my @rows = (
        [ '$x = $h{a} /2;',          'Operator=/', 'a subscript divided by 2 (control)' ],
        [ '$x = @{$r} /2;',          'Operator=/', 'a dereference divided by 2 (control)' ],
        [ 'my $s = sub { 1 } / 2;',  'Operator=/', 'an anonymous sub divided by 2 (control)' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}

# §26, more positions of the same bug: after return and local, and in a
# list (the five rows above are after = and at the start).
{
    my @rows = (
        [ 'return *!;',                'Symbol=*!',  '*! after return is one glob' ],
        [ 'local *12 = sub { 1 };',    'Symbol=*12', '*12 after local is one glob' ],
        [ '@a = (*-, *+);',           'Symbol=*+',  '*- and *+ in a list are globs' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}
# The controls: after a term a * multiplies, *$g is a glob dereference, and
# after an unknown word the existing guess stays.
{
    my @rows = (
        [ '$x = $y *-1;',  'Operator=*', 'a scalar times -1 multiplies (control)' ],
        [ '$x = 2*3;',     'Operator=*', '2*3 multiplies (control)' ],
        [ '$z = *$g;',     'Cast=*',     '*$g is a glob dereference (control)' ],
        [ 'foo *-1;',      'Operator=*', 'after an unknown word * stays an operator (control)' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}

# §26, the colon: $: names a scalar, so *: is a glob, while *::foo stays the
# glob main::foo.
{
    my @t = map { short_class($_) } toks('*X = *:;');
    ok( grep( $_ eq 'Symbol=*:', @t ), '*: is one glob' ) or diag "got: @t";
}
{
    my @t = map { short_class($_) } toks('*X = *::foo;');
    ok( grep( $_ eq 'Symbol=*::foo', @t ), '*::foo stays one glob (control)' ) or diag "got: @t";
}

# §32, the siblings: $, and $= take the same wrong branch as $) once the
# signatures feature is on (perl: $, is the output field separator, $= the
# page length).  A nameless parameter is a $ followed by ) , or = INSIDE a
# signature, and only there.
{
    for my $r ( [ "use v5.36;\nmy \$s = \$,;", 'Magic=$,' ],
                [ "use v5.36;\nprint \$=;",     'Magic=$=' ] ) {
        my ( $code, $want ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$want under the signatures feature is one Magic" )
            or diag "got: @t";
    }
}
# The controls: nameless parameters in a named sub's, an anonymous sub's and
# an attributed sub's signature stay a $ Symbol.
for my $code ( "use v5.36;\nsub f (\$, \$y) { 1 }",
               "use v5.36;\nmy \$c = sub (\$) { 1 };",
               "use v5.36;\nsub g :prototype(\$) (\$x, \$=) { 1 }" ) {
    my @t = map { short_class($_) } toks($code);
    ok( grep( $_ eq 'Symbol=$', @t ), "a nameless parameter stays a \$ Symbol (control)" )
        or diag "got: @t";
}

# §7 and §8, more shapes.  perl reads a word before a colon as a LABEL only
# where it expects a statement (toke.c's XSTATE), and the colon after a
# declared variable or list introduces the declaration's attributes.
{
    my @rows = (
        [ 'my @a = (sub :lvalue { 1 });',  'Attribute=lvalue', 'an anonymous sub in a list takes an attribute, not a label' ],
        [ 'my @s = (sub : lvalue { 1 });', 'Attribute=lvalue', 'an anonymous sub in a list takes a spaced attribute' ],
        [ 'our ($p, $q) : unique;',       'Attribute=unique', 'a declared list takes an attribute' ],
        [ 'state $n :shared = 0;',        'Attribute=shared', 'a state variable takes an attribute' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}
# The controls: labels at the start of a statement, after a block and after
# another label, and the colon of a ternary.
{
    my @rows = (
        [ 'LINE: for (1) { 1 }',       'Label=LINE:', 'a label at the start of the document (control)' ],
        [ '{ 1 } NEXT: 1;',            'Label=NEXT:', 'a label after a block (control)' ],
        [ 'A: B: 1;',                  'Label=B:',    'a label after a label (control)' ],
        [ '$x = $c ? $a : $b;',        'Operator=:',  'the colon of a ternary (control)' ],
        [ 'my $y = $c ? foo : bar;',   'Word=foo',    'a word in a ternary is no label (control)' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}

# §8, a TYPED declaration.  perl's `my CLASS $var : attr` (and `my CLASS
# ($a, $b) : attr`) has the class name between the declarator and the
# variable; the colon still introduces the declaration's attributes.
{
    my @rows = (
        [ 'my A $x : plugh;',                 'Attribute=plugh',  'a typed declaration takes an attribute' ],
        [ 'my Foo::Bar @s :shared = ();',     'Attribute=shared', 'a typed declaration with a qualified class takes an attribute' ],
        [ 'our Dog ($p, $q) : unique;',       'Attribute=unique', 'a typed declared list takes an attribute' ],
    );
    for my $r (@rows) {
        my ( $code, $want, $desc ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: $desc" ) or diag "got: @t";
    }
}
# The control: a word before a variable that is not after a declarator keeps
# the colon an operator (print $x in a ternary).
{
    my @t = map { short_class($_) } toks('my $y = $c ? print $x : 1;');
    ok( grep( $_ eq 'Operator=:', @t ), 'a ternary after print $x keeps its colon (control)' )
        or diag "got: @t";
}
# Top-level statements of a snippet, as "Class: content" strings.
sub stmts {
    my $doc = PPI::Document->new(\$_[0]) or return ('NO DOCUMENT');
    return map { short_class(ref $_) . ': ' . squash($_->content) }
           grep { $_->isa('PPI::Statement') } $doc->schildren;
}

# §18, the rest of the shape: perl's try (5.34) takes catch, and from 5.36
# finally, as ONE self-terminating statement -- `try BLOCK catch (VAR) BLOCK
# finally BLOCK` -- and Syntax::Keyword::Try also allows `try BLOCK finally
# BLOCK`.  The finally block belongs to the Statement::Compound, and the
# statement after it is a statement of its own.
{
    is_deeply( [ stmts("use feature 'try';\ntry { a() } catch (\$e) { b() } finally { c() }\nd();\n") ],
        [ "Statement::Include: use feature 'try';",
          'Statement::Compound: try { a() } catch ($e) { b() } finally { c() }',
          'Statement: d();' ],
        'try/catch/finally is one Statement::Compound, the next statement its own' );
    is_deeply( [ stmts("use Syntax::Keyword::Try;\ntry { a() } finally { c() }\nd();\n") ],
        [ 'Statement::Include: use Syntax::Keyword::Try;',
          'Statement::Compound: try { a() } finally { c() }',
          'Statement: d();' ],
        'try/finally (Syntax::Keyword::Try) is one Statement::Compound' );
}
is_deeply( [ stmts("use feature 'try';\ntry { a() } catch (\$e) { b() }\nd();\n") ],
    [ "Statement::Include: use feature 'try';",
      'Statement::Compound: try { a() } catch ($e) { b() }',
      'Statement: d();' ],
    'try/catch without finally ends at its block (control)' );

# §37, the rest of the family: every list operator that takes a block
# filehandle or program (print, printf, say, exec, system; with or without
# CORE::) reads a { right after its ( the way it reads it without the
# parens -- perl -e 'use feature "say"; my $fh = \*STDOUT;
# say({$fh} "a"); CORE::say({$fh} "b")' prints a and b.  The block is the
# first element of ONE statement inside the list.
{
    my @rows = (
        [ 'say({$fh} "a");',                'say' ],
        [ 'CORE::say({$fh} "a");',          'CORE::say' ],
        [ 'print( {$fh} map { $_ } @d );',  'print with map in the list' ],
        [ 'system({$prog} "a", "b");',      'system' ],
        [ 'exec({$prog} "a", "b");',        'exec' ],
    );
    for my $r (@rows) {
        my ( $code, $what ) = @$r;
        my $doc = PPI::Document->new(\$code);
        my ($list) = @{ $doc->find('PPI::Structure::List') || [] };
        my @st = $list ? $list->schildren : ();
        my $first = @st ? $st[0]->schild(0) : undef;
        {
            ok( @st == 1 && ref($st[0]) eq 'PPI::Statement'
                  && $first && ref($first) eq 'PPI::Structure::Block',
                "$what: {\$fh} is a Block opening the one plain statement in $code" )
              or diag 'got: ' . join( ' | ', map { ref($_) . ': ' . squash($_->content) } @st );
        }
    }
}
{
    my $doc = PPI::Document->new(\'print({a => 1});');
    my ($br) = grep { $_->start && $_->start->content eq '{' }
               @{ $doc->find('PPI::Structure') || [] };
    is( ref($br), 'PPI::Structure::Constructor',
        'print({a => 1}) stays an anonymous hash (control)' );
}

# §6 §10 §29, the whole loop-variable slot of foreach (perly.y's FOR rules):
# `for [my|our|state] $x`, a dereference (`for $$f`, `for ${$r}`,
# `for ${*$f}`), a refaliasing variable (`for \my %h`, `for my \%h`,
# `for \$x`) and the n-at-a-time list of 5.36 (`for my ($q, $r)`) all read
# `( LIST ) BLOCK` next.  Each is ONE Statement::Compound of type foreach,
# and the statement after it is its own.
{
    my @shapes = (
        [ 'for $$f (5, 11) { 1 } f();',       '§29' ],
        [ 'for ${$r} (5, 11) { 1 } f();',     '§29' ],
        [ 'for ${*$f} (5, 11) { 1 } f();',    '§6' ],
        [ 'for $$$r (5, 11) { 1 } f();',      '§1' ],
        [ 'for my ($q, $r) (@l) { 1 } f();',  '§10' ],
        [ 'for \my %h (@l) { 1 } f();',       '§10' ],
        [ 'for my \%h (@l) { 1 } f();',       '§10' ],
        [ 'for \my $x (@l) { 1 } f();',       '§10' ],
        [ 'for \$x (@l) { 1 } f();',          '§10' ],
        [ 'L: for \our @a (@l) { 1 } f();',   '§10' ],
    );
    my %why = ();   # every shape passes since §1 ($$$r) was fixed
    for my $r (@shapes) {
        my ( $code, $sect ) = @$r;
        ( my $loop = $code ) =~ s/ f\(\);$//;
        my $doc = PPI::Document->new(\$code);
        my ($cmp) = $doc ? grep { $_->isa('PPI::Statement::Compound') } $doc->schildren : ();
        TODO: {
            local $TODO = $why{$sect};
            is_deeply( [ stmts($code) ], [ "Statement::Compound: $loop", 'Statement: f();' ],
                "$code: the loop is one Statement::Compound, f(); its own statement" );
            is( $cmp && $cmp->type, 'foreach', "$code: the compound is a foreach" );
        }
    }
    for my $code ( 'for my $x (@l) { 1 } f();', 'for $x qw(a b) { 1 } f();',
                   'for (my $i = 0; $i < 3; $i++) { 1 } f();', 'for (@l) { 1 } f();' ) {
        ( my $loop = $code ) =~ s/ f\(\);$//;
        is_deeply( [ stmts($code) ], [ "Statement::Compound: $loop", 'Statement: f();' ],
            "$code: one compound, then f(); (control)" );
    }
}

# §17 §36, the rest of the family: a [ or { right after a term subscripts
# it -- perl reads a dereference block (${$r}[0], ${a}[1], @{$r}[0, 1],
# %{$r}{'a'}) and a key/value slice (%h{'a'}, %a[0, 1]) the way it reads
# $a[1] and @h{'a'}.  The brackets are a Structure::Subscript.
{
    my @rows = (
        [ 'my $v = ${a}[1];',          '[', '§36' ],
        [ 'my $v = ${$r}[0];',         '[', '§17' ],
        [ 'my @v = @{$r}[0, 1];',      '[', '§17' ],
        [ 'my %v = %{$r}[0, 1];',      '[', '§17' ],
        [ 'my %v = %{$r}{"a", "b"};',  '{', '§17' ],
        [ 'my %v = %h{"a", "b"};',     '{', '§17' ],
        [ 'my %v = %a[0, 1];',         '[', '§17' ],
    );
    for my $r (@rows) {
        my ( $code, $open, $sect ) = @$r;
        my $doc = PPI::Document->new(\$code);
        my @br  = grep { $_->start && $_->start->content eq $open }
                  @{ $doc->find('PPI::Structure') || [] };
        is( ref( $br[-1] ), 'PPI::Structure::Subscript',
            "$code: the last $open...  is a Structure::Subscript ($sect)" );
    }
    for my $r ( [ 'print {$fh} [1];', '[', 'PPI::Structure::Constructor',
                  'after a block filehandle a [ is an anonymous array (control)' ],
                [ 'my $v = ${$r}{a};', '{', 'PPI::Structure::Subscript',
                  '${$r}{a} is a Subscript (control)' ],
                [ 'my @v = @h{"a", "b"};', '{', 'PPI::Structure::Subscript',
                  '@h{...} is a Subscript (control)' ],
                [ 'my %v = %$r{"a", "b"};', '{', 'PPI::Structure::Subscript',
                  '%$r{...} is a Subscript (control)' ] ) {
        my ( $code, $open, $want, $desc ) = @$r;
        my $doc = PPI::Document->new(\$code);
        my @br  = grep { $_->start && $_->start->content eq $open }
                  @{ $doc->find('PPI::Structure') || [] };
        is( ref( $br[-1] ), $want, "$code: $desc" );
    }
}

# §5 -- a { where a statement starts is a block unless what follows says
# anonymous hash.  perl's rule (toke.c, the curly look-ahead): a } right
# away, or a first term that is a string or a word followed by =>, or a
# string, a number or a word not starting with a lower-case letter
# followed by a comma -- perl -e 'sub f { { "a", "foo" } } print ref f()'
# prints HASH, and so do { 1, 2 } and { Foo, 1 }; { foo, 1 }, { $x, 1 }
# and { 1.5, 2 } are blocks.
{
    my @rows = (
        [ q{{ 'a', 'foo' };},  'PPI::Structure::Constructor', 1 ],
        [ q{{ "a", 1 };},      'PPI::Structure::Constructor', 1 ],
        [ q{{ 1, 2 };},        'PPI::Structure::Constructor', 1 ],
        [ q{{ Foo, 1 };},      'PPI::Structure::Constructor', 1 ],
        [ q{{ q(a), 1 };},     'PPI::Structure::Constructor', 1 ],
        [ q{{ foo, 1 };},      'PPI::Structure::Block', 0 ],
        [ q{{ $x, 1 };},       'PPI::Structure::Block', 0 ],
        [ q{{ 1.5, 2 };},      'PPI::Structure::Block', 0 ],
        [ q{{ 'a' };},         'PPI::Structure::Block', 0 ],
        [ q{{ 'a' => 1 };},    'PPI::Structure::Constructor', 0 ],
    );
    for my $r (@rows) {
        my ( $code, $want, $row ) = @$r;
        my $doc = PPI::Document->new(\$code);
        my ($first) = $doc->schildren;
        my $br = $first && $first->schild(0);
        is( ref($br), $want,
            "$code: the statement-initial { is a " . short_class($want)
              . ( $row ? " (PCL \x{a7}5)" : " (control)" ) );
    }
}

# §13, the whole of it: the tokens of a document do not depend on the
# caller's $/.  In slurp mode ($/ undefined, as code that has just read
# the source is likely to be) a trailing comment absorbs its newline and
# the newline after __DATA__ / __END__ becomes a Comment.
{
    my $src = "# c\nx; # d\n__DATA__\nfoo\n";
    my $tokens = sub {
        join '|', map { short_class(ref $_) . '=' . $_->content }
                  PPI::Document->new(\$src)->tokens;
    };
    my $plain   = $tokens->();
    my $slurped = do { local $/; $tokens->() };
    my $crlf    = do { local $/ = "\r\n"; $tokens->() };
    {
        is( $slurped, $plain, 'the tokens are the same when $/ is undef' );
        is( $crlf,    $plain, 'the tokens are the same when $/ is "\r\n"' );
    }
}

# §39 -- whitespace may stand between a sigil and its name (toke.c
# scan_ident skips it): `my $ bits = 5; print $bits` prints 5.
TODO: {
    local $TODO = 'PCL §39: a spaced sigil $ name lexes as Cast + Word';
    for my $r ( [ 'my $ bits = 5;', 'Symbol=$ bits' ], [ '$ x = 1;', 'Symbol=$ x' ] ) {
        my ( $code, $want ) = @$r;
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq $want, @t ), "$code: the sigil and its name are one Symbol" ) or diag "got: @t";
    }
}

# §40 -- a format body is picture text up to the line holding a lone `.`
# (toke.c scan_formline), never code:
# `format STDOUT =\nhello world\n.\nwrite;` prints hello world.
TODO: {
    local $TODO = 'PCL §40: a format body is tokenized as code';
    my @t = map { short_class($_) } toks("format STDOUT =\nhello world\n.\nwrite;\n");
    ok( !grep( $_ eq 'Word=hello', @t ), 'the picture line of a format is not code' ) or diag "got: @t";
}

# §41 -- an empty package segment is part of the name (toke.c scan_word6):
# `sub foo::::bar { 7 } print foo::::bar()` prints 7.
{
    for my $code ( 'sub foo::::bar { 7 }', 'foo::::bar();' ) {
        my @t = map { short_class($_) } toks($code);
        ok( grep( $_ eq 'Word=foo::::bar', @t ), "$code: foo::::bar is one Word" ) or diag "got: @t";
    }
}

# §42 -- a here-doc introduced inside a quote-like body takes its body
# from the lines after the statement, as anywhere else:
# `$_ = "a"; s/a/<<END/e;\nfoo\nEND\nprint;` prints foo.
TODO: {
    local $TODO = 'PCL §42: a here-doc inside a quote-like body does not consume its body';
    my @t = map { short_class($_) } toks("\$_ = 'a'; s/a/<<END/e;\nfoo\nEND\nprint;\n");
    ok( !grep( $_ eq 'Word=END', @t ), 's/a/<<END/e: the here-doc body is not code' ) or diag "got: @t";
}

# §43 -- a lexical sub may be named like a keyword, and its name is then
# a sub call: `my sub s { "S@_" } print s(1)` prints S1.
TODO: {
    local $TODO = 'PCL §43: a lexical sub named like a keyword keeps the keyword lexing';
    my @t = map { short_class($_) } toks('my sub s { "S@_" } print s(1), "\n";');
    ok( !grep( /^Regexp::Substitute=/, @t ), 'my sub s ... s(1): a call, not a substitution' ) or diag "got: @t";
}

# §44 -- CORE::__END__ and CORE::__DATA__ end the code like __END__ and
# __DATA__: `print "x\n";\nCORE::__END__\nnot code` prints x.
{
    for my $m (qw(__END__ __DATA__)) {
        my @t = map { short_class($_) } toks("print 1;\nCORE::$m\nnot code\n");
        ok( grep( $_ eq "Separator=CORE::$m", @t ), "CORE::$m is a Separator" ) or diag "got: @t";
    }
}

# §45 -- `&` where a term is expected is the code sigil even before a
# space and a block (toke.c yyl_ampersand): `& {sub { print "ok\n" }};`
# prints ok.
TODO: {
    local $TODO = 'PCL §45: & {BLOCK} with a space is a bitwise and';
    my @t = map { short_class($_) } toks('& {sub { print "ok\n" }};');
    is( $t[0], 'Cast=&', '& {BLOCK} at a statement start: & is a Cast' ) or diag "got: @t";
}

# §46 -- the old package separator ' may open a sub name:
# `sub 'Hello'_he_said { "hi" } print Hello::_he_said()` prints hi.
{
    my @t = map { short_class($_) } toks(q{sub 'Hello'_he_said { "hi" }});
    ok( grep( $_ eq q{Word='Hello'_he_said}, @t ), q{sub 'Hello'_he_said: the name is one Word} ) or diag "got: @t";
}

# §47 -- `WORD :` inside a ternary's middle operand is a word and the
# colon, never a label (a label only where a statement starts):
# `my $c = 0 ? ref shift : shift` is the second shift.
{
    my @t = map { short_class($_) } toks('sub f { my $c = 0 ? ref shift : shift; $c }');
    ok( !grep( /^Label=/, @t ), '0 ? ref shift : shift: no label in a ternary' ) or diag "got: @t";
}

# §13, the root: a PPI::Tokenizer used on its own (no PPI::Document, no
# Lexer) reads the same tokens whatever the caller's $/ is.  The comment and
# __END__ arms took their line end with chomp, which removes $/.
{
    my $src = "# c\nx; # d\n__END__ e\nfoo\n";
    my $tokens = sub {
        my $tz = PPI::Tokenizer->new( \$src );
        join '|', map { short_class(ref $_) . '=' . $_->content } @{ $tz->all_tokens };
    };
    my $plain   = $tokens->();
    my $slurped = do { local $/; $tokens->() };
    is( $slurped, $plain, 'a standalone tokenizer: the tokens are the same when $/ is undef' );
}
