package Helper;

use strict;
use warnings;

use parent 'Exporter';
use Test::More;

use PPI::Document ();

our @EXPORT_OK = qw( check_with  safe_new );

=head1 safe_new @args

	my $doc = safe_new \"use strict";

Creates a PPI::Document object from the arguments and reports errors if
necessary. Can be used to replace most document new calls in the tests for
easier testing.

=cut

sub safe_new {
	my $Document = PPI::Document->new(@_);
	is( PPI::Document->errstr, '', "no errors" );
	isa_ok $Document, 'PPI::Document';
	return $Document;
}

=head1 check_with

	check_with "1.eqm'bar';", sub {
		is $_->child( 0 )->child( 1 )->content, "eqm'bar",
		  "eqm' bareword after number and concat op is not mistaken for eq";
	};

Creates a document object from the given code and stores it in $_, so the sub
passed in the second argument can quickly run tests on it.

=cut

sub check_with {
	my ( $code, $checker ) = @_;
	local $_ = safe_new \$code;
	return $checker->();
}

1;
