#!/usr/bin/perl

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use PPI;

use Test::More tests => 275;


FIND_ONE_OP: {
	my $source = '$a = .987;';
	my $doc = PPI::Document->new( \$source );
	isa_ok( $doc, 'PPI::Document', "parsed '$source'" );
	my $ops = $doc->find( 'Token::Number::Float' );
	is( ref $ops, 'ARRAY', "found number" );
	is( @$ops, 1, "number found exactly once" );
	is( $ops->[0]->content(), '.987', "text matches" );

	$ops = $doc->find( 'Token::Operator' );
	is( ref $ops, 'ARRAY', "operator = found operators in number test" );
	is( @$ops, 1, "operator = found exactly once in number test" );
}


HEREDOC: {
	my $source = '$a = <<PERL_END;' . "\n" . 'PERL_END';
	my $doc = PPI::Document->new( \$source );
	isa_ok( $doc, 'PPI::Document', "parsed '$source'" );
	my $ops = $doc->find( 'Token::HereDoc' );
	is( ref $ops, 'ARRAY', "found heredoc" );
	is( @$ops, 1, "heredoc found exactly once" );

	$ops = $doc->find( 'Token::Operator' );
	is( ref $ops, 'ARRAY', "operator = found operators in heredoc test" );
	is( @$ops, 1, "operator = found exactly once in heredoc test" );
}


PARSE_ALL_OPERATORS: {
	foreach my $op ( sort keys %PPI::Token::Operator::OPERATOR ) {
		my $source = $op eq '<>' ? '<>;' : "1 $op 2;";
		my $doc = PPI::Document->new( \$source );
		isa_ok( $doc, 'PPI::Document', "operator $op parsed '$source'" );
		my $ops = $doc->find( $op eq '<>' ? 'Token::QuoteLike::Readline' : 'Token::Operator' );
		is( ref $ops, 'ARRAY', "operator $op found operators" );
		is( @$ops, 1, "operator $op found exactly once" );
		is( $ops->[0]->content(), $op, "operator $op operator text matches" );
	}
}

1;
