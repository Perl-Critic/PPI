package PPI::Token::Operator;

=pod

=head1 NAME

PPI::Token::Operator - Token class for operators

=head1 INHERITANCE

  PPI::Token::Operator
  isa PPI::Token
      isa PPI::Element

=head1 SYNOPSIS

  # This is the list of valid operators
  ++   --   **   !    ~    +    -
  =~   !~   *    /    %    x
  <<   >>   lt   gt   le   ge   cmp  ~~
  ==   !=   <=>  .    ..   ...  ,
  &    |    ^    &&   ||   //
  ?    :    **=  +=   -=   .=   *=   /=
  %=   x=   &=   |=   ^=   <<=  >>=  &&=
  ||=  //=  <    >    <=   >=   <>   =>   ->
  and  or   xor  not  eq   ne   <<>>


=head1 DESCRIPTION

All operators in PPI are created as C<PPI::Token::Operator> objects,
including the ones that may superficially look like a L<PPI::Token::Word>
object.

=head1 METHODS

There are no additional methods beyond those provided by the parent
L<PPI::Token> and L<PPI::Element> classes.

=cut

use strict;
use PPI::Token ();
use PPI::Singletons '%OPERATOR';

our $VERSION = '1.292';

our @ISA = "PPI::Token";





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_char {
	my $t    = $_[1];
	my $char = substr( $t->{line}, $t->{line_cursor}, 1 );

	# Are we still an operator if we add the next character
	my $content = $t->{token}->{content};
	# special case for <<>> operator
	if(length($content) < 4 &&
		$content . substr( $t->{line}, $t->{line_cursor}, 4 - length($content) ) eq '<<>>') {
		return 1;
	}
	# Where a term is expected, ~~ is two bitwise complements (~~$y), not
	# the smart match.  Only a known operand position counts (or the start
	# of the document): after a match or a method name _opcontext cannot
	# say, and those take ~~.
	if ( $content eq '~' and $char eq '~'
		and ( $t->_opcontext eq 'operand' or !$t->_last_significant_token )
	) {
		return $t->_finalize_token->__TOKENIZER__on_char( $t );
	}
	return 1 if $OPERATOR{ $content . $char };

	# Handle the special case of a .1234 decimal number
	if ( $content eq '.' ) {
		# .5 is a number only in TERM position; after a term ($x.2) it is
		# the concatenation operator
		if ( $char =~ /^[0-9]$/ and $t->_opcontext ne 'operator' ) {
			# This is a decimal number
			$t->{class} = $t->{token}->set_class('Number::Float');
			return $t->{class}->__TOKENIZER__on_char( $t );
		}
	}

	# Handle the special case if we might be a here-doc
	if ( $content eq '<<' ) {
		pos $t->{line} = $t->{line_cursor};
		# Either <<FOO  or << 'FOO'  or <<\FOO  or
		#        <<~FOO or <<~ 'FOO' or <<~\FOO
		### Is the zero-width look-ahead assertion really
		### supposed to be there?
		if ( $t->{line} =~ m/\G ~? (?: (?!\d)\w | \s*['"`] | \\\w ) /gcx ) {
			# This is a here-doc.
			# Change the class and move to the HereDoc's own __TOKENIZER__on_char method.
			$t->{class} = $t->{token}->set_class('HereDoc');
			return $t->{class}->__TOKENIZER__on_char( $t );
		}
	}

	# Handle the special case of the null Readline
	$t->{class} = $t->{token}->set_class('QuoteLike::Readline')
		if $content eq '<>' or $content eq '<<>>';

	# Finalize normally
	$t->_finalize_token->__TOKENIZER__on_char( $t );
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
