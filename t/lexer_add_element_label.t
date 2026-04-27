#!/usr/bin/perl

# Unit testing for labeled statement detection in Lexer::_add_element
# See https://github.com/Perl-Critic/PPI/issues/51

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 18 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use PPI::Lexer ();
use Helper 'safe_new';

LABELED_STATEMENT_CLASSES: {
	my $doc = safe_new \"LABEL: for (;;) { }";
	my $st = $doc->find_first('PPI::Statement::Compound');
	ok $st, 'labeled for loop found as Compound';
	is $st->type, 'for', 'labeled for loop has type "for"';
}

LABELED_BLOCK: {
	my $doc = safe_new \"LABEL: { 1; }";
	my $st = $doc->find_first('PPI::Statement::Compound');
	ok $st, 'labeled block found as Compound';
}

LABELED_BLOCK_CONTINUE: {
	my $doc = safe_new \"LABEL: { 1; } continue { 2; }";
	my $st = $doc->find_first('PPI::Statement::Compound');
	ok $st, 'labeled block with continue found as Compound';
	my @blocks = grep { $_->isa('PPI::Structure::Block') } $st->schildren;
	is scalar @blocks, 2, 'labeled block with continue has two blocks';
}

BARE_LABEL: {
	my $doc = safe_new \"LABEL:";
	my $st = $doc->find_first('PPI::Statement::Compound');
	ok $st, 'bare label found as Compound';
	is $st->type, 'label', 'bare label has type "label"';
}

ADD_ELEMENT_RECLASSIFICATION: {
	my $lexer = PPI::Lexer->new;

	# When a PPI::Statement has a Label as schild(0) and a keyword as
	# schild(1), _add_element should re-classify to the appropriate class.
	my $parent = PPI::Statement->new;
	$parent->__add_element(PPI::Token::Label->new('LABEL:'));
	$parent->__add_element(PPI::Token::Whitespace->new(' '));
	$parent->__add_element(PPI::Token::Word->new('for'));

	$lexer->_add_element($parent, PPI::Token::Whitespace->new(' '));

	is ref $parent, 'PPI::Statement::Compound',
	   '_add_element re-classifies labeled "for" statement to Compound';

	# Unknown keywords should not cause re-classification
	my $parent2 = PPI::Statement->new;
	$parent2->__add_element(PPI::Token::Label->new('FOO:'));
	$parent2->__add_element(PPI::Token::Whitespace->new(' '));
	$parent2->__add_element(PPI::Token::Word->new('something_unknown'));

	$lexer->_add_element($parent2, PPI::Token::Whitespace->new(' '));

	is ref $parent2, 'PPI::Statement',
	   '_add_element does not re-classify for unknown keywords';

	# When label is the only significant child, should not crash
	my $parent3 = PPI::Statement->new;
	$parent3->__add_element(PPI::Token::Label->new('BAR:'));

	my $lived = eval {
		$lexer->_add_element($parent3, PPI::Token::Whitespace->new(' '));
		1;
	};

	ok $lived, '_add_element does not crash when label is only child';
}
