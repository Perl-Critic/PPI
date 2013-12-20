package PPI::DeadCode;

=pod

=head1 NAME

PPI::DeadCode - code believed to be dead

=head1 DESCRIPTION

In the history of PPI certain code sections have evolved such that they dropped
out of being covered by tests and attempts to add tests to cover them failed.
They are believed to be dead, but this cannot be said with absolute certainty.
Thus, the conditions that leave to the dead code are kept in stasis in this
module, from where they can be called from their former places of residence.
The functionality they once had, is however replaced with an exception,
explaining that a piece of code believed to be dead was found and should be
resurrected by way of contacting the maintainers of PPI.

=cut

use strict;
use PPI::Exception ();

use vars qw{$VERSION @ISA};

BEGIN {
	$VERSION = '1.215';
}

sub throw_undead {
	my $id = ( split /::/, ( caller( 1 ) )[3] )[-1];
	PPI::Exception->throw( "Code presumed to be dead called under method '$id'. "
		  . "Please inform the PPI maintainers along with sample "
		  . "of the source parsed to generate this exception." );
}

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
