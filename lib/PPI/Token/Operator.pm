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
	return 1 if $OPERATOR{ $content . $char };

	# Handle the special case of a .1234 decimal number,
	# but only when not preceded by a value-producing token
	if ( $content eq '.' ) {
		if ( $char =~ /^[0-9]$/ ) {
			my $prev = $t->_last_significant_token;
			if ( !$prev or !_dot_is_concat_after($prev) ) {
				$t->{class} = $t->{token}->set_class('Number::Float');
				return $t->{class}->__TOKENIZER__on_char( $t );
			}
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

my %_PRODUCES_VALUE = map { $_ => 1 }
	'PPI::Token::Symbol',
	'PPI::Token::Magic',
	'PPI::Token::Number',
	'PPI::Token::Number::Binary',
	'PPI::Token::Number::Octal',
	'PPI::Token::Number::Hex',
	'PPI::Token::Number::Float',
	'PPI::Token::Number::Exp',
	'PPI::Token::Number::Version',
	'PPI::Token::ArrayIndex',
	'PPI::Token::Quote::Double',
	'PPI::Token::Quote::Interpolate',
	'PPI::Token::Quote::Literal',
	'PPI::Token::Quote::Single',
	'PPI::Token::QuoteLike::Backtick',
	'PPI::Token::QuoteLike::Command',
	'PPI::Token::QuoteLike::Readline',
	'PPI::Token::QuoteLike::Regexp',
	'PPI::Token::QuoteLike::Words',
	'PPI::Token::HereDoc',
;

sub _dot_is_concat_after {
	my $prev = shift;
	return 1 if $_PRODUCES_VALUE{ ref $prev };
	return 1 if $prev->isa('PPI::Token::Structure')
		and ( $prev->content eq ')' or $prev->content eq ']' or $prev->content eq '}' );
	return '';
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
