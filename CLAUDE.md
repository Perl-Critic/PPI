# CLAUDE.md

## What is PPI

PPI is a Perl document parser — it parses Perl source code into a structure representing a **document** (not an abstract syntax tree), preserving whitespace, comments, and POD. It powers Perl::Critic and other static analysis tools. Round-trip safe: parse + serialize without changes = identical source.

## Build & Test

Uses **Dist::Zilla** (`dist.ini`) — there is no `Makefile.PL` or `Build.PL` in the repo.

```bash
# Run tests (uses .proverc: parallel, recurse, -l, state caching)
prove

# Run a single test file
prove -l --norc t/08_regression.t

# Build distribution
dzil build

# Install author deps + project deps
dzil authordeps --missing | cpanm
dzil listdeps --missing --author | cpanm
```

CI tests across Perl 5.8 through 5.38 on Ubuntu, macOS, and Windows.

## Architecture

Three-stage pipeline: **Tokenizer** → **Lexer** → **PDOM tree**

### PDOM class hierarchy

All classes inherit from `PPI::Element`:

```
PPI::Element                    # Abstract base for all PDOM nodes
├── PPI::Token                  # Leaf nodes (actual source text)
│   ├── ::Whitespace, ::Comment, ::Pod
│   ├── ::Word, ::Symbol, ::Magic, ::Operator, ::Cast
│   ├── ::Number (+ ::Binary, ::Octal, ::Hex, ::Float, ::Exp, ::Version)
│   ├── ::Quote (::Single, ::Double, ::Literal, ::Interpolate)
│   ├── ::QuoteLike (::Backtick, ::Command, ::Regexp, ::Words, ::Readline)
│   ├── ::Regexp (::Match, ::Substitute, ::Transliterate)
│   ├── ::HereDoc, ::Label, ::Separator, ::Data, ::End
│   ├── ::Prototype, ::Attribute, ::ArrayIndex, ::DashedWord, ::BOM
│   └── ::Unknown
├── PPI::Node                   # Container nodes (have children)
│   ├── PPI::Document           # Root of the tree
│   │   ├── ::File, ::Fragment, ::Normalized
│   ├── PPI::Statement          # Logical Perl statements
│   │   ├── ::Package, ::Include, ::Sub, ::Scheduled
│   │   ├── ::Compound, ::Break, ::Given, ::When
│   │   ├── ::Variable, ::Expression, ::Null
│   │   ├── ::Data, ::End, ::UnmatchedBrace, ::Unknown
│   └── PPI::Structure          # Matched braces: (), [], {}
│       ├── ::Block, ::Subscript, ::Constructor
│       ├── ::Condition, ::List, ::For
│       ├── ::Given, ::When, ::Signature, ::Unknown
```

### Key modules (`lib/PPI/`)

| Module | Role |
|--------|------|
| `Tokenizer.pm` | Character-by-character lexical scanning, heuristic-based |
| `Lexer.pm` | Builds PDOM tree from token stream |
| `Document.pm` | Root node, file I/O, error tracking |
| `Element.pm` | Base class — content, location, navigation, overloaded ops |
| `Node.pm` | Container — children, find, prune |
| `Statement.pm` | Statement base — subclasses for each Perl statement type |
| `Structure.pm` | Brace-delimited structure base |
| `Token.pm` | Token base — subclasses for each token type |
| `Singletons.pm` | Global parent-child tracking (`%_PARENT`) and position cache |
| `Find.pm` | Element search (by class or callback) |
| `Normal.pm` | Normalization (strip insignificant elements for comparison) |
| `Cache.pm` | MD5 + Storable document caching |
| `Transform.pm` | Base class for document transformations |
| `Dumper.pm` | Debug tree visualization |
| `Util.pm` | Utility functions |

### Key design rules

- A Statement never contains another Statement
- A Structure never contains another Structure
- A Document never contains another Document
- Everything is preserved (whitespace, comments, POD) for round-trip safety
- "Significant" elements are actual code; "insignificant" are whitespace/comments/POD

## Testing

Tests live in `t/`, test data in `t/data/`, helpers in `t/lib/`.

### Test boilerplate

```perl
use lib 't/lib';
use PPI::Test::pragmas;     # strict + warnings + disables PPI::XS
use Helper 'safe_new';       # safe_new(\$code) with error checking

my $doc = safe_new \"my \$x = 1;";
```

- `PPI::Test::pragmas` enables strict/warnings and sets `$PPI::XS_DISABLE = 1`
- `safe_new` creates a `PPI::Document` and fails the test if parsing errors
- `check_with` creates a doc and stores it in `$_` for quick assertions

### `.proverc`

Configured with `--state=hot,slow,save -j 9 --recurse -l t` — runs slow tests first, 9 parallel jobs.

## Conventions

- Perl 5.8 compatibility
- Library modules do NOT enable `warnings` — warnings coverage comes from the test pragma
- Version set globally by `Git::VersionManager` during release (`our $VERSION = '...'`)
- Extend PPI via `PPIx::` namespace; general Perl tools use `Perl::` namespace
- PPI::XS is optional/experimental — always disabled in tests
- avoid unless, except for `die unless #\n my $thing = generate;` constructs
- prefer postfix syntax constructs
- All PRs should be implemented with at least two commits, one containing failing tests, marked with $TODO, the other containing the fixes and removals of relevant $TODO markers.

## Dependencies

Runtime: `Clone`, `Params::Util`, `List::Util` ≥ 1.33, `Scalar::Util`, `Storable` ≥ 2.17, `Digest::MD5`, `Task::Weaken`, `Safe::Isa`

Test: `Test::More` ≥ 0.96, `Test::Warnings` (author testing only)
