package PPI::Structure::Subscript;

=pod

=head1 NAME

PPI::Structure::Subscript - Braces that represent an array or hash subscript

=head1 SYNOPSIS

  # The end braces for all of the following are subscripts
  $foo->[...]
  $foo[...]
  $foo{...}[...]
  $foo->{...}
  $foo{...}
  $foo[]{...}

=head1 INHERITANCE

  PPI::Structure::Subscript
  isa PPI::Structure
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Structure::Subscript> is the class used for square and curly
braces that specify one element of an array or hash (or a slice/subset
of an array or hash)

=head1 METHODS

C<PPI::Structure::Subscript> has no methods beyond those provided by the
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
