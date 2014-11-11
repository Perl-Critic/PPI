package PPI::Token::QuoteLike::Words;

=pod

=head1 NAME

PPI::Token::QuoteLike::Words - Word list constructor quote-like operator

=head1 INHERITANCE

  PPI::Token::QuoteLike::Words
  isa PPI::Token::QuoteLike
      isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

A C<PPI::Token::QuoteLike::Words> object represents a quote-like operator
that acts as a constructor for a list of words.

  # Create a list for a significant chunk of the alphabet
  my @list = qw{a b c d e f g h i j k l};

=head1 METHODS

=cut

use strict;
use PPI::Token::QuoteLike          ();
use PPI::Token::_QuoteEngine::Full ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.220';
	@ISA     = qw{
		PPI::Token::_QuoteEngine::Full
		PPI::Token::QuoteLike
	};
}

=pod

=head2 literal

Returns the words contained.  Note that this method does not check the
context that the token is in; it always returns the list and not merely
the last element if the token is in scalar context.

=cut

sub literal {
	my $self    = shift;
	my $section = $self->{sections}->[0];
	return split ' ', substr(
		$self->{content},
		$section->{position},
		$section->{size},
	);
}

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
