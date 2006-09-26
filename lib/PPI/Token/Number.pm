package PPI::Token::Number;

=pod

=head1 NAME

PPI::Token::Number - Token class for a number

=head1 SYNOPSIS

  $n = 1234;       # decimal integer
  $n = 0b1110011;  # binary integer
  $n = 01234;      # octal integer
  $n = 0x1234;     # hexadecimal integer
  $n = 12.34e-56;  # exponential notation ( currently not working )

=head1 INHERITANCE

  PPI::Token::Number
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

The C<PPI::Token::Number> class is used for tokens that represent numbers,
in the various types that Perl supports.

=head1 METHODS

=cut

use strict;
use base 'PPI::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.118';
}

=head2 base

The C<base> method is provided by all of the ::Number subclasses.
This is 10 for decimal, 16 for hexadecimal, 2 for binary, etc.

=cut

sub base {
	my $self = shift;
	return $self->{_base} || 10;
}


#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;
	my $char  = substr( $t->{line}, $t->{line_cursor}, 1 );

	# Allow underscores straight through
	return 1 if $char eq '_';

	# Handle the conversion from an unknown to known type.
	# The regex covers "potential" hex/bin/octal number.
	my $token = $t->{token};
	if ( $token->{content} =~ /^-?0_*$/ ) {
		# This could be special
		if ( $char eq 'x' ) {
			return $t->_set_token_class( 'Number::Hex' ) ? 1 : undef;
		} elsif ( $char eq 'b' ) {
			return $t->_set_token_class( 'Number::Binary' ) ? 1 : undef;
		} elsif ( $char =~ /\d/ ) {
			# You cannot have 8s and 9s on octals
			if ( $char eq '8' or $char eq '9' ) {
				$token->{_error} = "Illegal character in octal number '$char'";
			}
			return $t->_set_token_class( 'Number::Octal' ) ? 1 : undef;
		} elsif ( $char eq '.' ) {
			# TODO: class -> ::Float
			return 1;
		} else {
			# End of the number... its just 0
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}
	}

	$token->{_base} = 10 unless $token->{_base};

	# Handle the easy case, integer or real.
	return 1 if $char =~ /\d/o;

	if ( $char eq '.' ) {
		if ( $token->{content} =~ /\.$/ ) {
			# We have a .., which is an operator.
			# Take the . off the end of the token..
			# and finish it, then make the .. operator.
			chop $t->{token}->{content};
			$t->_new_token('Operator', '..') or return undef;
			return 0;
		} else {
			# Will this be the first .?
			if ( $token->{content} =~ /\./ ) {
				# TODO: class -> ::VersionString
				#   but see http://perlmonks.org/?node_id=574573

				# Flag as a base256.
				$token->{_base} = 256;
			}
			return 1;
		}
		# TODO: else class -> ::Float
	}
	# TODO: else ($char eq 'e' || $char eq 'E')

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

=pod

=head1 TO DO

- Add support for exponential notation

- Break out floats and v-strings into their own modules

- Treak v-strings as binary strings or barewords, not as "base-256"
  numbers

- Break out decimal integers into their own subclass?

- Implement literal()

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
