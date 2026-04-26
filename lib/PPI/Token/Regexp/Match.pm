package PPI::Token::Regexp::Match;

=pod

=head1 NAME

PPI::Token::Regexp::Match - A standard pattern match regex

=head1 INHERITANCE

  PPI::Token::Regexp::Match
  isa PPI::Token::Regexp
      isa PPI::Token
          isa PPI::Element

=head1 SYNOPSIS

  $text =~ m/match regexp/;
  $text =~ /match regexp/;

=head1 DESCRIPTION

A C<PPI::Token::Regexp::Match> object represents a single match regular
expression. Just to be doubly clear, here are things that are and
B<aren't> considered a match regexp.

  # Is a match regexp
  /This is a match regexp/;
  m/Old McDonald had a farm/eieio;
  
  # These are NOT match regexp
  qr/This is a regexp quote-like operator/;
  s/This is a/replace regexp/;

=head1 METHODS

There are no methods available for C<PPI::Token::Regexp::Match> beyond
those provided by the parent L<PPI::Token::Regexp>, L<PPI::Token> and
L<PPI::Element> classes.

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
