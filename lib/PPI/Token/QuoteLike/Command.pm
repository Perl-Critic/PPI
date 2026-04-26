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

There are no methods available for C<PPI::Token::QuoteLike::Command>
beyond those provided by the parent L<PPI::Token::QuoteLike>, L<PPI::Token>
and L<PPI::Element> classes.

=cut

use strict;
use PPI::Token::QuoteLike          ();
use PPI::Token::_QuoteEngine::Full ();

our $VERSION = '1.292';

our @ISA = qw{
	PPI::Token::_QuoteEngine::Full
	PPI::Token::QuoteLike
};

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=cut
