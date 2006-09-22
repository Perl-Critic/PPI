package PPI::Statement::Scheduled;

=pod

=head1 NAME

PPI::Statement::Scheduled - A scheduled code block

=head1 INHERITANCE

  PPI::Statement::Scheduled
  isa PPI::Statement::Sub
      isa PPI::Statement
          isa PPI::Node
              isa PPI::Element

=head1 DESCRIPTION

A scheduled code block is one that is intended to be run at a specific
time during the loading process.

There are four types of scheduled block:

  BEGIN {
  	# Executes as soon as this block is fully defined
  	...
  }
  
  CHECK {
  	# Executes after compile-phase in reverse order
  	...
  }
  
  INIT {
  	# Executes just before run-time
  	...
  }
  
  END {
  	# Executes as late as possible in reverse order
  	...
  }

Technically these scheduled blocks are actually subroutines, and in fact
may have 'sub' in front of them.

=head1 METHODS

=cut

use strict;
use base 'PPI::Statement::Sub';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.118';
}

sub __LEXER__normal { '' }

=pod

=head2 type

The C<type> method returns the type of scheduled block, which should always be
one of C<'BEGIN'>, C<'CHECK'>, C<'INIT'> or C<'END'>.

=cut

sub type {
	my $self     = shift;
	my @children = $self->schildren or return undef;
	$children[0]->content eq 'sub'
		? $children[1]->content
		: $children[0]->content;
}

# This is actually the same as Sub->name
sub name {
	shift->type(@_);
}

1;

=pod

=head1 TO DO

- Write unit tests for this package

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
