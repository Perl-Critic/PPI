package PPI::Token::Number::Version;

=pod

=head1 NAME

PPI::Token::Number::Version - Token class for a byte-packed number

=head1 SYNOPSIS

  $n = 1.1.0;
  $n = 127.0.0.1;
  $n = 10_000.10_000.10_000;
  $n = v1.2.3.4

=head1 INHERITANCE

  PPI::Token::Number::Version
  isa PPI::Token::Number
      isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

The C<PPI::Token::Number::Version> class is used for tokens that have
multiple decimal points.  In truth, these aren't treated like numbers
at all by Perl, but they look like numbers to a parser.

=head1 METHODS

=cut

use strict;
use PPI::Token::Number ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.216_01';
	@ISA     = 'PPI::Token::Number';
}

=pod

=head2 base

Returns the base for the number: 256.

=cut

sub base() { 256 }

=pod

=head2 literal

Return the numeric value of this token.

=cut

sub literal {
	my $self    = shift;
	my $content = $self->{content};
	$content =~ s/^v//;
	return join '', map { chr $_ } ( split /\./, $content );
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $class = shift;
	my $t     = shift;
	my $char  = substr( $t->{line}, $t->{line_cursor}, 1 );

	# Allow digits
	return 1 if $char =~ /\d/o;

	# Is this a second decimal point in a row?  Then the '..' operator
	if ( $char eq '.' ) {
		if ( $t->{token}->{content} =~ /\.$/ ) {
			# We have a .., which is an operator.
			# Take the . off the end of the token..
			# and finish it, then make the .. operator.
			chop $t->{token}->{content};
			$t->{class} = $t->{token}->set_class( 'Number::Float' );
			$t->_new_token('Operator', '..');
			return 0;
		} else {
			return 1;
		}
	}

	# Doesn't fit a special case, or is after the end of the token
	# End of token.
	$t->_finalize_token->__TOKENIZER__on_char( $t );
}

sub __TOKENIZER__commit {
	my $t = $_[1];

	# Get the rest of the line
	pos $t->{line} = $t->{line_cursor};
	if ( $t->{line} !~ m/\G(v\d+(?:\.\d+)*)/gc ) {
		# This was not a v-string after all (it's a word)
		return PPI::Token::Word->__TOKENIZER__commit($t);
	}

	# This is a v-string
	my $vstring = $1;
	$t->{line_cursor} += length($vstring);
	$t->_new_token('Number::Version', $vstring);
	$t->_finalize_token->__TOKENIZER__on_char($t);
}

1;

=pod

=head1 BUGS

- Does not handle leading minus sign correctly. Should translate to a DashedWord.
See L<http://perlmonks.org/?node_id=574573>

  -95.0.1.0  --> "-_\000\cA\000"
  -96.0.1.0  --> Argument "`\0^A\0" isn't numeric in negation (-)

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Chris Dolan E<lt>cdolan@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 Chris Dolan.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
