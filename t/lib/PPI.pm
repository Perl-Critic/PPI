package t::lib::PPI;

use Test::More;
use Test::Object;
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# PPI::Document Testing

Test::Object->register(
	class => 'PPI::Document',
	tests => 1,
	code  => \&document_ok,
);

sub document_ok {
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





#####################################################################
# Are there an unknowns

Test::Object->register(
	class => 'PPI::Document',
	tests => 3,
	code  => \&unknown_objects,
);

sub unknown_objects {
	my $doc = shift;

	is( $doc->find_any('Token::Unknown'), '',
		"Contains no PPI::Token::Unknown elements" );
	is( $doc->find_any('Structure::Unknown'), '',
		"Contains no PPI::Structure::Unknown elements" );
	is( $doc->find_any('Statement::Unknown'), '',
		"Contains no PPI::Statement::Unknown elements" );

	1;
}

1;
