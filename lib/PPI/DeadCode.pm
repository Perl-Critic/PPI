package PPI::DeadCode;

=pod

=head1 NAME

PPI::DeadCode - code believed to be dead

=head1 DESCRIPTION

In the history of PPI certain code sections have evolved such that they dropped
out of being covered by tests and attempts to add tests to cover them failed.
They are believed to be dead, but this cannot be said with absolute certainty.
Thus, the conditions that leave to the dead code are kept in stasis in this
module, from where they can be called from their former places of residence.
The functionality they once had, is however replaced with an exception,
explaining that a piece of code believed to be dead was found and should be
resurrected by way of contacting the maintainers of PPI.

=cut

use strict;
use PPI::Exception ();

use vars qw{$VERSION @ISA};

BEGIN {
	$VERSION = '1.215';
}

sub throw_undead {
	my $id = ( split /::/, ( caller( 1 ) )[3] )[-1];
	PPI::Exception->throw( "Code presumed to be dead called under method '$id'. "
		  . "Please inform the PPI maintainers along with sample "
		  . "of the source parsed to generate this exception." );
}

sub token_word_char_maybe_attribute {
	my ( undef, $tokens ) = @_;
	throw_undead if $tokens->[0]->{_attribute};
}

sub token_word_char_maybe_quotelike {
	my ( undef, $QUOTELIKE, $word, $class, $t, $tokens ) = @_;
	throw_undead if $QUOTELIKE->{$word} and !$class->__TOKENIZER__literal( $t, $word, $tokens );
}

sub token_word_char_operator_and_literal {
	my ( undef, $class, $t, $word, $tokens ) = @_;
	throw_undead if $class->__TOKENIZER__literal( $t, $word, $tokens );
}

sub token_word_char_maybe_label {
	my ( undef, $char ) = @_;
	throw_undead if $char eq ':';
}

sub token_word_char_maybe_magic_filehandle {
	my ( undef, $char, $word ) = @_;
	throw_undead if $char ne ':' and $word eq '_';
}

sub token_word_commit_bareword_starting_with_numbers {
	my ( undef, $word ) = @_;
	throw_undead if !$word;
}

sub token_word_commit_eof_after_attribute {
	my ( undef, $t ) = @_;
	throw_undead if $t->{line_cursor} >= $t->{line_length};
}

sub token_word_commit_eof_after_quotelike {
	my ( undef, $t ) = @_;
	throw_undead if $t->{line_cursor} >= $t->{line_length};
}

sub token_word_commit_eof_at_end_of_commit {
	my ( undef, $t ) = @_;
	throw_undead if $t->{line_cursor} >= $t->{line_length};
}

sub token_word_literal_without_preceding_tokens {
	my ( undef, $token ) = @_;
	throw_undead if !$token;
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
