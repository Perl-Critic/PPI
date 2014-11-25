#!/usr/bin/perl

# Unit testing for PPI::Token::Unknown

use t::lib::PPI::Test::pragmas;
use Test::More tests => 3;

use PPI;

sub o { test_cast_or_op( @_ ) }
sub c { test_cast_or_op( @_, 1 ) }

OPERATOR_CAST: {
	o '$c{d}*$e';
	o '1%$a';
	
	# * % &
	# $ @ % * {
	o '1*$a';
	o '1*@a';
	o '1*%a';
	o '1**a';
	o '1**{$a}';
	o '1*{2}';

	o '1%$a';
	o '1%@a';
	o '1%%a';
	o '1%*a';
	o '1%{2}';

	o '1&$a';
	o '1&@a';
	o '1&%a';
	o '1&*a';
	o '1&{2}';
	
}

sub test_cast_or_op {
	my ( $code, $want_cast ) = @_;

	my $d        = PPI::Document->new( \$code );
	my @tokens   = @{ $d->find( sub { 1 } ) };
	my @types    = map { ref $_ } @tokens;
	my $has_cast = grep { $_ eq 'PPI::Token::Cast' } @types;
	my $has_op   = grep { $_ eq 'PPI::Token::Operator' } @types;
	return
	  if $want_cast
	  ? ( ok( $has_cast, "$code: has cast" ) and ok( !$has_op, "$code: has no op" ) )
	  : ( ok( $has_op, "$code: has op" ) and ok( !$has_cast, "$code: has no cast" ) );

	@tokens = map { ref $_, $_->content } @tokens;
	diag explain \@tokens;
	return;
}
