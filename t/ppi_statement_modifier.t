#!/usr/bin/perl

# Unit testing for PPI::Statement modifier_type() and modifier()

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 84 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


POSTFIX_IF: {
	my $doc = safe_new \"print 'hello' if \$condition;";
	my $stmts = $doc->find('Statement');
	is( scalar @{$stmts}, 1, 'postfix if: found 1 statement' );
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'if', 'postfix if: modifier_type returns if' );

	my $mod = $stmt->modifier;
	isa_ok( $mod, 'PPI::Token::Word', 'postfix if: modifier returns a Word token' );
	is( $mod->content, 'if', 'postfix if: modifier content is if' );
}


POSTFIX_UNLESS: {
	my $doc = safe_new \"die 'error' unless \$ok;";
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'unless', 'postfix unless: modifier_type returns unless' );
}


POSTFIX_WHILE: {
	my $doc = safe_new \"print while <STDIN>;";
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'while', 'postfix while: modifier_type returns while' );
}


POSTFIX_UNTIL: {
	my $doc = safe_new \q{sleep 1 until $ready;};
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'until', 'postfix until: modifier_type returns until' );
}


POSTFIX_FOR: {
	my $doc = safe_new \"say \$_ for \@items;";
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'for', 'postfix for: modifier_type returns for' );
}


POSTFIX_FOREACH: {
	my $doc = safe_new \"push \@out, \$_ foreach \@in;";
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'foreach', 'postfix foreach: modifier_type returns foreach' );
}


BREAK_WITH_MODIFIER: {
	my $doc = safe_new \"return if \$done;";
	my $stmts = $doc->find('Statement::Break');
	is( scalar @{$stmts}, 1, 'break with modifier: found 1 Break statement' );
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'if', 'break with modifier: modifier_type returns if' );

	my $mod = $stmt->modifier;
	isa_ok( $mod, 'PPI::Token::Word', 'break with modifier: modifier is a Word' );
}


BREAK_UNLESS: {
	my $doc = safe_new \"next unless \$valid;";
	my $stmts = $doc->find('Statement::Break');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'unless', 'next unless: modifier_type returns unless' );
}


VARIABLE_WITH_MODIFIER: {
	my $doc = safe_new \"my \$foo = 1 if \$condition;";
	my $stmts = $doc->find('Statement::Variable');
	is( scalar @{$stmts}, 1, 'variable with modifier: found 1 Variable statement' );
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'if', 'variable with modifier: modifier_type returns if' );
}


NO_MODIFIER_SIMPLE: {
	my $doc = safe_new \"my \$x = 1;";
	my $stmts = $doc->find('Statement::Variable');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'no modifier: variable assignment returns empty' );
	is( $stmt->modifier, '', 'no modifier: modifier returns empty' );
}


NO_MODIFIER_PLAIN: {
	my $doc = safe_new \"print 'hello';";
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'plain statement: no modifier' );
}


COMPOUND_NOT_MODIFIER: {
	my $doc = safe_new \"if (\$x) { print 1; }";
	my $stmts = $doc->find('Statement::Compound');
	is( scalar @{$stmts}, 1, 'compound: found 1 Compound statement' );
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'compound if: modifier_type returns empty' );
	is( $stmt->modifier, '', 'compound if: modifier returns empty' );
}


COMPOUND_WHILE_NOT_MODIFIER: {
	my $doc = safe_new \"while (\$x) { print 1; }";
	my $stmts = $doc->find('Statement::Compound');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'compound while: modifier_type returns empty' );
}


COMPOUND_FOR_NOT_MODIFIER: {
	my $doc = safe_new \"for my \$x (\@items) { print \$x; }";
	my $stmts = $doc->find('Statement::Compound');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'compound for: modifier_type returns empty' );
}


FAT_COMMA_NOT_MODIFIER: {
	my $doc = safe_new \"die if => 1;";
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'fat comma if: not a modifier' );
	is( $stmt->modifier, '', 'fat comma if: modifier returns empty' );
}


HASH_KEY_NOT_MODIFIER: {
	my $doc = safe_new \"\$hash{for} = 1;";
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'hash key for: not a modifier' );
}


DO_WHILE: {
	my $doc = safe_new \"do { cleanup() } while \$running;";
	my $stmts = $doc->find('Statement');
	is( scalar @{$stmts}, 2, 'do-while: found 2 statements (outer + inner)' );
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'while', 'do-while: modifier_type returns while' );
}


COMPLEX_CONDITION: {
	my $doc = safe_new \"chomp(my \$line = <STDIN>) if defined(\$line = <STDIN>);";
	my $stmts = $doc->find('Statement');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'if', 'complex condition: modifier_type returns if' );

	my $mod = $stmt->modifier;
	isa_ok( $mod, 'PPI::Token::Word', 'complex condition: modifier is a Word' );
	is( $mod->content, 'if', 'complex condition: modifier content is if' );
}


INCLUDE_NOT_MODIFIER: {
	my $doc = safe_new \"use strict;";
	my $stmts = $doc->find('Statement::Include');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'include: no modifier' );
}


SCHEDULED_NOT_MODIFIER: {
	my $doc = safe_new \"BEGIN { 1; }";
	my $stmts = $doc->find('Statement::Scheduled');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'scheduled: no modifier' );
}


SUB_NOT_MODIFIER: {
	my $doc = safe_new \"sub foo { 1; }";
	my $stmts = $doc->find('Statement::Sub');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'sub: no modifier' );
}


NULL_NOT_MODIFIER: {
	my $doc = safe_new \";;";
	my $stmts = $doc->find('Statement::Null');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, '', 'null statement: no modifier' );
}


RETURN_EXPR_UNLESS: {
	my $doc = safe_new \"return \$x + 1 unless defined \$y;";
	my $stmts = $doc->find('Statement::Break');
	my $stmt = $stmts->[0];

	is( $stmt->modifier_type, 'unless', 'return expr unless: modifier_type returns unless' );

	my $mod = $stmt->modifier;
	isa_ok( $mod, 'PPI::Token::Word', 'return expr unless: modifier is a Word' );
	is( $mod->content, 'unless', 'return expr unless: modifier content is unless' );
}
