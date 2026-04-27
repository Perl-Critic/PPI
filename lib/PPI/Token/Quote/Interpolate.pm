package PPI::Token::Quote::Interpolate;

=pod

=head1 NAME

PPI::Token::Quote::Interpolate - The interpolation quote-like operator

=head1 INHERITANCE

  PPI::Token::Quote::Interpolate
  isa PPI::Token::Quote
      isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

A C<PPI::Token::Quote::Interpolate> object represents a single
interpolation quote-like operator, such as C<qq{$foo bar $baz}>.

=head1 METHODS

There are several methods available for C<PPI::Token::Quote::Interpolate>,
beyond those provided by the parent L<PPI::Token::Quote>, L<PPI::Token> and
L<PPI::Element> classes.

=cut

use strict;
use Params::Util                     qw{_INSTANCE};
use PPI::Token::Quote                ();
use PPI::Token::_QuoteEngine::Full   ();

our $VERSION = '1.292';

our @ISA = qw{
	PPI::Token::_QuoteEngine::Full
	PPI::Token::Quote
};





#####################################################################
# PPI::Token::Quote::Interpolate Methods

=pod

=head2 interpolations

The C<interpolations> method checks to see if the interpolation
quote-like operator actually contains any interpolated variables.

Returns true if the string contains interpolations, or false if not.

=cut

sub interpolations {
	!! ($_[0]->content =~ /(?<!\\)(?:\\\\)*[\$\@]/);
}

=pod

=head2 simplify

The C<simplify> method will, if possible, modify an interpolation
quote-like operator in place, turning it into the equivalent literal
quote-like operator. If the token is modified, it is reblessed into
the L<PPI::Token::Quote::Literal> package.

Because the content changes length (C<qq> becomes C<q>), you should
call the document's C<flush_locations> method if you need accurate
location data after simplification.

The object itself is returned as a convenience.

=cut

sub simplify {
	my $self = _INSTANCE(shift, 'PPI::Token::Quote::Interpolate') or return undef;

	my $value = $self->string;
	return $self if $value =~ /[\\\$\@]/;

	(my $content = $self->{content}) =~ s/\Aqq/q/ or return $self;
	$self->{content} = $content;

	$_->{position}-- for @{$self->{sections}};

	$self->{operator} = 'q';

	bless $self, 'PPI::Token::Quote::Literal';
}


#####################################################################
# PPI::Token::Quote Methods

sub string {
	my $self     = shift;
	my @sections = $self->_sections;
	my $str      = $sections[0];
	substr( $self->{content}, $str->{position}, $str->{size} );
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
