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

There are no methods available for C<PPI::Token::QuoteLike::Words>
beyond those provided by the parent L<PPI::Token::QuoteLike>,
L<PPI::Token> and L<PPI::Element> classes.

Got any ideas for methods? Submit a report to rt.cpan.org!

=cut

use strict;
use base 'PPI::Token::_QuoteEngine::Full',
         'PPI::Token::QuoteLike';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.199_07';
}

1;

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
