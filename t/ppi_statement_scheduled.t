#!/usr/bin/perl

# Test PPI::Statement::Scheduled

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 320 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';


SUB_WORD_OPTIONAL: {
	for my $name ( qw( BEGIN CHECK UNITCHECK INIT END ) ) {
		for my $sub ( '', 'sub ' ) {

			# '{}' -- function definition
			# ';' -- function declaration
			# '' -- function declaration with missing semicolon
			for my $followed_by ( ' {}', '{}', ';', '' ) {
				test_sub_as( $sub, $name, $followed_by );
			}
		}
	}
}

sub test_sub_as {
	my ( $sub, $name, $followed_by ) = @_;

	my $code     = "$sub$name$followed_by";
	my $Document = safe_new \$code;

	my ( $sub_statement, $dummy ) = $Document->schildren;
	isa_ok( $sub_statement, 'PPI::Statement::Scheduled', "$code: document child is a scheduled statement" );
	is( $dummy, undef, "$code: document has exactly one child" );
	ok( $sub_statement->reserved, "$code: is reserved" );
	is( $sub_statement->name, $name, "$code: name() correct" );

	if ( $followed_by =~ /}/ ) {
		isa_ok( $sub_statement->block, 'PPI::Structure::Block', "$code: has a block" );
	}
	else {
		ok( !$sub_statement->block, "$code: has no block" );
	}

	return;
}


BAREWORD_FILEHANDLE: {
	for my $name ( qw( BEGIN CHECK UNITCHECK INIT END ) ) {
		my $code     = "open($name, '/foo');";
		my $Document = safe_new \$code;

		my $scheduled = $Document->find('PPI::Statement::Scheduled');
		ok( !$scheduled, "$code: no PPI::Statement::Scheduled found" );

		my ($stmt) = $Document->schildren;
		isa_ok( $stmt, 'PPI::Statement', "$code: top-level statement" );
		my $list = $stmt->schild(1);
		isa_ok( $list, 'PPI::Structure::List', "$code: has list structure" );
		my ($expr) = $list->schildren;
		isa_ok( $expr, 'PPI::Statement::Expression', "$code: list child is expression" );

		my $word = $expr->schild(0);
		isa_ok( $word, 'PPI::Token::Word', "$code: first token is Word" );
		is( $word->content, $name, "$code: word content is $name" );
	}
}
