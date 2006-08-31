package PPI::Structure::ForLoop;

=pod

=head1 NAME

PPI::Structure::ForLoop - Circular braces for a for expression

=head1 SYNOPSIS

  for ( var $i = 0; $i < $max; $i++ ) {
      ...
  }

=head1 INHERITANCE

  PPI::Structure::ForLoop
  isa PPI::Structure
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Structure::ForLoop> is the class used for circular braces that
contain the three part C<for> expression.

=head1 METHODS

C<PPI::Structure::ForLoop> has no methods beyond those provided by the
standard L<PPI::Structure>, L<PPI::Node> and L<PPI::Element> methods.

Got any ideas for methods? Submit a report to rt.cpan.org!

=cut

use strict;
use base 'PPI::Structure';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.116';
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
