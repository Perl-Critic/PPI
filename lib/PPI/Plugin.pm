package PPI::Plugin;

=pod

=head1 NAME

PPI::Plugin - Base class for PPI parsing plugins

=head1 SYNOPSIS

  # Create a plugin that recognizes 'method' as starting an expression
  package My::Plugin;
  use parent 'PPI::Plugin';

  sub statement_class {
      my ($self, $token, $parent) = @_;
      return 'PPI::Statement::Expression'
        if $token->isa('PPI::Token::Word')
        and $token->content eq 'method';
      return;
  }

  # Use it
  my $doc = PPI::Document->new(\$source, plugins => [My::Plugin->new]);

=head1 DESCRIPTION

C<PPI::Plugin> provides an interface for extending PPI's parsing behavior
without modifying PPI's internals. Plugins can hook into the lexer and
tokenizer at well-defined points to influence how Perl source code is
parsed into a PDOM tree.

Plugins are passed to L<PPI::Document/new> via the C<plugins> parameter
and are propagated through the Lexer and Tokenizer during parsing.

=head1 METHODS

=head2 new

  my $plugin = PPI::Plugin->new(%params);

Creates a new plugin object. The base class constructor accepts any
key/value pairs and stores them as object attributes. Subclasses may
override this to validate or process their parameters.

=cut

use strict;

our $VERSION = '1.292';

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	bless { @_ }, $class;
}

=pod

=head2 statement_class $token, $parent

  sub statement_class {
      my ($self, $token, $parent) = @_;
      return 'PPI::Statement::Sub' if ...;
      return;  # defer to default behavior
  }

Called by the Lexer when determining which C<PPI::Statement> subclass to
use for a new statement. Receives the first significant token and the
parent node. Return a statement class name to override the default, or
C<undef>/empty list to defer to PPI's normal classification.

=cut

sub statement_class { return }

=pod

=head2 modify_token $token

  sub modify_token {
      my ($self, $token) = @_;
      $token->{_my_flag} = 1 if $token->content eq 'method';
      return;
  }

Called by the Tokenizer after each token is finalized. Receives the
completed token object. Can modify the token in-place (e.g., set custom
attributes). The return value is ignored.

B<Note:> Plugins must not change the token's class or content in ways that
would break round-trip safety. Adding custom attributes (with a leading
underscore by convention) is the intended use.

=cut

sub modify_token { return }

=pod

=head2 feature_includes $include

  sub feature_includes {
      my ($self, $include) = @_;
      return { signatures => 1 }
        if $include->module eq 'My::Boilerplate';
      return;
  }

Called when the Lexer encounters a C<use> or C<no> statement. Receives
the L<PPI::Statement::Include> object. Return a hashref of features to
enable/disable for the current scope, or C<undef>/empty list to defer
to PPI's normal feature detection.

This hook is called before PPI's built-in feature detection, so plugins
get first chance to claim an include statement.

=cut

sub feature_includes { return }

1;

=pod

=head1 WRITING PLUGINS

Subclass C<PPI::Plugin> and override one or more hook methods. All hooks
have safe defaults (return nothing), so you only implement what you need.

Multiple plugins can be active simultaneously. They are called in order;
the first plugin to return a defined value wins for C<statement_class> and
C<feature_includes>. All plugins receive C<modify_token> calls regardless.

=head1 SEE ALSO

L<PPI::Document>, L<PPI::Lexer>, L<PPI::Tokenizer>

=cut
