package PPI::Token::Data;

=pod

=head1 NAME

PPI::Token::Data - The actual data in the __DATA__ section of a file

=head1 INHERITANCE

  PPI::Token::Data
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

The C<PPI::Token::Data> class is used to represent the actual data inside
of a file's __DATA__ section.

One C<PPI::Token::Data> object is used to represent the entire of the data,
primarily so that it can provide a convenient handle directly to the data.

=head1 METHODS

C<PPI::Token::Data> provides one method in addition to those provided by
our parent L<PPI::Token> and L<PPI::Element> classes.

=cut

use strict;
use base 'PPI::Token';
use IO::Scalar ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.110';
}





#####################################################################
# Methods

=pod

=head2 handle

The C<handle> method returns a L<IO::Scalar> handle that allows you
to do all the normal handle'y things to the contents of the __DATA__
section of the file.

Unlike in perl itself, this means you can also do things like C<print>
new data onto the end of the __DATA__ section, or modify it with
any other process that can accept an L<IO::Handle> as input or output.

Returns an L<IO::Scalar> object

=cut

sub handle {
	my $self = shift;
	IO::Scalar->new( \$self->{content} );
}

sub __TOKENIZER__on_char { 1 }

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2001 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
