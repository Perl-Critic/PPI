package PPI::Token::End;

=pod

=head1 NAME

PPI::Token::End - Completely useless content after the __END__ tag

=head1 INHERITANCE

  PPI::Token::End
  isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

If you've read L<PPI::Token::Whitespace>, you should understand by now
the concept of documents "floating in a sea of PPI::Token::Whitespace".

Well not after the __END__ tag it doesn't.

Once you __END__ it's all over. Anything after that tag isn't even fit
to be called whitespace. It just simply doesn't exist as far as perl
(the interpreter) is concerned.

That's not to say there isn't useful content. Most often people use
the __END__ tag to hide POD content, so that perl never has to see it,
and presumably providing some small speed up.

That's fine. PPI likes POD. Any POD after the __END__ tag is parsed
into valid L<PPI::Token::Pod> tags as normal. B<This> class, on the
other hand, is for "what's after __END__ when it isn't POD". 

Basically, the completely worthless bits of the file :)

=head1 METHODS

This class has no method beyond what is provided by it's L<PPI::Token> and
L<PPI::Element> parent classes.

=cut

use strict;
use base 'PPI::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.114';
}





#####################################################################
# Tokenizer Methods

### XS -> PPI/XS.xs:_PPI_Token_End__significant 0.900+
sub significant { '' }

sub __TOKENIZER__on_char { 1 }

sub __TOKENIZER__on_line_start {
	my $t = $_[1];

	# Can we classify the entire line in one go
	$_ = $t->{line};
	if ( /^=(\w+)/ ) {
		# A Pod tag... change to pod mode
		$t->_new_token( 'Pod', $_ ) or return undef;
		unless ( $1 eq 'cut' ) {
			# Normal start to pod
			$t->{class} = 'PPI::Token::Pod';
		}

		# This is an error, but one we'll ignore
		# Don't go into Pod mode, since =cut normally
		# signals the end of Pod mode
	} else {
		if ( defined $t->{token} ) {
			# Add to existing token
			$t->{token}->{content} .= $t->{line};
		} else {
			$t->_new_token( 'End', $t->{line} );
		}
	}

	0;
}

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
