package PPI::Token::QuoteLike::Command;

=pod

=head1 NAME

PPI::Token::QuoteLike::Command - The command quote-like operator

=head1 INHERITANCE

  PPI::Token::QuoteLike::Command
  isa PPI::Token::QuoteLike
      isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

A C<PPI::Token::QuoteLike::Command> object represents a command output
capturing quote-like operator.

=head1 METHODS

The following methods are provided by this class,
beyond those provided by the parent L<PPI::Token::QuoteLike>,
L<PPI::Token> and L<PPI::Element> classes.

=cut

use strict;
use PPI::Token::QuoteLike          ();
use PPI::Token::_QuoteEngine::Full ();

our $VERSION = '1.292';

our @ISA = qw{
	PPI::Token::_QuoteEngine::Full
	PPI::Token::QuoteLike
};

=pod

=head2 get_delimiters

The C<get_delimiters> method returns the delimiters of the command string as an
array. The first and only element is the delimiters of the command string
content.

=cut

sub get_delimiters {
	return $_[0]->_delimiters();
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
