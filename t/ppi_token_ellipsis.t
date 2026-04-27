#!/usr/bin/perl

# Unit testing for PPI::Token::Ellipsis

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 38 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';

our $TODO;

ELLIPSIS_TOKEN_TYPE: {
	my $doc = safe_new \'...;';

	local $TODO = "ellipsis token type not yet implemented";

	my $tokens = $doc->find( sub { $_[1]->isa('PPI::Token') and $_[1]->content eq '...' } );
	is( ref $tokens, 'ARRAY', "'...' token found" );
	is( @$tokens, 1, "'...' found exactly once" );
	isa_ok( $tokens->[0], 'PPI::Token::Ellipsis', "'...' token" );
	ok( !$tokens->[0]->isa('PPI::Token::Operator'), "'...' is not a Token::Operator" );
}

ELLIPSIS_IN_SUB: {
	my $doc = safe_new \'sub foo { ... }';

	local $TODO = "ellipsis token type not yet implemented";

	my $tokens = $doc->find( sub { $_[1]->isa('PPI::Token') and $_[1]->content eq '...' } );
	is( ref $tokens, 'ARRAY', "ellipsis found in sub body" );
	is( @$tokens, 1, "ellipsis found exactly once in sub body" );
	isa_ok( $tokens->[0], 'PPI::Token::Ellipsis', "ellipsis in sub body" );
}

ELLIPSIS_SIGNIFICANT: {
	my $doc = safe_new \'...;';
	my $tokens = $doc->find( sub { $_[1]->isa('PPI::Token') and $_[1]->content eq '...' } );
	is( ref $tokens, 'ARRAY', "ellipsis found for significance test" );
	ok( $tokens->[0]->significant, "ellipsis is significant" );
}

ELLIPSIS_STATEMENT_BREAK: {
	my $doc = safe_new \'...;';

	local $TODO = "ellipsis token type not yet implemented";

	my $stmts = $doc->find('Statement::Break');
	is( ref $stmts, 'ARRAY', "'...' creates a Statement::Break" );
	is( ref $stmts eq 'ARRAY' ? scalar @$stmts : 0, 1, "exactly one Statement::Break" );
}

ELLIPSIS_IN_SUB_STATEMENT: {
	my $doc = safe_new \'sub foo { ... }';

	local $TODO = "ellipsis token type not yet implemented";

	my $stmts = $doc->find('Statement::Break');
	is( ref $stmts, 'ARRAY', "ellipsis in sub creates Statement::Break" );
	is( ref $stmts eq 'ARRAY' ? scalar @$stmts : 0, 1, "exactly one Statement::Break in sub body" );
}

RANGE_OPERATOR_UNCHANGED: {
	my $doc = safe_new \'my @a = 1..10;';
	my $ops = $doc->find('Token::Operator');
	is( ref $ops, 'ARRAY', "'..' still found as operator" );
	my @dots = grep { $_->content eq '..' } @$ops;
	is( scalar @dots, 1, "range operator '..' found exactly once" );
}

CONCAT_OPERATOR_UNCHANGED: {
	my $doc = safe_new \'my $x = "a" . "b";';
	my $ops = $doc->find('Token::Operator');
	is( ref $ops, 'ARRAY', "'.' still found as operator" );
	my @dots = grep { $_->content eq '.' } @$ops;
	is( scalar @dots, 1, "concat operator '.' found exactly once" );
}

ROUND_TRIP: {
	my $code = "sub foo { ... }\n";
	my $doc = safe_new \$code;
	is( $doc->serialize, $code, "round-trip preserves ellipsis code" );
}

ELLIPSIS_WITH_SEMICOLON: {
	my $doc = safe_new \'...; print "hello\n";';

	local $TODO = "ellipsis token type not yet implemented";

	my $tokens = $doc->find( sub { $_[1]->isa('PPI::Token') and $_[1]->content eq '...' } );
	is( ref $tokens, 'ARRAY', "ellipsis found before semicolon" );
	isa_ok( $tokens->[0], 'PPI::Token::Ellipsis', "ellipsis before semicolon" );
}
