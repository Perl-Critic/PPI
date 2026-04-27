#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 12 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI ();
use PPI::Dumper;

our $TODO;
my $todo_msg = "Plugin system not yet implemented";

PLUGIN_BASE_CLASS: {
	local $TODO = $todo_msg;
	require_ok('PPI::Plugin');
	my $plugin = eval { PPI::Plugin->new };
	isa_ok( $plugin, 'PPI::Plugin' );
	can_ok( 'PPI::Plugin', 'statement_class', 'modify_token', 'feature_includes' );
}

PLUGIN_PASSED_TO_DOCUMENT: {
	local $TODO = $todo_msg;
	my $plugin = eval { PPI::Plugin->new } || bless {}, 'PPI::Plugin';
	my $doc = PPI::Document->new( \"my \$x = 1;", plugins => [$plugin] );
	ok( $doc, "Document created with plugins attribute" );
	my $plugins = eval { $doc->plugins };
	is( ref $plugins, 'ARRAY', "plugins accessor returns arrayref" );
	is( $plugins ? scalar @$plugins : 0, 1, "plugins list has one entry" );
}

STATEMENT_CLASS_HOOK: {
	local $TODO = $todo_msg;

	{
		package TestPlugin::StatementClass;
		our @ISA;
		BEGIN { @ISA = eval { require PPI::Plugin; 1 } ? ('PPI::Plugin') : () }
		sub new { bless {}, shift }
		sub statement_class {
			my ( $self, $token, $parent ) = @_;
			return 'PPI::Statement::Expression'
			  if $token->isa('PPI::Token::Word')
			  and $token->content eq 'method';
			return;
		}
	}

	my $plugin = TestPlugin::StatementClass->new;
	my $doc = PPI::Document->new(
		\"method foo { 1 }",
		plugins => [$plugin],
	);
	ok( $doc, "Document parsed with statement_class plugin" );

	my $stmts = $doc ? $doc->find('PPI::Statement::Expression') : undef;
	ok( $stmts && @$stmts, "plugin's statement_class hook was invoked" );
}

MODIFY_TOKEN_HOOK: {
	local $TODO = $todo_msg;

	{
		package TestPlugin::ModifyToken;
		our @ISA;
		BEGIN { @ISA = eval { require PPI::Plugin; 1 } ? ('PPI::Plugin') : () }
		sub new { bless {}, shift }
		sub modify_token {
			my ( $self, $token ) = @_;
			if ( $token->isa('PPI::Token::Word')
				and $token->content eq 'method' )
			{
				$token->{_plugin_seen} = 1;
			}
			return;
		}
	}

	my $plugin = TestPlugin::ModifyToken->new;
	my $doc = PPI::Document->new(
		\"method foo { 1 }",
		plugins => [$plugin],
	);
	ok( $doc, "Document parsed with modify_token plugin" );

	my $words = $doc ? $doc->find('PPI::Token::Word') : undef;
	my ($method_word) = $words ? grep { $_->content eq 'method' } @$words : ();
	ok( $method_word && $method_word->{_plugin_seen},
		"plugin's modify_token hook was called" );
}

FEATURE_INCLUDES_HOOK: {
	local $TODO = $todo_msg;

	{
		package TestPlugin::FeatureIncludes;
		our @ISA;
		BEGIN { @ISA = eval { require PPI::Plugin; 1 } ? ('PPI::Plugin') : () }
		sub new { bless {}, shift }
		sub feature_includes {
			my ( $self, $include ) = @_;
			return { signatures => 1 }
			  if $include->module
			  and $include->module eq 'MyApp::Signatures';
			return;
		}
	}

	my $plugin = TestPlugin::FeatureIncludes->new;
	my $doc = PPI::Document->new(
		\"use MyApp::Signatures;\nsub foo(\$x) {}",
		plugins => [$plugin],
	);
	ok( $doc, "Document parsed with feature_includes plugin" );

	my $sigs = $doc ? $doc->find('PPI::Structure::Signature') : undef;
	ok( $sigs && @$sigs, "plugin's feature_includes hook enabled signatures" );
}
