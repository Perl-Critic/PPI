package PPI::Structure::Signature;

=pod

=head1 NAME

PPI::Structure::Signature - List of subroutine signature elements

=head1 SYNOPSIS

  sub do_thing( $param, $arg ) {}

=head1 INHERITANCE

  PPI::Structure::Signature
    isa PPI::Structure::List
        isa PPI::Structure
            isa PPI::Node
                isa PPI::Element

=head1 DESCRIPTION

C<PPI::Structure::Signature> is the class used for circular braces that
represent lists of signature elements.

=head1 METHODS

C<PPI::Structure::Signature> has no methods beyond those provided by the
standard L<PPI::Structure::List>, L<PPI::Structure>, L<PPI::Node> and
L<PPI::Element> methods.

=cut

use strict;
use PPI::Structure ();

our $VERSION = '1.292';

our @ISA = "PPI::Structure::List";

1;

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=cut
