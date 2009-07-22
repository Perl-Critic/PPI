package PPI::Token::QuoteLike::Regexp;

=pod

=head1 NAME

PPI::Token::QuoteLike::Regexp - Regexp constructor quote-like operator

=head1 INHERITANCE

  PPI::Token::QuoteLike::Regexp
  isa PPI::Token::QuoteLike
      isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

A C<PPI::Token::QuoteLike::Regexp> object represents the quote-like
operator used to construct anonymous L<Regexp> objects, as follows.

  # Create a Regexp object for a module filename
  my $module = qr/\.pm$/;

=head1 METHODS

There are no methods available for C<PPI::Token::QuoteLike::Regexp>
beyond those provided by the parent L<PPI::Token::QuoteLike>,
L<PPI::Token> and L<PPI::Element> classes.

Got any ideas for methods? Submit a report to rt.cpan.org!

=cut

use strict;
use PPI::Token::QuoteLike          ();
use PPI::Token::_QuoteEngine::Full ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.204_06';
	@ISA     = qw{
		PPI::Token::_QuoteEngine::Full
		PPI::Token::QuoteLike
	};
}

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
