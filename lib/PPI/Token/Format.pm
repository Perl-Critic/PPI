package PPI::Token::Format;

=pod

=head1 NAME

PPI::Token::Format - A format for the write function

=head1 INHERITANCE

  PPI::Token::Pod
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

A single C<PPI::Token::Format> object represents a single format section

=head1 METHODS

This class provides no additional methods beyond those provided by its
L<PPI::Token> and L<PPI::Element> parent classes.

=cut

use strict;
use Params::Util qw{_INSTANCE};
use PPI::Token   ();

# VERSION

our @ISA = "PPI::Token";

#####################################################################
# PPI::Element Methods

### XS -> PPI/XS.xs:_PPI_Token_Pod__significant 0.900+
sub significant() { 1 }





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_line_start {
	my $t = $_[1];

	# Add the line to the token first
	$t->{token}->{content} .= $t->{line};

	# Check the line to see if it is a =cut line
	if ( $t->{line} =~ /^\.$/  ) {
		# End of the token
		$t->_finalize_token;
	}

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
