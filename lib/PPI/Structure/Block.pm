package PPI::Structure::Block;

=pod

=head1 NAME

PPI::Structure::Block - Curly braces representing a code block

=head1 SYNOPSIS

  sub foo { ... }
  
  grep { ... } @list;
  
  if ( condition ) {
      ...
  }
  
  LABEL: {
      ...
  }

=head1 INHERITANCE

  PPI::Structure::Block
  isa PPI::Structure
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Structure::Block> is the class used for all curly braces that
represent code blocks. This includes subroutines, compound statements
and any other block braces.

=head1 METHODS

C<PPI::Structure::Block> has no methods beyond those provided by the
standard L<PPI::Structure>, L<PPI::Node> and L<PPI::Element> methods.

=cut

use strict;
use PPI::Structure ();

our $VERSION = '1.292';

our @ISA = "PPI::Structure";





#####################################################################
# PPI::Element Methods

# This is a scope boundary
sub scope() { 1 }

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=cut
