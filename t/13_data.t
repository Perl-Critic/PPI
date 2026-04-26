#!/usr/bin/perl

# Tests functionality relating to __DATA__ sections of files

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 20 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use File::Spec::Functions qw( catfile );
use PPI ();
use Helper 'safe_new';


my $module = catfile('t', 'data', '13_data', 'Foo.pm');
ok( -f $module, 'Test file exists' );

my $Document = safe_new $module;

# Get the data token
my $Token = $Document->find_first( 'Token::Data' );
isa_ok( $Token, 'PPI::Token::Data' );

# Get the handle
my $handle = $Token->handle;
isa_ok( $handle, "$]" < 5.008 ? 'IO::String' : 'GLOB' );

# Try to read a line off the handle
my $line = <$handle>;
is( $line, "This is data\n", "Reading off a handle works as expected" );

# Print to the handle
ok( $handle->print("Foo bar\n"), "handle->print returns ok" );
is( $Token->content, "This is data\nFoo bar\nis\n",
	"handle->print modifies the content as expected" );


# POD within __DATA__ should be parsed as PPI::Token::Pod (issue #15)
{
	my $code = "1;\n__DATA__\nsome data\n=head1 DESCRIPTION\nSome pod text\n=cut\nmore data\n";
	my $doc = safe_new \$code;

	my @data = @{ $doc->find( 'Token::Data' ) || [] };
	my @pods = @{ $doc->find( 'Token::Pod' )  || [] };

	is( scalar @pods, 1, '__DATA__: found 1 Pod token' );
	is( scalar @data, 2, '__DATA__: found 2 Data tokens (before and after pod)' );
	is( $pods[0] && $pods[0]->content, "=head1 DESCRIPTION\nSome pod text\n=cut\n",
		'__DATA__: Pod token has correct content' );
	is( $data[0] && $data[0]->content, "some data\n",
		'__DATA__: first Data token is content before pod' );
	is( $data[1] && $data[1]->content, "more data\n",
		'__DATA__: second Data token is content after pod' );

	is( $doc->serialize, $code, '__DATA__ with pod: round-trip serialization' );
}

# POD at start of __DATA__ section
{
	my $code = "1;\n__DATA__\n=head1 TITLE\npod\n=cut\n";
	my $doc = safe_new \$code;

	my @pods = @{ $doc->find( 'Token::Pod' ) || [] };

	is( scalar @pods, 1, '__DATA__: pod at start of data section is recognized' );
	is( $doc->serialize, $code, '__DATA__ pod at start: round-trip serialization' );
}
