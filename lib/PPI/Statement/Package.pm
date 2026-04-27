package PPI::Statement::Package;

=pod

=head1 NAME

PPI::Statement::Package - A package statement

=head1 INHERITANCE

  PPI::Statement::Package
  isa PPI::Statement
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

Most L<PPI::Statement> subclasses are assigned based on the value of the
first token or word found in the statement. When PPI encounters a statement
starting with 'package', it converts it to a C<PPI::Statement::Package>
object.

When working with package statements, please remember that packages only
exist within their scope.

To determine the effective namespace at any point in the document, use
the L<PPI::Element/namespace> method on any element. It handles both
semicolon-form (C<package Foo;>) and block-form (C<package Foo { ... }>)
declarations, including scoped packages in nested blocks.

=head1 METHODS

C<PPI::Statement::Package> has a number of methods in addition to the standard
L<PPI::Statement>, L<PPI::Node> and L<PPI::Element> methods.

=cut

use strict;
use PPI::Statement ();

our $VERSION = '1.292';

our @ISA = "PPI::Statement";

# Lexer clues
sub __LEXER__normal() { '' }

=pod

=head2 namespace

Most package declarations are simple, and just look something like

  package Foo::Bar;

The C<namespace> method returns the name of the declared package, in the
above case 'Foo::Bar'. It returns this exactly as written and does not
attempt to clean up or resolve things like ::Foo to main::Foo.

If the package statement is done any different way, it returns false.

=cut

sub namespace {
	my $self = shift;
	my $namespace = $self->schild(1) or return '';
	$namespace->isa('PPI::Token::Word')
		? $namespace->content
		: '';
}

=pod

=head2 version

Some package declarations may include a version:

  package Foo::Bar 1.23;
  package Baz v1.23;

The C<version> method returns the stringified version as seen in the
document (if any), otherwise the empty string.

=cut

sub version {
	my $self = shift;
	my $version = $self->schild(2) or return '';
	$version->isa('PPI::Token::Structure')
		? ''
		: $version->content;
}

=pod

=head2 block

With its name and implementation shared with L<PPI::Statement::Sub>,
the C<block> method finds and returns the actual Structure object of the
code block for this package, if it uses the Perl 5.14+ block form
(e.g. C<package Foo { ... }>).

Returns false if this is a semicolon-form package declaration
(e.g. C<package Foo;>).

=cut

sub block {
	my $self = shift;
	my $lastchild = $self->schild(-1) or return '';
	$lastchild->isa('PPI::Structure::Block') and $lastchild;
}

=pod

=head2 file_scoped

Regardless of whether it is named or not, the C<file_scoped> method will
test to see if the package declaration is a top level "file scoped"
statement or not, based on its location.

In general, returns true if it is a "file scoped" package declaration with
an immediate parent of the top level Document, or false if not.

Note that if the PPI DOM tree B<does not> have a PPI::Document object at
as the root element, this will return false. Likewise, it will also return
false if the root element is a L<PPI::Document::Fragment>, as a fragment of
a file does not represent a scope.

=cut

sub file_scoped {
	my $self     = shift;
	my ($Parent, $Document) = ($self->parent, $self->top);
	$Parent and $Document and $Parent == $Document
	and $Document->isa('PPI::Document')
	and ! $Document->isa('PPI::Document::Fragment');
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
