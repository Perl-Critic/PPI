package PPI::Statement::Data;

=pod

=head1 NAME

PPI::Statement::Data - The __DATA__ section of a file

=head1 SYNOPSIS

  # Normal content
  
  __DATA__
  This: data
  is: part
  of: the
  PPI::Statement::Data: object

=head1 INHERITANCE

  PPI::Statement::Compound
  isa PPI::Statement
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Statement::Data> is a utility class designed to hold content in
the __DATA__ section of a file. It provides a single statement to hold
B<all> of the data.

=head1 METHODS

C<PPI::Statement::Data> has no additional methods beyond the default ones
provided by L<PPI::Statement>, L<PPI::Node> and L<PPI::Element>.

However, it is expected to gain methods for accessing the data directly,
(as a filehandle for example) just as you would access the data in the
Perl code itself.

=cut

use strict;
use PPI::Statement ();

our $VERSION = '1.292';

our @ISA = "PPI::Statement";

# Data is never complete
sub _complete () { '' }

1;

=pod

=head1 TO DO

- Add the methods to read in the data

- Add some proper unit testing

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=cut
