#!/usr/bin/perl

use strict;

use lib 't/lib';
use PPI::Test::pragmas;

use Test::More tests => 34 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use PPI::Document ();

run();

sub run {
	# Subclasses with a default brace type can be created with no arguments
	for my $case (
		[ 'PPI::Structure::Condition', '()', '(' ],
		[ 'PPI::Structure::For',       '()', '(' ],
		[ 'PPI::Structure::Given',     '()', '(' ],
		[ 'PPI::Structure::When',      '()', '(' ],
		[ 'PPI::Structure::List',      '()', '(' ],
		[ 'PPI::Structure::Signature', '()', '(' ],
		[ 'PPI::Structure::Block',     '{}', '{' ],
	) {
		my ( $class, $braces, $open ) = @$case;
		my $struct = $class->new;
		isa_ok $struct, $class, "$class->new";
		is $struct->braces, $braces, "$class->new has correct braces";
		ok $struct->complete, "$class->new is complete";
	}

	# Subclasses without a default brace type require an explicit brace
	for my $class (
		'PPI::Structure::Constructor',
		'PPI::Structure::Subscript',
		'PPI::Structure::Unknown',
		'PPI::Structure',
	) {
		my $struct = $class->new;
		is $struct, undef, "$class->new with no args returns undef";
	}

	# Explicit brace character argument
	{
		my $sq = PPI::Structure::Constructor->new('[');
		isa_ok $sq, 'PPI::Structure::Constructor', 'Constructor->new("[")';
		is $sq->braces, '[]', 'Constructor with [ has [] braces';

		my $cu = PPI::Structure::Subscript->new('{');
		isa_ok $cu, 'PPI::Structure::Subscript', 'Subscript->new("{")';
		is $cu->braces, '{}', 'Subscript with { has {} braces';
	}

	# content() returns the braces with no inner content
	{
		my $cond = PPI::Structure::Condition->new;
		is $cond->content, '()', 'Condition content is ()';

		my $block = PPI::Structure::Block->new;
		is $block->content, '{}', 'Block content is {}';
	}

	# Backward compatibility: token-based construction still works
	{
		my $token = PPI::Token::Structure->new('(');
		my $struct = PPI::Structure::Condition->new($token);
		isa_ok $struct, 'PPI::Structure::Condition',
			'token-based construction';
		is $struct->start, $token,
			'token-based construction preserves start token';
		ok !$struct->complete,
			'token-based construction leaves finish unset';
	}
}

1;
