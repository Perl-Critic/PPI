package PPI::Token::Format;

=pod

=head1 NAME

PPI::Token::Format - The body of a format declaration

=head1 INHERITANCE

  PPI::Token::Format
  isa PPI::Token
      isa PPI::Element

=head1 SYNOPSIS

  format STDOUT =
  @<<<<<<<<<< @>>>>>
  $name,      $value
  .

=head1 DESCRIPTION

perl reads the lines after the C<=> of a C<format NAME => declaration as
picture and argument lines, never as code, up to and including the line
that holds a lone C<.> (L<perlform>; toke.c C<scan_formline>).  A single
C<PPI::Token::Format> object holds those lines, terminator included, so
the declaration ends with it and what follows the C<.> is lexed as the
next statement.

=head1 METHODS

This class provides one method beyond those provided by its
L<PPI::Token> and L<PPI::Element> parent classes.

=cut

use strict;
use PPI::Token ();

our $VERSION = '1.292';

our @ISA = "PPI::Token";

=pod

=head2 lines

The C<lines> method returns the picture and argument lines of the format,
without the terminating C<.> line, each without its newline.

=cut

sub lines {
	my @lines = split /\n/, $_[0]->{content}, -1;
	pop @lines if @lines and $lines[-1] eq '';
	pop @lines if @lines and $lines[-1] =~ /^\.\s*$/;
	return @lines;
}





#####################################################################
# Tokenizer Methods

# A format body is line oriented: every line joins the token, and the line
# holding a lone . ends it.
sub __TOKENIZER__on_line_start {
	my $t = $_[1];

	$t->{token}->{content} .= $t->{line};
	$t->_finalize_token if $t->{line} =~ /^\.\s*$/;

	0;
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
