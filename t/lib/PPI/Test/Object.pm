package PPI::Test::Object;

use File::Spec::Functions ':ALL';
use Test::More;
use Test::Object;
use Params::Util qw{_STRING _INSTANCE};
use List::MoreUtils 'any';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.216_01';
}

sub r {
	my ( $class, $tests, $code ) = @_;
	Test::Object->register( class => $class, tests => $tests, code  => $code );
}

#####################################################################
# PPI::Document Testing

r(
	'PPI::Document', 1, sub {
		my $doc = shift;

		# A document should have zero or more children that are either
		# a statement or a non-significant child.
		my @children = $doc->children;
		my $good = grep {
			_INSTANCE($_, 'PPI::Statement')
			or (
				_INSTANCE($_, 'PPI::Token') and ! $_->significant
				)
			} @children;

		is( $good, scalar(@children),
			'Document contains only statements and non-significant tokens' );

		1;
	}
);

#####################################################################
# Are there an unknowns

r(
	'PPI::Document', 3, sub {
		my $doc = shift;

		is(
			$doc->find_any('Token::Unknown'),
			'',
			"Contains no PPI::Token::Unknown elements",
		);
		is(
			$doc->find_any('Structure::Unknown'),
			'',
			"Contains no PPI::Structure::Unknown elements",
		);
		is(
			$doc->find_any('Statement::Unknown'),
			'',
			"Contains no PPI::Statement::Unknown elements",
		);

		1;
	}
);

#####################################################################
# Are there any invalid nestings?

r(
	'PPI::Document', 1, sub {
		my $doc = shift;

		ok(
			! $doc->find_any( sub {
				_INSTANCE($_[1], 'PPI::Statement')
				and
				any { _INSTANCE($_, 'PPI::Statement') } $_[1]->children
			} ),
			'Document contains no nested statements',
		);
	}
);

r(
	'PPI::Document', 1, sub {
		my $doc = shift;

		ok(
			! $doc->find_any( sub {
				_INSTANCE($_[1], 'PPI::Structure')
				and
				any { _INSTANCE($_, 'PPI::Structure') } $_[1]->children
			} ),
			'Document contains no nested structures',
		);
	}
);

r(
	'PPI::Document', 1, sub {
		my $doc = shift;

		ok(
			! $doc->find_any( sub {
				_INSTANCE($_[1], 'PPI::Token::Attribute')
				and
				! exists $_[1]->{_attribute}
			} ),
			'No ->{_attribute} in PPI::Token::Attributes',
		);
	}
);

#####################################################################
# PPI::Statement Tests

r(
	'PPI::Document', 1, sub {
		my $document = shift;
		my $compound = $document->find('PPI::Statement::Compound');
		is(
			scalar( grep { not defined $_->type } @$compound ),
			0, 'All compound statements have defined ->type',
		);
	}
);

#####################################################################
# Does ->location work properly
# As an aside, fixes #23788: PPI::Statement::location() returns undef for C<({})>.

r(
	'PPI::Document', 1, sub {
		my $document = shift;
		my $bad      = $document->find( sub {
			not defined $_[1]->location
		} );
		is( $bad, '', '->location always defined' );
	}
);

1;
