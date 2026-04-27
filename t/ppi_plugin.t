#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 12 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI ();
use PPI::Dumper;

PLUGIN_BASE_CLASS: {
	require_ok('PPI::Plugin');
	my $plugin = eval { PPI::Plugin->new };
	isa_ok( $plugin, 'PPI::Plugin' );
	can_ok( 'PPI::Plugin', 'statement_class', 'modify_token', 'feature_includes' );
}

PLUGIN_PASSED_TO_DOCUMENT: {
	my $plugin = PPI::Plugin->new;
	my $doc = PPI::Document->new( \"my \$x = 1;", plugins => [$plugin] );
	ok( $doc, "Document created with plugins attribute" );
	my $plugins = $doc->plugins;
	is( ref $plugins, 'ARRAY', "plugins accessor returns arrayref" );
	is( scalar @$plugins, 1, "plugins list has one entry" );
}

STATEMENT_CLASS_HOOK: {
	{
		package TestPlugin::StatementClass;
		use parent 'PPI::Plugin';
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

	my $stmts = $doc->find('PPI::Statement::Expression');
	ok( $stmts && @$stmts, "plugin's statement_class hook was invoked" );
}

MODIFY_TOKEN_HOOK: {
	{
		package TestPlugin::ModifyToken;
		use parent 'PPI::Plugin';
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

	my $words = $doc->find('PPI::Token::Word');
	my ($method_word) = grep { $_->content eq 'method' } @$words;
	ok( $method_word && $method_word->{_plugin_seen},
		"plugin's modify_token hook was called" );
}

FEATURE_INCLUDES_HOOK: {
	{
		package TestPlugin::FeatureIncludes;
		use parent 'PPI::Plugin';
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

	my $sigs = $doc->find('PPI::Structure::Signature');
	ok( $sigs && @$sigs, "plugin's feature_includes hook enabled signatures" );
}
