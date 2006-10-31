package PPI::Token::Unknown;

=pod

=head1 NAME

PPI::Token::Unknown - Token of unknown or as-yet undetermined type

=head1 INHERITANCE

  PPI::Token::Unknown
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

Object of the type C<PPI::Token::Unknown> exist primarily inside the
tokenizer, where they are temporarily brought into existing for a very
short time to represent a token that could be one of a number of types.

Generally, they only exist for a character or two, after which they are
resolved and converted into the correct type. For an object of this type
to survive the parsing process is considered a major bug.

Please report any C<PPI::Token::Unknown> you encounter in a L<PPI::Document>
object as a bug.

=cut

use strict;
use base 'PPI::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.199_02';
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $t = $_[1];                                    # Tokenizer object
	my $c = $t->{token}->{content};                   # Current token contents
	my $char = substr( $t->{line}, $t->{line_cursor}, 1 );  # Current character


	# Now, we split on the different values of the current content


	if ( $c eq '*' ) {
		if ( $char =~ /(?:(?!\d)\w|\:)/ ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $char eq '{' ) {
			# Obvious GLOB cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		if ( $char eq '$' ) {
			# Operator/operand-sensitive, multiple or GLOB cast
			my $_class = undef;
			my $tokens = $t->_previous_significant_tokens( 1 ) or return undef;
			my $p0     = $tokens->[0];
			if ( $p0 ) {
				# Is it a token or a number
				if ( $p0->isa('PPI::Token::Symbol') ) {
					$_class = 'Operator';
				} elsif ( $p0->isa('PPI::Token::Number') ) {
					$_class = 'Operator';
				} elsif (
					$p0->isa('PPI::Token::Structure')
					and
					$p0->content =~ /^(?:\)|\])$/
				) {
					$_class = 'Operator';
				} else {
					### This is pretty weak, there's
					### room for a dozen more tests
					### before going with a default.
					### Or even better, a proper
					### operator/operand method :(
					$_class = 'Cast';
				}
			} else {
				# Nothing before it, must be glob cast
				$_class = 'Cast';
			}

			# Set class and rerun
			$t->_set_token_class( $_class ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		if ( $char eq '*' || $char eq '=' ) {
			# Power operator '**' or mult-assign '*='
			return $t->_set_token_class( 'Operator' ) ? 1 : undef;
		}

		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->_finalize_token->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '$' ) {
		if ( $char =~ /[a-z_]/i ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $PPI::Token::Magic::magic{ $c . $char } ) {
			# Magic variable
			return $t->_set_token_class( 'Magic' ) ? 1 : undef;
		}

		# Must be a cast
		$t->_set_token_class( 'Cast' ) or return undef;
		return $t->_finalize_token->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '@' ) {
		if ( $char =~ /[\w:]/ ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $char =~ /[\-\+\*]/ ) {
			# Magic variable
			return $t->_set_token_class( 'Magic' ) ? 1 : undef;
		}

		# Must be a cast
		$t->_set_token_class( 'Cast' ) or return undef;
		return $t->_finalize_token->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '%' ) {
		# Is it a number?
		if ( $char =~ /\d/ ) {
			# This is %2 (modulus number)
			$t->_set_token_class( 'Operator' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		# Is it a symbol?
		if ( $char =~ /[\w:]/ ) {
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $char =~ /[\$@%{]/ ) {
			# It's a cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );

		}

		# Probably the mod operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '&' ) {
		# Is it a number?
		if ( $char =~ /\d/ ) {
			# This is &2 (bitwise-and number)
			$t->_set_token_class( 'Operator' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		# Is it a symbol
		if ( $char =~ /[\w:]/ ) {
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $char =~ /[\$@%{]/ ) {
			# The ampersand is a cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		# Probably the binary and operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '-' ) {
		if ( $char =~ /\d/o ) {
			# Number
			return $t->_set_token_class( 'Number' ) ? 1 : undef;
		}

		if ( $char eq '.' ) {
			# Number::Float
			return $t->_set_token_class( 'Number::Float' ) ? 1 : undef;
		}

		if ( $char =~ /[a-zA-Z]/ ) {
			return $t->_set_token_class( 'DashedWord' ) ? 1 : undef;
		}

		# The numeric negative operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->__TOKENIZER__on_char( $t );



	} elsif ( $c eq ':' ) {
		if ( $char eq ':' ) {
			# ::foo style bareword
			return $t->_set_token_class( 'Word' ) ? 1 : undef;
		}

		# Now, : acts very very differently in different contexts.
		# Mainly, we need to find out if this is a subroutine attribute.
		# We'll leave a hint in the token to indicate that, if it is.
		if ( $_[0]->__TOKENIZER__is_an_attribute( $t ) ) {
			# This : is an attribute indicator
			$t->_set_token_class( 'Operator' ) or return undef;
			$t->{token}->{_attribute} = 1;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		# It MIGHT be a label, but its probably the ?: trinary operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->__TOKENIZER__on_char( $t );
	}

	### erm...
	die 'Unknown value in PPI::Token::Unknown token';
}

# Are we at a location where a ':' would indicate a subroutine attribute
sub __TOKENIZER__is_an_attribute {
	my $t      = $_[1]; # Tokenizer object
	my $tokens = $t->_previous_significant_tokens( 3 ) or return undef;
	my $p0     = $tokens->[0];

	# If we just had another attribute, we are also an attribute
	if ( $p0->isa('PPI::Token::Attribute') ) {
		return 1;
	}

	# If we just had a prototype, then we are an attribute
	if ( $p0->isa('PPI::Token::Prototype') ) {
		return 1;
	}

	# Other than that, we would need to have had a bareword
	unless ( $p0->isa('PPI::Token::Word') ) {
		return '';
	}

	# We could be an anonymous subroutine
	if ( $p0->isa('PPI::Token::Word') and $p0->content eq 'sub' ) {
		return 1;
	}

	# Or, we could be a named subroutine
	my $p1 = $tokens->[1];
	my $p2 = $tokens->[2];
	if (
		$p1->isa('PPI::Token::Word')
		and
		$p1->content eq 'sub'
		and (
			$p2->isa('PPI::Token::Structure')
			or (
				$p2->isa('PPI::Token::Whitespace')
				and
				$p2->content eq ''
			)
		)
	) {
		return 1;
	}

	# We arn't an attribute
	'';	
}

1;

=pod

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
