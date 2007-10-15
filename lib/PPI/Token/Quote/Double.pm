package PPI::Token::Quote::Double;

=pod

=head1 NAME

PPI::Token::Quote::Double - A standard "double quote" token

=head1 INHERITANCE

  PPI::Token::Quote::Double
  isa PPI::Token::Quote
      isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

A C<PPI::Token::Quote::Double> object represents a double-quoted
interpolating string.

The string is treated as a single entity, L<PPI> will not try to
understand what is in the string during the parsing process.

=head1 METHODS

There are several methods available for C<PPI::Token::Quote::Double>, beyond
those provided by the parent L<PPI::Token::Quote>, L<PPI::Token> and
L<PPI::Element> classes.

Got any ideas for methods? Submit a report to rt.cpan.org!

=cut

use strict;
use base 'PPI::Token::_QuoteEngine::Simple',
         'PPI::Token::Quote';
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.200';
}





#####################################################################
# PPI::Token::Quote::Double Methods

=pod

=head2 interpolations

The interpolations method checks to see if the double quote actually
contains any interpolated variables.

Returns true if the string contains interpolations, or false if not.

=begin testing interpolations 8

# Get a set of objects
my $Document = PPI::Document->new(\<<'END_PERL');
"no interpolations"
"no \@interpolations"
"has $interpolation"
"has @interpolation"
"has \\@interpolation"
"" # False content to test double-negation scoping
END_PERL
isa_ok( $Document, 'PPI::Document' );
my $strings = $Document->find('Token::Quote::Double');
is( scalar(@$strings), 6, 'Found the 5 test strings' );
is( $strings->[0]->interpolations, '', 'String 1: No interpolations'  );
is( $strings->[1]->interpolations, '', 'String 2: No interpolations'  );
is( $strings->[2]->interpolations, 1,  'String 3: Has interpolations' );
is( $strings->[3]->interpolations, 1,  'String 4: Has interpolations' );
is( $strings->[4]->interpolations, 1,  'String 5: Has interpolations' );
is( $strings->[5]->interpolations, '', 'String 6: No interpolations'  );

=end testing

=cut

# Upgrade: Return the interpolated substrings.
# Upgrade: Returns parsed expressions.
sub interpolations {
	my $self = shift;

	# Are there any unescaped $things in the string
	!! ($self->content =~ /(?<!\\)(?:\\\\)*[\$\@]/);
}

=pod

=head2 simplify

For various reasons, some people find themselves compelled to have
their code in the simplest form possible.

The C<simply> method will turn a simple double-quoted string into the
equivalent single-quoted string.

If the double can be simplified, it will be modified in place and
returned as a convenience, or returns false if the string cannot be
simplified.  

=cut

sub simplify {
	# This only works on EXACTLY this class
	my $self = _INSTANCE(shift, 'PPI::Token::Quote::Double') or return undef;

	# Don't bother if there are characters that could complicate things
	my $content = $self->content;
	my $value   = substr($content, 1, length($content) - 1);
	return '' if $value =~ /[\\\$\'\"]/;

	# Change the token to a single string
	$self->{content} = '"' . $value . '"';
	bless $self, 'PPI::Token::Quote::Single';
}







#####################################################################
# PPI::Token::Quote Methods

=pod

=begin testing string 3

my $Document = PPI::Document->new( \'print "foo";' );
isa_ok( $Document, 'PPI::Document' );
my $Double = $Document->find_first('Token::Quote::Double');
isa_ok( $Double, 'PPI::Token::Quote::Double' );
is( $Double->string, 'foo', '->string returns as expected' );

=end testing

=cut

sub string {
	my $str = $_[0]->{content};
	substr( $str, 1, length($str) - 2 );
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
