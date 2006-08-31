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
	$VERSION = '1.116';
}

=head2 base

Returns the base for the number.  This is 10 for decimal, 16 for hexadecimal, etc.

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
			$token->{_base} = 16;
			return 1;
		} elsif ( $char eq 'b' ) {
			$token->{_base} = 2;
			return 1;
		} elsif ( $char =~ /\d/ ) {
			$token->{_base} = 8;
			return 1;
		} elsif ( $char eq '.' ) {
			return 1;
		} else {
			# End of the number... its just 0
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}
	}

	$token->{_base} = 10 unless $token->{_base};

	if ( $token->{_base} == 10 or $token->{_base} == 256 ) {
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
					return 1;
				} else {
					# Flag as a base256.
					$token->{_base} = 256;
					return 1;
				}
			}
		}

	} elsif ( $token->{_base} == 8 ) {
		if ( $char =~ /\d/ ) {
			# You cannot have 8s and 9s on octals
			if ( $char eq '8' or $char eq '9' ) {
				$token->{_error} = "Illegal character in octal number '$char'";
			}
			return 1;
		}

	} elsif ( $token->{_base} == 16 ) {
		if ( $char =~ /\w/ ) {
			unless ( $char =~ /[\da-f]/ ) {
				# Add a warning if it contains non-hex chars
				$token->{_error} = "Illegal character in hexidecimal number '$char'";
			}
			return 1;
		}

	} elsif ( $token->{_base} == 2 ) {
		if ( $char =~ /[\w\d]/ ) {
			unless ( $char eq '1' or $char eq '0' ) {
				# Add a warning if it contains non-hex chars
				$token->{_error} = "Illegal character in binary number '$char'";
			}
			return 1;
		}

	} else {
		Carp::croak("Unknown number type 'base$token->{_base}'");
	}

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

1;

=pod

=head1 TO DO

- Add proper unit testing to this

- Add support for exponential notation

- What the hell is a base256 number and why did I use it.
  Surely it should be something more like "base1000" or "version".

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
