#!/usr/bin/perl

# Verify that location caches are automatically invalidated
# after document mutations (insert, remove, replace, add, prune).

use lib 't/lib';
use PPI::Test::pragmas;

use PPI::Document ();
use PPI::Token::Whitespace ();
use PPI::Token::Comment ();
use PPI::Statement ();
use Test::More tests => 6 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use Helper 'safe_new';

subtest 'insert_before invalidates locations' => sub {
	my $doc = safe_new \"my \$x = 1;\nmy \$y = 2;\n";

	my @stmts = $doc->children;
	my $y_stmt = $stmts[2];
	is $y_stmt->first_token->content, 'my',
		'found second my statement';
	is_deeply $y_stmt->first_token->location, [ 2, 1, 1, 2, undef ],
		'$y stmt starts at line 2 before insert';

	my $new_ws = PPI::Token::Whitespace->new("\n");
	my $new_doc = safe_new \"# inserted\n";
	my $new_comment = $new_doc->find_first('PPI::Token::Comment')->remove;

	$y_stmt->insert_before( $new_comment );
	$y_stmt->insert_before( $new_ws );

	local $TODO = "location cache not yet auto-invalidated on mutation";
	is_deeply $y_stmt->first_token->location, [ 3, 1, 1, 3, undef ],
		'$y stmt location updated after insert_before';
};

subtest 'insert_after invalidates locations' => sub {
	my $doc = safe_new \"my \$x = 1;\nmy \$y = 2;\n";

	my @stmts = $doc->children;
	my $x_stmt = $stmts[0];
	my $y_stmt = $stmts[2];
	is_deeply $y_stmt->first_token->location, [ 2, 1, 1, 2, undef ],
		'$y stmt starts at line 2 before insert';

	my $sep = $stmts[1];
	my $new_ws = PPI::Token::Whitespace->new("\n");
	my $new_doc = safe_new \"# inserted\n";
	my $new_comment = $new_doc->find_first('PPI::Token::Comment')->remove;

	$sep->insert_after( $new_comment );
	$sep->insert_after( $new_ws );

	local $TODO = "location cache not yet auto-invalidated on mutation";
	is_deeply $y_stmt->first_token->location, [ 4, 1, 1, 4, undef ],
		'$y stmt location updated after insert_after';
};

subtest 'remove invalidates locations' => sub {
	my $doc = safe_new \"# first\nmy \$x = 1;\nmy \$y = 2;\n";

	my $comment = $doc->find_first('PPI::Token::Comment');
	my @stmts = grep { $_->isa('PPI::Statement') } $doc->children;
	my $y_stmt = $stmts[1];
	is_deeply $y_stmt->first_token->location, [ 3, 1, 1, 3, undef ],
		'$y stmt starts at line 3 before remove';

	$comment->remove;

	local $TODO = "location cache not yet auto-invalidated on mutation";
	is_deeply $y_stmt->first_token->location, [ 2, 1, 1, 2, undef ],
		'$y stmt location updated after remove';
};

subtest 'replace invalidates locations' => sub {
	my $doc = safe_new \"my \$x = 1 + 2;\n";

	my $plus = $doc->find_first(
		sub { $_[1]->isa('PPI::Token::Operator') and $_[1]->content eq '+' }
	);
	is $plus->content, '+', 'found plus operator';
	is_deeply $plus->location, [ 1, 11, 11, 1, undef ],
		'plus at column 11 before replace';

	my $one = ($doc->find('PPI::Token::Number'))->[0];
	my $replacement = PPI::Token::Number->new('100');
	$one->replace( $replacement );

	local $TODO = "location cache not yet auto-invalidated on mutation";
	is_deeply $plus->location, [ 1, 13, 13, 1, undef ],
		'plus column updated after replacing 1 with 100';
};

subtest 'add_element invalidates locations' => sub {
	my $doc = safe_new \"sub foo { 1 }\nmy \$y = 2;\n";

	my @stmts = grep { $_->isa('PPI::Statement') } $doc->children;
	my $y_stmt = $stmts[1];
	is_deeply $y_stmt->first_token->location, [ 2, 1, 1, 2, undef ],
		'$y stmt starts at line 2 before add';

	my $block = $doc->find_first('PPI::Structure::Block');
	$block->add_element( PPI::Token::Whitespace->new("\n") );
	my $new_stmt = PPI::Statement->new;
	$new_stmt->add_element( PPI::Token::Word->new('bar') );
	$block->add_element( $new_stmt );
	$block->add_element( PPI::Token::Whitespace->new("\n") );

	local $TODO = "location cache not yet auto-invalidated on mutation";
	is_deeply $y_stmt->first_token->location, [ 4, 1, 1, 4, undef ],
		'$y stmt pushed down after adding lines to block';
};

subtest 'prune invalidates locations' => sub {
	my $doc = safe_new \"# first\nmy \$x = 1;\nmy \$y = 2;\n";

	my @stmts = grep { $_->isa('PPI::Statement') } $doc->children;
	my $y_stmt = $stmts[1];
	is_deeply $y_stmt->first_token->location, [ 3, 1, 1, 3, undef ],
		'$y stmt starts at line 3 before prune';

	$doc->prune('PPI::Token::Comment');

	local $TODO = "location cache not yet auto-invalidated on mutation";
	is_deeply $y_stmt->first_token->location, [ 2, 1, 1, 2, undef ],
		'$y stmt location updated after prune removes comment';
};
