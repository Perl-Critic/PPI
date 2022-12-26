#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 10 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use B 'perlstring';

use PPI ();
use PPI::Dumper;

#use DB::Skip subs => [
#	qw( PPI::Document::new  PPI::Lexer::lex_source  PPI::Lexer::new
#	  PPI::Lexer::_clear  PPI::Lexer::(eval)  PPI::Lexer::X_TOKENIZER
#	  PPI::Tokenizer::new  PPI::Lexer::lex_tokenizer  PPI::Node::new  ),
#	qr/^PPI::Tokenizer::__ANON__.*237.*$/
#];

sub test_document;

FEATURE_TRACKING: {
	test_document
	  <<'END_PERL',
		sub meep($) {}
		use 5.035;
		sub marp($left, $right) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub meep($) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'meep',
		'PPI::Token::Prototype',      '($)',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
		'PPI::Statement::Include',    'use 5.035;',
		'PPI::Token::Word',           'use',
		'PPI::Token::Number::Float',  '5.035',
		'PPI::Token::Structure',      ';',
		'PPI::Statement::Sub',        'sub marp($left, $right) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'marp',
		'PPI::Structure::Signature',  '($left, $right)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$left, $right',
		'PPI::Token::Symbol',         '$left',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$right',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}'
	  ],
	  "enabling of features";
}

DOCUMENT_FEATURES: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub meep($) {}
		sub marp($left, $right) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub meep($) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'meep',
		'PPI::Structure::Signature',  '($)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$',
		'PPI::Token::Symbol',         '$',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
		'PPI::Statement::Sub',        'sub marp($left, $right) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'marp',
		'PPI::Structure::Signature',  '($left, $right)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$left, $right',
		'PPI::Token::Symbol',         '$left',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$right',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "document-level default features";
}

DISABLE_FEATURE: {
	test_document
	  [ feature_mods => { signatures => 1 } ],
	  <<'END_PERL',
		sub meep($) {}
		no feature 'signatures';
		sub marp($left, $right) {}
END_PERL
	  [
		'PPI::Statement::Sub',        'sub meep($) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'meep',
		'PPI::Structure::Signature',  '($)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$',
		'PPI::Token::Symbol',         '$',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
		'PPI::Statement::Include',    'no feature \'signatures\';',
		'PPI::Token::Word',           'no',
		'PPI::Token::Word',           'feature',
		'PPI::Token::Quote::Single',  '\'signatures\'',
		'PPI::Token::Structure',      ';',
		'PPI::Statement::Sub',        'sub marp($left, $right) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'marp',
		'PPI::Token::Prototype',      '($left, $right)',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "disabling of features";
}

PROTOTYPE_ATTR: {
	test_document
	  <<'END_PERL',
		sub meep :prototype($) {}
END_PERL
	  [
		'PPI::Statement::Sub'   => 'sub meep :prototype($) {}',
		'PPI::Token::Word'      => 'sub',
		'PPI::Token::Word'      => 'meep',
		'PPI::Token::Operator'  => ':',
		'PPI::Token::Attribute' => 'prototype($)',
		'PPI::Structure::Block' => '{}',
		'PPI::Token::Structure' => '{',
		'PPI::Token::Structure' => '}',
	  ],
	  "prototype attribute";
}

SYNTAX_KEYWORD_TRY: {
	test_document
	  <<'END_PERL',
		use Syntax::Keyword::Try;
		try{}catch{}
END_PERL
	  [
		'PPI::Statement::Include'  => 'use Syntax::Keyword::Try;',
		'PPI::Token::Word'         => 'use',
		'PPI::Token::Word'         => 'Syntax::Keyword::Try',
		'PPI::Token::Structure'    => ';',
		'PPI::Statement::Compound' => 'try{}catch{}',
		'PPI::Token::Word'         => 'try',
		'PPI::Structure::Block'    => '{}',
		'PPI::Token::Structure'    => '{',
		'PPI::Token::Structure'    => '}',
		'PPI::Token::Word'         => 'catch',
		'PPI::Structure::Block'    => '{}',
		'PPI::Token::Structure'    => '{',
		'PPI::Token::Structure'    => '}',
	  ],
	  "Syntax::Keyword::Try";
}

CORE_TRY: {
	test_document
	  <<'END_PERL',
		use feature "try";
		try{}catch($e){}
END_PERL
	  [
		'PPI::Statement::Include',    'use feature "try";',
		'PPI::Token::Word',           'use',
		'PPI::Token::Word',           'feature',
		'PPI::Token::Quote::Double',  '"try"',
		'PPI::Token::Structure',      ';',
		'PPI::Statement::Compound',   'try{}catch($e){}',
		'PPI::Token::Word',           'try',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
		'PPI::Token::Word',           'catch',
		'PPI::Structure::List',       '($e)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$e',
		'PPI::Token::Symbol',         '$e',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "core try";
}

HOMEBREW_ARGS: {
	test_document
	  [ custom_feature_includes => { strEct => { signatures => 1 } } ],
	  <<'END_PERL',
		use strEct;
		sub meep($) {}
		sub marp($left, $right) {}
END_PERL
	  [
		'PPI::Statement::Include',    'use strEct;',
		'PPI::Token::Word',           'use',
		'PPI::Token::Word',           'strEct',
		'PPI::Token::Structure',      ';',
		'PPI::Statement::Sub',        'sub meep($) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'meep',
		'PPI::Structure::Signature',  '($)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$',
		'PPI::Token::Symbol',         '$',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
		'PPI::Statement::Sub',        'sub marp($left, $right) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'marp',
		'PPI::Structure::Signature',  '($left, $right)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$left, $right',
		'PPI::Token::Symbol',         '$left',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$right',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "simple custom boilerplate modules";
}

HOMEBREW_CB: {
	test_document    #
	  [
		custom_feature_include_cb => sub {
			my ($inc) = @_;
			my ($arg) = $inc->arguments;
			return ( $inc->module eq "strEct" and $arg->string eq "sigg" )
			  ? { signatures => 1 }
			  : ();
		}
	  ],
	  <<'END_PERL',
		use strEct "sigg";
		sub meep($) {}
		sub marp($left, $right) {}
END_PERL
	  [
		'PPI::Statement::Include',    'use strEct "sigg";',
		'PPI::Token::Word',           'use',
		'PPI::Token::Word',           'strEct',
		'PPI::Token::Quote::Double',  '"sigg"',
		'PPI::Token::Structure',      ';',
		'PPI::Statement::Sub',        'sub meep($) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'meep',
		'PPI::Structure::Signature',  '($)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$',
		'PPI::Token::Symbol',         '$',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
		'PPI::Statement::Sub',        'sub marp($left, $right) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'marp',
		'PPI::Structure::Signature',  '($left, $right)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$left, $right',
		'PPI::Token::Symbol',         '$left',
		'PPI::Token::Operator',       ',',
		'PPI::Token::Symbol',         '$right',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "callback for complex custom boilerplate modules";
}

CPAN_MOJOLICIOUS_LITE: {
	test_document
	  <<'END_PERL',
		use Mojolicious::Lite -signatures;
		sub meep($) {}
END_PERL
	  [
		'PPI::Statement::Include',    'use Mojolicious::Lite -signatures;',
		'PPI::Token::Word',           'use',
		'PPI::Token::Word',           'Mojolicious::Lite',
		'PPI::Token::Word',           '-signatures',
		'PPI::Token::Structure',      ';',
		'PPI::Statement::Sub',        'sub meep($) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'meep',
		'PPI::Structure::Signature',  '($)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$',
		'PPI::Token::Symbol',         '$',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "simple custom boilerplate modules";
}

CPAN_MODERN_PERL: {
	test_document
	  <<'END_PERL',
		use Modern::Perl 2023;
		sub meep($) {}
END_PERL
	  [
		'PPI::Statement::Include',    'use Modern::Perl 2023;',
		'PPI::Token::Word',           'use',
		'PPI::Token::Word',           'Modern::Perl',
		'PPI::Token::Number',         '2023',
		'PPI::Token::Structure',      ';',
		'PPI::Statement::Sub',        'sub meep($) {}',
		'PPI::Token::Word',           'sub',
		'PPI::Token::Word',           'meep',
		'PPI::Structure::Signature',  '($)',
		'PPI::Token::Structure',      '(',
		'PPI::Statement::Expression', '$',
		'PPI::Token::Symbol',         '$',
		'PPI::Token::Structure',      ')',
		'PPI::Structure::Block',      '{}',
		'PPI::Token::Structure',      '{',
		'PPI::Token::Structure',      '}',
	  ],
	  "simple custom boilerplate modules";
}

### TODO from ppi_token_unknown.t , deduplicate

sub one_line_explain {
	my ($data) = @_;
	my @explain = explain $data;
	s/\n//g for @explain;
	return join "", @explain;
}

sub main_level_line {
	return "" if not $TODO;
	my @outer_final;
	my $level = 0;
	while ( my @outer = caller( $level++ ) ) {
		@outer_final = @outer;
	}
	return "l $outer_final[2] - ";
}

sub test_document {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $args = ref $_[0] eq "ARRAY" ? shift : [];
	my ( $code, $expected, $msg ) = @_;
	$msg = perlstring $code if !defined $msg;

	my $d      = PPI::Document->new( \$code, @{$args} ) or die explain $@;
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref($_), $_->content } @$tokens ];

	my $ok = is_deeply( $tokens, $expected, main_level_line . $msg );
	if ( !$ok ) {
		diag ">>> $code -- $msg\n";
		diag( PPI::Dumper->new($d)->string );
		diag one_line_explain $tokens;
		diag one_line_explain $expected;
	}

	return;
}
