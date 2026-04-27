package PPI::Token::Preamble;

=pod

=head1 NAME

PPI::Token::Preamble - Non-Perl content before the shebang line in perl -x mode

=head1 INHERITANCE

  PPI::Token::Preamble
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

When parsing with C<perl_x> enabled (emulating the C<perl -x> command line
option), any text before the first C<#!...perl> shebang line is collected
into a single C<PPI::Token::Preamble> token. This content is not Perl code
and is treated as non-significant, similar to L<PPI::Token::End>.

The preamble is preserved in the PDOM tree so that the document remains
fully round-trip safe.

=head1 METHODS

This class has no methods beyond those provided by its L<PPI::Token> and
L<PPI::Element> parent classes.

=cut

use strict;
use PPI::Token ();

our $VERSION = '1.292';

our @ISA = "PPI::Token";

sub significant() { '' }

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 COPYRIGHT

Copyright 2001 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
