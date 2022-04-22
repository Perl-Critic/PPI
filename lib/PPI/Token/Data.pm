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
a file's C<__DATA__> section.

One C<PPI::Token::Data> object is used to represent the entire of the data,
primarily so that it can provide a convenient handle directly to the data.

=head1 METHODS

C<PPI::Token::Data> provides one method in addition to those provided by
our parent L<PPI::Token> and L<PPI::Element> classes.

=cut

use strict;
use PPI::Token ();

# IO::String emulates file handles using in memory strings. Perl can do this
# directly on perl 5.8+
use constant USE_IO_STRING => $] < '5.008000';
use if USE_IO_STRING, 'IO::String';
# code may expect methods to be available on all file handles, so make sure
# IO is loaded
use if !USE_IO_STRING, 'IO::File';

our $VERSION = '1.274';

our @ISA = "PPI::Token";





#####################################################################
# Methods

=pod

=head2 handle

The C<handle> method returns a L<IO::String> handle that allows you
to do all the normal handle-y things to the contents of the __DATA__
section of the file.

Unlike in perl itself, this means you can also do things like C<print>
new data onto the end of the __DATA__ section, or modify it with
any other process that can accept an L<IO::Handle> as input or output.

Returns an L<IO::String> object.

=cut

sub handle {
	my $self = shift;
	# perl 5.6 compatibility
	if (USE_IO_STRING) {
		return IO::String->new( \$self->{content} );
	}
	else {
		open my $fh, '+<', \$self->{content};
		return $fh;
	}
}

sub __TOKENIZER__on_line_start {
	my ( $self, $t ) = @_;

	# Add the line
	if ( defined $t->{token} ) {
		$t->{token}->{content} .= $t->{line};
	}
	else {
		defined( $t->{token} = $t->{class}->new( $t->{line} ) ) or return undef;
	}

	return 0;
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
