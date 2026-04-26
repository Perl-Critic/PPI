package PPI::Statement::Unknown;

=pod

=head1 NAME

PPI::Statement::Unknown - An unknown or transient statement

=head1 INHERITANCE

  PPI::Statement::Unknown
  isa PPI::Statement
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

The C<PPI::Statement::Unknown> class is used primarily during the lexing
process to hold elements that are known to be statement, but for which
the exact C<type> of statement is as yet unknown, and requires further
tokens in order to resolve the correct type.

They should not exist in a fully parse B<valid> document, and if any
exists they indicate either a problem in Document, or possibly (by
allowing it to get through unresolved) a bug in L<PPI::Lexer>.

=head1 METHODS

C<PPI::Statement::Unknown> has no additional methods beyond the
default ones provided by L<PPI::Statement>, L<PPI::Node> and
L<PPI::Element>.

=cut

use strict;
use PPI::Statement ();

our $VERSION = '1.292';

our @ISA = "PPI::Statement";

# If one of these ends up in the final document,
# we're pretty much screwed. Just call it a day.
sub _complete () { 1 }

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=cut
