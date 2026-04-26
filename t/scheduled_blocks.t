#!/usr/bin/perl

# Verify behaviour of BEGIN, UNITCHECK, CHECK, INIT and END
# in all contexts documented in perlmod.
# See: https://github.com/Perl-Critic/PPI/issues/275

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 415 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';

my @SCHEDULED = qw( BEGIN CHECK UNITCHECK INIT END );

KEYWORD_WITH_BLOCK: {
	for my $kw (@SCHEDULED) {
		my $doc = safe_new \"$kw { 1 }";
		my ($st) = $doc->schildren;
		isa_ok $st, 'PPI::Statement::Scheduled', "$kw { 1 }";
		is $st->type, $kw, "$kw { 1 }: type()";
		is $st->name, $kw, "$kw { 1 }: name()";
		isa_ok $st->block, 'PPI::Structure::Block', "$kw { 1 }: block()";
		ok $st->reserved, "$kw { 1 }: reserved()";
	}
}

KEYWORD_WITH_SUB: {
	for my $kw (@SCHEDULED) {
		my $doc = safe_new \"sub $kw { 1 }";
		my ($st) = $doc->schildren;
		isa_ok $st, 'PPI::Statement::Scheduled', "sub $kw { 1 }";
		is $st->type, $kw, "sub $kw { 1 }: type()";
		is $st->name, $kw, "sub $kw { 1 }: name()";
		isa_ok $st->block, 'PPI::Structure::Block', "sub $kw { 1 }: block()";
	}
}

SUB_WITH_PROTOTYPE: {
	for my $kw (@SCHEDULED) {
		my $doc = safe_new \"sub $kw () { 1 }";
		my ($st) = $doc->schildren;
		isa_ok $st, 'PPI::Statement::Scheduled', "sub $kw () { 1 }";
		is $st->type, $kw, "sub $kw () { 1 }: type()";
		isa_ok $st->block, 'PPI::Structure::Block', "sub $kw () { 1 }: block()";
	}
}

DECLARATION_WITH_SEMICOLON: {
	for my $kw (@SCHEDULED) {
		my $doc = safe_new \"$kw;";
		my ($st) = $doc->schildren;
		isa_ok $st, 'PPI::Statement::Scheduled', "$kw;";
		is $st->type, $kw, "$kw;: type()";
		ok !$st->block, "$kw;: no block()";
	}
}

NOT_SCHEDULED_FUNCTION_CALL: {
	for my $kw (@SCHEDULED) {
		my $code = "$kw()";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_AMPERSAND_CALL: {
	for my $kw (@SCHEDULED) {
		my $code = "&$kw";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_CODE_REFERENCE: {
	for my $kw (@SCHEDULED) {
		my $code = "\\&$kw";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_DEFINED_CHECK: {
	for my $kw (@SCHEDULED) {
		my $code = "defined &$kw";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_FAT_COMMA: {
	for my $kw (@SCHEDULED) {
		my $code = "$kw => 1";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_FAT_COMMA_IN_LIST: {
	for my $kw (@SCHEDULED) {
		my $code = "my \%h = ($kw => 1)";
		my $doc = safe_new \$code;
		my @found = grep { $_->isa('PPI::Statement::Scheduled') }
			@{ $doc->find('PPI::Statement') || [] };
		is scalar @found, 0,
			"my \%h = ($kw => 1): no scheduled blocks";
	}
}

NOT_SCHEDULED_HASH_SUBSCRIPT: {
	for my $kw (@SCHEDULED) {
		my $code = "\$h{$kw}";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_METHOD_CALL: {
	for my $kw (@SCHEDULED) {
		my $code = "\$obj->$kw()";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_METHOD_DEREF: {
	for my $kw (@SCHEDULED) {
		my $code = "$kw->()";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_OPEN_PATTERN: {
	for my $kw (@SCHEDULED) {
		my $code = "open($kw, \"file\")";
		my $doc = safe_new \$code;
		my @found = grep { $_->isa('PPI::Statement::Scheduled') }
			@{ $doc->find('PPI::Statement') || [] };
		is scalar @found, 0,
			"open($kw, \"file\"): no scheduled blocks";
	}
}

NOT_SCHEDULED_LABEL: {
	for my $kw (@SCHEDULED) {
		my $code = "$kw: { 1 }";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		isa_ok $st, 'PPI::Statement::Compound',
			"$code: label creates compound statement";
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: not a scheduled block";
	}
}

NOT_SCHEDULED_LABEL_WITH_SPACE: {
	for my $kw (@SCHEDULED) {
		my $code = "$kw : { 1 }";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		isa_ok $st, 'PPI::Statement::Compound',
			"$code: label with space creates compound statement";
	}
}

NOT_SCHEDULED_CORE_PREFIXED: {
	for my $kw (@SCHEDULED) {
		my $code = "CORE::$kw";
		my $doc = safe_new \$code;
		my ($st) = $doc->schildren;
		ok !$st->isa('PPI::Statement::Scheduled'),
			"$code: CORE:: prefixed is not a scheduled block";
	}
}

NESTED_IN_BLOCK: {
	for my $kw (@SCHEDULED) {
		my $code = "if (1) { $kw { 1 } }";
		my $doc = safe_new \$code;
		my @found = @{ $doc->find('PPI::Statement::Scheduled') || [] };
		is scalar @found, 1,
			"$code: scheduled block found inside if block";
		is $found[0]->type, $kw,
			"$code: nested type()";
	}
}

NESTED_IN_EVAL: {
	for my $kw (@SCHEDULED) {
		my $code = "eval { $kw { 1 } }";
		my $doc = safe_new \$code;
		my @found = @{ $doc->find('PPI::Statement::Scheduled') || [] };
		is scalar @found, 1,
			"$code: scheduled block found inside eval";
	}
}

AFTER_PACKAGE: {
	for my $kw (@SCHEDULED) {
		my $code = "package Foo; $kw { 1 }";
		my $doc = safe_new \$code;
		my @found = @{ $doc->find('PPI::Statement::Scheduled') || [] };
		is scalar @found, 1,
			"$code: scheduled block after package declaration";
	}
}

MULTIPLE_SAME_TYPE: {
	for my $kw (@SCHEDULED) {
		my $code = "$kw { 1 } $kw { 2 }";
		my $doc = safe_new \$code;
		my @found = @{ $doc->find('PPI::Statement::Scheduled') || [] };
		is scalar @found, 2,
			"$code: two scheduled blocks of same type";
	}
}

MIXED_TYPES: {
	my $code = "BEGIN { 1 } END { 2 }";
	my $doc = safe_new \$code;
	my @found = @{ $doc->find('PPI::Statement::Scheduled') || [] };
	is scalar @found, 2, "BEGIN + END: two scheduled blocks found";
	is $found[0]->type, 'BEGIN', "first is BEGIN";
	is $found[1]->type, 'END', "second is END";
}

ROUND_TRIP: {
	for my $kw (@SCHEDULED) {
		for my $form ("$kw { 1 }", "sub $kw { 1 }") {
			my $doc = safe_new \$form;
			is $doc->serialize, $form,
				"$form: round-trip serialize";
		}
	}
}
