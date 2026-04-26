package PPI::Token::Regexp::Substitute;

=pod

=head1 NAME

PPI::Token::Regexp::Substitute - A match and replace regular expression token

=head1 INHERITANCE

  PPI::Token::Regexp::Substitute
  isa PPI::Token::Regexp
      isa PPI::Token
          isa PPI::Element

=head1 SYNOPSIS

  $text =~ s/find/$replace/;

=head1 DESCRIPTION

A C<PPI::Token::Regexp::Substitute> object represents a single substitution
regular expression.

=head1 METHODS

There are no methods available for C<PPI::Token::Regexp::Substitute>
beyond those provided by the parent L<PPI::Token::Regexp>, L<PPI::Token>
and L<PPI::Element> classes.

=cut

use strict;
use PPI::Token::Regexp             ();
use PPI::Token::_QuoteEngine::Full ();

our $VERSION = '1.292';

our @ISA = qw{
	PPI::Token::_QuoteEngine::Full
	PPI::Token::Regexp
};

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=cut
