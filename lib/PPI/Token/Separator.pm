package PPI::Token::Separator;

=pod

=head1 NAME

PPI::Token::Separator - The __DATA__ and __END__ tags

=head1 INHERITANCE

  PPI::Token::Separator
  isa PPI::Token::Word
      isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

Although superficially looking like a normal L<PPI::Token::Word> object,
when the C<__DATA__> and C<__END__> compiler tags appear at the beginning of
a line (on supposedly) their own line, these tags become file section
separators.

The indicate that the time for Perl code is over, and the rest of the
file is dedicated to something else (data in the case of C<__DATA__>) or
to nothing at all (in the case of C<__END__>).

=head1 METHODS

This class has no methods beyond what is provided by its
L<PPI::Token::Word>, L<PPI::Token> and L<PPI::Element>
parent classes.

=cut

use strict;
use PPI::Token::Word ();

our $VERSION = '1.292';

our @ISA = "PPI::Token::Word";

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=cut
