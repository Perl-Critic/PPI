package PPI::Structure::Condition;

=pod

=head1 NAME

PPI::Structure::Condition - Round braces for boolean context conditions

=head1 SYNOPSIS

  if ( condition ) {
      ...
  }
  
  while ( condition ) {
      ...
  }

=head1 INHERITANCE

  PPI::Structure::Condition
  isa PPI::Structure
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Structure::Condition> is the class used for all round braces
that represent boolean contexts used in various conditions.

=head1 METHODS

C<PPI::Structure::Condition> has no methods beyond those provided by
the standard L<PPI::Structure>, L<PPI::Node> and L<PPI::Element> methods.

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
