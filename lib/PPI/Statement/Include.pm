package PPI::Statement::Include;

=pod

=head1 NAME

PPI::Statement::Include - Statements that include other code

=head1 SYNOPSIS

  # The following are all includes
  use 5.006;
  use strict;
  use My::Module;
  use constant FOO => 'Foo';
  require Foo::Bar;
  require "Foo/Bar.pm";
  require $foo if 1;
  no strict 'refs';

=head1 INHERITANCE

  PPI::Statement::Include
  isa PPI::Statement
      isa PPI::Node
          isa PPI::Element

=head1 DESCRIPTION

Despite its name, the C<PPI::Statement::Include> class covers a number
of different types of statement that cover all statements starting with
C<use>, C<no> and C<require>.

But basically, they cover three situations.

Firstly, a dependency on a particular version of perl (for which the
C<version> method returns true), a pragma (for which the C<pragma> method
returns true, or the loading (and unloading via no) of modules.

=head1 METHODS

C<PPI::Statement::Include> has a number of methods in addition to the standard
L<PPI::Statement>, L<PPI::Node> and L<PPI::Element> methods.

=cut

use strict;
use base 'PPI::Statement';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.112';
}

=pod

=head2 type

The C<type> method returns the general type of statement (C<'use'>, C<'no'>
or C<'require'>).

Returns the type as a string, or C<undef> if the type cannot be detected.

=cut

sub type {
	my $self    = shift;
	my $keyword = $self->schild(0) or return undef;
	$keyword->isa('PPI::Token::Word') and $keyword->content;
}

=pod

=head2 module

The C<module> method returns the module name specified in any include
statement. This C<includes> pragma names, because pragma are implemented
as modules. (And lets face it, the definition of a pragma can be fuzzy
at the best of times in any case)

This covers all of these...

  use strict;
  use My::Module;
  no strict;
  require My::Module;

...but does not cover any of these...

  use 5.006;
  require 5.005;
  require "explicit/file/name.pl";

Returns the module name as a string, or C<undef> if the include does
not specify a module name.

=cut

sub module {
	my $self = shift;
	my $module = $self->schild(1) or return undef;
	$module->isa('PPI::Token::Word') and $module->content;
}

=pod

=head2 pragma

The C<pragma> method checks for an include statement's use as a
pragma, and returns it if so.

Or at least, it claims to. In practice it's a lot harder to say exactly
what is or isn't a pragma, because the definition is fuzzy.

The C<intent> of a pragma is to modify the way in which the parser works.
This is done though the use of modules that do various types of internals
magic.

For now, PPI assumes that any "module name" that is only a set of
lowercase letters. This behaviour is expected to change, most likely to
something that knows the specific names of the various "pragmas".

Returns the name of the pragma, or false ('') if the include is not a
pragma.

=cut

sub pragma {
	my $self = shift;
	my $module = $self->module or return '';
	$module =~ /^[a-z]/ ? $module : '';
}

=pod

The C<version> method checks for an include statement that introduces a
dependency on the version of C<perl> the code is compatible with.

This covers two specific statements.

  use 5.006;
  require 5.006;

Currently the version is returned as a string, although in future the
version may be returned as a numeric literal, or more likely as a
L<version> object. Returns false if the statement is not a version
dependency.

=cut

sub version {
	my $self = shift;
	my $version = $self->schild(1) or return undef;
	$version->isa('PPI::Token::Number') ? $version->content : '';
}

1;

=pod

=head1 TO DO

- Write specific unit tests for this package

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2001 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
