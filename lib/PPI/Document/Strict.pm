package PPI::Document::Strict;

=pod

=head1 NAME

PPI::Document::Strict - A strict-mode Perl Document that dies on broken syntax

=head1 SYNOPSIS

  use PPI::Document::Strict;

  # Dies if parsing fails or syntax is objectively broken
  my $doc = PPI::Document::Strict->new( 'Module.pm' );

  # All PPI::Document methods work normally
  my $subs = $doc->find('PPI::Statement::Sub');

=head1 INHERITANCE

  PPI::Document::Strict
  isa PPI::Document
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

C<PPI::Document::Strict> is a subclass of L<PPI::Document> that throws
exceptions instead of returning C<undef> or silently accepting broken code.

Where L<PPI::Document> is intentionally lenient — parsing even broken Perl
source and leaving indicators like L<PPI::Statement::UnmatchedBrace> or
incomplete L<PPI::Structure> nodes in the tree — C<PPI::Document::Strict>
treats these conditions as fatal errors.

Specifically, after a successful parse, the document is validated for:

=over 4

=item *

B<Parse failure> — if the underlying parser returns C<undef>, an exception
is thrown with the error message from L<PPI::Document/errstr>.

=item *

B<Unmatched braces> — the presence of any L<PPI::Statement::UnmatchedBrace>
node indicates a stray C<}>, C<]>, or C<)> and causes an exception.

=item *

B<Incomplete structures> — any L<PPI::Structure> missing its closing brace
indicates unclosed syntax and causes an exception.

=item *

B<Unknown remnants> — any L<PPI::Statement::Unknown>, L<PPI::Structure::Unknown>,
or L<PPI::Token::Unknown> nodes that survive the parse are considered parser
anomalies and cause an exception.

=back

This module is intended for downstream tooling that requires confidently
well-formed input — linters, refactoring tools, code generators, and similar
systems that cannot safely operate on ambiguous or broken parse trees.

=head1 METHODS

C<PPI::Document::Strict> inherits all methods from L<PPI::Document>. The
constructor is the only method with different behavior.

=cut

use strict;
use Params::Util  qw{_INSTANCE};
use PPI::Document ();
use PPI::Exception ();

our $VERSION = '1.292';

our @ISA = 'PPI::Document';

=pod

=head2 new

  my $doc = PPI::Document::Strict->new( $filename );
  my $doc = PPI::Document::Strict->new( \$source );
  my $doc = PPI::Document::Strict->new( \$source, readonly => 1 );

The C<new> constructor accepts the same arguments as L<PPI::Document/new>.
On success it returns a C<PPI::Document::Strict> object. On failure it
throws a L<PPI::Exception> rather than returning C<undef>.

After a successful parse, the document is inspected for structural problems.
If any are found, a L<PPI::Exception> is thrown describing the issue.

=cut

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);

	unless ( defined $self ) {
		my $msg = PPI::Document->errstr || 'Unknown error parsing Perl document';
		PPI::Document->_clear;
		PPI::Exception->throw( "PPI::Document::Strict: $msg" );
	}

	bless $self, $class
		unless _INSTANCE( $self, 'PPI::Document::Strict' );

	$self->_validate;

	return $self;
}

sub _validate {
	my $self = shift;

	my $unmatched = $self->find('PPI::Statement::UnmatchedBrace');
	if ( $unmatched and @$unmatched ) {
		PPI::Exception->throw(
			"PPI::Document::Strict: document contains "
			. scalar(@$unmatched)
			. " PPI::Statement::UnmatchedBrace element(s)"
		);
	}

	my $incomplete = $self->find( sub {
		$_[1]->isa('PPI::Structure') and !$_[1]->complete
	} );
	if ( $incomplete and @$incomplete ) {
		PPI::Exception->throw(
			"PPI::Document::Strict: document contains "
			. scalar(@$incomplete)
			. " incomplete structure(s)"
		);
	}

	my $unknown_stmts = $self->find('PPI::Statement::Unknown');
	if ( $unknown_stmts and @$unknown_stmts ) {
		PPI::Exception->throw(
			"PPI::Document::Strict: document contains "
			. scalar(@$unknown_stmts)
			. " PPI::Statement::Unknown element(s)"
		);
	}

	my $unknown_structs = $self->find('PPI::Structure::Unknown');
	if ( $unknown_structs and @$unknown_structs ) {
		PPI::Exception->throw(
			"PPI::Document::Strict: document contains "
			. scalar(@$unknown_structs)
			. " PPI::Structure::Unknown element(s)"
		);
	}

	my $unknown_tokens = $self->find('PPI::Token::Unknown');
	if ( $unknown_tokens and @$unknown_tokens ) {
		PPI::Exception->throw(
			"PPI::Document::Strict: document contains "
			. scalar(@$unknown_tokens)
			. " PPI::Token::Unknown element(s)"
		);
	}

	return 1;
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
