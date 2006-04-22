package PPI::Token::Unknown;

=pod

=head1 NAME

PPI::Token::Unknown - Token of unknown or as-yet indetermined type

=head1 INHERITANCE

  PPI::Token::Unknown
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

Object of type C<PPI::Token::Unknown> exist primarily inside the tokenizer,
where they are temporarily brought into existing for a very short time to
represent a token that could be one of a number of types.

Generally, they only exist for a character or two, after which they are
resolved and converted into the correct type. For an object of this type
to survive the parsing process is considered a major bug.

Please report any you encounter in a L<PPI::Document> object.

=cut

use strict;
use base 'PPI::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.110';
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $t = $_[1];                                    # Tokenizer object
	my $c = $t->{token}->{content};                   # Current token contents
	$_ = substr( $t->{line}, $t->{line_cursor}, 1 );  # Current character


	# Now, we split on the different values of the current content


	if ( $c eq '*' ) {
		if ( /(?:(?!\d)\w|\:)/ ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $_ eq '{' or $_ eq '$' ) {
			# GLOB cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->_finalize_token->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '$' ) {
		if ( /[a-z_]/i ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $PPI::Token::Magic::magic{ $c . $_ } ) {
			# Magic variable
			return $t->_set_token_class( 'Magic' ) ? 1 : undef;
		}

		# Must be a cast
		$t->_set_token_class( 'Cast' ) or return undef;
		return $t->_finalize_token->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '@' ) {
		if ( /[\w:]/ ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( /[\-\+\*]/ ) {
			# Magic variable
			return $t->_set_token_class( 'Magic' ) ? 1 : undef;
		}

		# Must be a cast
		$t->_set_token_class( 'Cast' ) or return undef;
		return $t->_finalize_token->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '%' ) {
		# Is it a number?
		if ( /\d/ ) {
			# This is %2 (modulus number)
			$t->_set_token_class( 'Operator' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		# Is it a symbol?
		if ( /[\w:]/ ) {
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( /[\$@%{]/ ) {
			# It's a cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );

		}

		# Probably the mod operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '&' ) {
		# Is it a number?
		if ( /\d/ ) {
			# This is &2 (bitwise-and number)
			$t->_set_token_class( 'Operator' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		# Is it a symbol
		if ( /[\w:]/ ) {
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( /[\$@%{]/ ) {
			# The ampersand is a cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->__TOKENIZER__on_char( $t );
		}

		# Probably the binary and operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->__TOKENIZER__on_char( $t );



	} elsif ( $c eq '-' ) {
		if ( /\d/o ) {
			# Number
			return $t->_set_token_class( 'Number' ) ? 1 : undef;
		}

		if ( /[a-zA-Z]/ ) {
			return $t->_set_token_class( 'DashedWord' ) ? 1 : undef;
		}

		# The numeric negative operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->__TOKENIZER__on_char( $t );



	} elsif ( $c eq ':' ) {
		if ( $_ eq ':' ) {
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

See the L<support section|PPI/SUPPORT> in the main module

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2001 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
