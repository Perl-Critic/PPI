package PPI::Structure::Given;

=pod

=head1 NAME

PPI::Structure::Given - Circular braces for a switch statement

=head1 SYNOPSIS

  given ( something ) {
      ...
  }

=head1 INHERITANCE

  PPI::Structure::Given
  isa PPI::Structure
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Structure::Given> is the class used for circular braces that
contain the thing to be matched in a switch statement.

=head1 METHODS

C<PPI::Structure::Given> has no methods beyond those provided by the
standard L<PPI::Structure>, L<PPI::Node> and L<PPI::Element> methods.

=cut

use strict;
use PPI::Structure ();

our $VERSION = '1.292';

our @ISA = "PPI::Structure";

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=cut
