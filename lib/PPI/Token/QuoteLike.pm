package PPI::Token::QuoteLike;

=pod

=head1 NAME

PPI::Token::QuoteLike - Quote-like operator abstract base class

=head1 INHERITANCE

  PPI::Token::QuoteLike
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

The C<PPI::Token::QuoteLike> class is never instantiated, and simply
provides a common abstract base class for the five quote-like operator
classes. In PPI, a "quote-like" is the set of quote-like things that
exclude the string quotes and regular expressions.

The subclasses of C<PPI::Token::QuoteLike> are:

qw{} - L<PPI::Token::QuoteLike::Words>

`` - L<PPI::Token::QuoteLike::Backtick>

qx{} - L<PPI::Token::QuoteLike::Command>

qr// - L<PPI::Token::QuoteLike::Regexp>

<FOO> - L<PPI::Token::QuoteLike::Readline>

The names are hopefully obvious enough not to have to explain what
each class is. See their pages for more details.

You may note that the backtick and command quote-like are treated
separately, even though they do the same thing. This is intentional,
as the inherit from and are processed by two different parts of the
PPI's quote engine.

=cut

use strict;
use base 'PPI::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.114';
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
