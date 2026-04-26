package PPI::Structure::Constructor;

=pod

=head1 NAME

PPI::Structure::Constructor - Anonymous hash or array constructor

=head1 SYNOPSIS

  my $array = [ 'foo', 'bar' ];
  my $hash  = { foo => 'bar' };

=head1 INHERITANCE

  PPI::Structure::Constructor
  isa PPI::Structure
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Structure::Constructor> is the class used for anonymous C<ARRAY>
reference of C<HASH> reference constructors.

=head1 METHODS

C<PPI::Structure::Constructor> has no methods beyond those provided by
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
