package PPI::Structure::List;

=pod

=head1 NAME

PPI::Structure::List - Explicit list or precedence ordering braces

=head1 SYNOPSIS

  # A list used for params
  function( 'param', 'param' );
  
  # Explicit list
  return ( 'foo', 'bar' );

=head1 INHERITANCE

  PPI::Structure::List
  isa PPI::Structure
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Structure::List> is the class used for circular braces that
represent lists, and related.

=head1 METHODS

C<PPI::Structure::List> has no methods beyond those provided by the
standard L<PPI::Structure>, L<PPI::Node> and L<PPI::Element> methods.

Got any ideas for methods? Submit a report to rt.cpan.org!

=cut

use strict;
use base 'PPI::Structure';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.202_01';
}

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
