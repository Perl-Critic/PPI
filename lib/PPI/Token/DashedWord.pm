package PPI::Token::DashedWord;

=pod

=head1 NAME

PPI::Token::DashedWord - A dashed bareword token

=head1 INHERITANCE

  PPI::Token::DashedWord
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

The "dashed bareword" token represents literal values like C<-foo>.

=head1 METHODS

There are no additional methods beyond those provided by the parent
L<PPI::Token> and L<PPI::Element> classes.

Got any ideas for methods? Submit a report to rt.cpan.org!

=cut

use strict;
use base 'PPI::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.199_03';
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $t = $_[1];

	# Suck to the end of the dashed bareword
	my $line = substr( $t->{line}, $t->{line_cursor} );
	if ( $line =~ /^(\w+)/ ) {
		$t->{token}->{content} .= $1;
		$t->{line_cursor} += length $1;
	}

	# Are we a file test operator?
	if ( $t->{token}->{content} =~ /^\-[rwxoRWXOezsfdlpSbctugkTBMAC]$/ ) {
		# File test operator
		$t->{class} = $t->{token}->set_class( 'Operator' );
	} else {
		# No, normal dashed bareword
		$t->{class} = $t->{token}->set_class( 'Word' );
	}

	$t->_finalize_token->__TOKENIZER__on_char( $t );
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
