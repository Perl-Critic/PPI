package PPI::Token::Ellipsis;

=pod

=head1 NAME

PPI::Token::Ellipsis - The Perl 5.12+ ellipsis statement token

=head1 INHERITANCE

  PPI::Token::Ellipsis
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

C<PPI::Token::Ellipsis> represents the C<...> (yada yada) statement
introduced in Perl 5.12. When executed, it throws an
C<"Unimplemented"> exception.

Although C<...> looks superficially like an operator, it is really
a statement unto itself and does not operate on any values.

=head1 METHODS

There are no additional methods beyond those provided by the parent
L<PPI::Token> and L<PPI::Element> classes.

=cut

use strict;
use PPI::Token ();

our $VERSION = '1.292';

our @ISA = "PPI::Token";

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
