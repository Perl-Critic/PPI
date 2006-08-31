package PPI::Token::Word;

=pod

=head1 NAME

PPI::Token::Word - The generic "word" Token

=head1 INHERITANCE

  PPI::Token::Word
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

A C<PPI::Token::Word> object is a PPI-specific representation of several
different types of word-like things, and is one of the most common Token
classes found in typical documents.

Specifically, it includes not only barewords, but also any other valid
Perl identifier including non-operator keywords and core functions, and
any include C<::> separators inside it, as long as it fits the
format of a class, function, etc.

=head1 METHODS

There are no methods available for C<PPI::Token::Word> beyond those
provided by its L<PPI::Token> and L<PPI::Element> parent
classes.

We expect to add additional methods to help further resolve a Word as
a function, method, etc over time.

=cut

use strict;
use base 'PPI::Token';

use vars qw{$VERSION %QUOTELIKE %OPERATOR};
BEGIN {
	$VERSION = '1.116';

	%QUOTELIKE = (
		'q'  => 'Quote::Literal',
		'qq' => 'Quote::Interpolate',
		'qx' => 'QuoteLike::Command',
		'qw' => 'QuoteLike::Words',
		'qr' => 'QuoteLike::Regexp',
		'm'  => 'Regexp::Match',
		's'  => 'Regexp::Substitute',
		'tr' => 'Regexp::Transliterate',
		'y'  => 'Regexp::Transliterate',
		);

	# Copy in OPERATOR from PPI::Token::Operator
	*OPERATOR = *PPI::Token::Operator::OPERATOR;
}

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;

	# Suck in till the end of the bareword
	my $line = substr( $t->{line}, $t->{line_cursor} );
	if ( $line =~ /^(\w+(?:(?:\'|::)(?!\d)\w+)*(?:::)?)/ ) {
		$t->{token}->{content} .= $1;
		$t->{line_cursor} += length $1;

		# Special Case: If we accidentally treat eq'foo' like the word "eq'foo",
		# then unwind it and just make it 'eq' (or the other stringy comparitors)
		if ( $t->{token}->{content} =~ /^(?:eq|ne|q|qq|qx|qw|qr|m|s|tr|y)\'/ ) {
			if ( substr($t->{token}->{content}, 1, 1) eq "'" ) {
				$t->{line_cursor} -= (length($t->{token}->{content}) - 1);
				$t->{token}->{content} = substr($t->{token}->{content}, 0, 1);
			} else {
				$t->{line_cursor} -= (length($t->{token}->{content}) - 2);
				$t->{token}->{content} = substr($t->{token}->{content}, 0, 2);
			}
		}
	}

	# We might be a subroutine attribute.
	my $tokens = $t->_previous_significant_tokens(1);
	if ( $tokens and $tokens->[0]->{_attribute} ) {
		$t->_set_token_class( 'Attribute' );
		return $t->{class}->__TOKENIZER__commit( $t );
	}

	# Check for a quote like operator
	my $word = $t->{token}->{content};
	if ( $QUOTELIKE{$word} and ! $class->__TOKENIZER__literal($t, $word, $tokens) ) {
		$t->_set_token_class( $QUOTELIKE{$word} );
		return $t->{class}->__TOKENIZER__on_char( $t );
	}

	# Or one of the word operators
	if ( $OPERATOR{$word} and ! $class->__TOKENIZER__literal($t, $word, $tokens) ) {
	 	$t->_set_token_class( 'Operator' );
 		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}

	# Unless this is a simple identifier, at this point
	# it has to be a normal bareword
	if ( $word =~ /\:/ ) {
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}

	# If the NEXT character in the line is a colon, this
	# is a label.
	my $char = substr( $t->{line}, $t->{line_cursor}, 1 );
	if ( $char eq ':' ) {
		$t->{token}->{content} .= ':';
		$t->{line_cursor}++;
		$t->_set_token_class( 'Label' );

	# If not a label, '_' on its own is the magic filehandle
	} elsif ( $word eq '_' ) {
		$t->_set_token_class( 'Magic' );

	}

	# Finalise and process the character again
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

# We are committed to being a bareword.
# Or so we would like to believe.
sub __TOKENIZER__commit {
	my ($class, $t) = @_;

	# Our current position is the first character of the bareword.
	# Capture the bareword.
	my $line = substr( $t->{line}, $t->{line_cursor} );
	unless ( $line =~ /^((?!\d)\w+(?:(?:\'|::)(?!\d)\w+)*(?:::)?)/ ) {
		# Programmer error
		die "Fatal error... regex failed to match in '$line' when expected";
	}

	# Special Case: If we accidentally treat eq'foo' like the word "eq'foo",
	# then unwind it and just make it 'eq' (or the other stringy comparitors)
	my $word = $1;
	if ( $word =~ /^(?:eq|ne|q|qq|qx|qw|qr|m|s|tr|y)\'/ ) {
		if ( substr($word, 1, 1) eq "'" ) {
			$word = substr($word, 0, 1);
		} else {
			$word = substr($word, 0, 2);
		}
	}

	# Advance the position one after the end of the bareword
	$t->{line_cursor} += length $word;

	# We might be a subroutine attribute.
	my $tokens = $t->_previous_significant_tokens(1);
	if ( $tokens and $tokens->[0]->{_attribute} ) {
		$t->_new_token( 'Attribute', $word );
		return ($t->{line_cursor} >= $t->{line_length}) ? 0
			: $t->{class}->__TOKENIZER__on_char($t);
	}

	# Check for the end of the file
	if ( $word eq '__END__' ) {
		# Create the token for the __END__ itself
		$t->_new_token( 'Separator', $1 );
		$t->_finalize_token;

		# Move into the End zone (heh)
		$t->{zone} = 'PPI::Token::End';

		# Add the rest of the line as a comment, and a whitespace newline
		# Anything after the __END__ on the line is "ignored". So we must
		# also ignore it, by turning it into a comment.
		$line = substr( $t->{line}, $t->{line_cursor} );
		$t->{line_cursor} = length $t->{line};
		if ( $line =~ /\n$/ ) {
			chomp $line;
			$t->_new_token( 'Comment', $line ) if length $line;
			$t->_new_token( 'Whitespace', "\n" );
		} else {
			$t->_new_token( 'Comment', $line ) if length $line;
		}
		$t->_finalize_token;

		return 0;
	}

	# Check for the data section
	if ( $word eq '__DATA__' ) {
		# Create the token for the __DATA__ itself
		$t->_new_token( 'Separator', "$1" );
		$t->_finalize_token;

		# Move into the Data zone
		$t->{zone} = 'PPI::Token::Data';

		# Add the rest of the line as the Data token
		$line = substr( $t->{line}, $t->{line_cursor} );
		$t->{line_cursor} = length $t->{line};
		if ( $line =~ /\n$/ ) {
			chomp $line;
			$t->_new_token( 'Comment', $line ) if length $line;
			$t->_new_token( 'Whitespace', "\n" );
		} else {
			$t->_new_token( 'Comment', $line ) if length $line;
		}
		$t->_finalize_token;

		return 0;
	}

	my $token_class;
	if ( $word =~ /\:/ ) {
		# Since its not a simple identifier...
		$token_class = 'Word';

	} elsif ( $class->__TOKENIZER__literal($t, $word, $tokens) ) {
		$token_class = 'Word';

	} elsif ( $QUOTELIKE{$word} ) {
		# Special Case: A Quote-like operator
		$t->_new_token( $QUOTELIKE{$word}, $word );
		return ($t->{line_cursor} >= $t->{line_length}) ? 0
			: $t->{class}->__TOKENIZER__on_char( $t );

	} elsif ( $OPERATOR{$word} ) {
		# Word operator
		$token_class = 'Operator';

	} else {
		# Now, if the next character is a :, its a label
		my $char = substr( $t->{line}, $t->{line_cursor}, 1 );
		if ( $char eq ':' ) {
			$word .= ':';
			$t->{line_cursor}++;
			$token_class = 'Label';
		} elsif ( $word eq '_' ) {
			$token_class = 'Magic';
		} else {
			$token_class = 'Word';
		}
	}

	# Create the new token and finalise
	$t->_new_token( $token_class, $word );
	if ( $t->{line_cursor} >= $t->{line_length} ) {
		# End of the line
		$t->_finalize_token;
		return 0;
	}
	$t->_finalize_token->__TOKENIZER__on_char($t);
}

# Is the word in a "forced" context, and thus cannot be either an
# operator or a quote-like thing. This version is only useful
# during tokenization.
sub __TOKENIZER__literal {
	my ($class, $t, $word, $tokens) = @_;

	# Is this a forced-word context?
	# i.e. Would normally be seen as an operator.
	unless ( $QUOTELIKE{$word} or $PPI::Token::Operator::OPERATOR{$word} ) {
		return '';
	}

	# Check the cases when we have previous tokens
	my $line = substr( $t->{line}, $t->{line_cursor} );
	if ( $tokens ) {
		my $token = $tokens->[0] or return '';

		# We are forced if we are a method name
		return 1 if $token->{content} eq '->';

		# We are forced if we are a sub name
		return 1 if $token->isa('PPI::Token::Word') && $token->{content} eq 'sub';

		# If we are contained in a pair of curly braces,
		# we are probably a bareword hash key
		if ( $token->{content} eq '{' and $line =~ /^\s*\}/ ) {
			return 1;
		}
	}

	# In addition, if the word is followed by => it is probably
	# also actually a word and not a regex.
	if ( $line =~ /^\s*=>/ ) {
		return 1;
	}

	# Otherwise we probably arn't forced
	'';
}

1;

=pod

=head1 TO DO

- Add C<function>, C<method> etc detector methods

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
