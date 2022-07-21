#!/usr/bin/perl

# Test the PPI::Util package

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 11 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use File::Spec::Functions qw( catfile );
use PPI ();
use PPI::Util qw( _Document _slurp );
use Helper 'safe_new';

# Execute the tests
my $testfile   = catfile( 't', 'data', '11_util', 'test.pm' );
my $testsource = 'print "Hello World!\n"';
my $slurpfile  = catfile( 't', 'data', 'basic.pl' );
my $slurpcode  = <<'END_FILE';
#!/usr/bin/perl

if ( 1 ) {
	print "Hello World!\n";
}

1;

END_FILE




#####################################################################
# Test PPI::Util::_Document

my $Document = safe_new \$testsource;

# Good things
foreach my $thing ( $testfile, \$testsource, $Document, [] ) {
	isa_ok( _Document( $thing ), 'PPI::Document' );
}

# Bad things
### erm...

# Evil things
foreach my $thing ( {}, sub () { 1 } ) {
	is( _Document( $thing ), undef, '_Document(evil) returns undef' );
}




#####################################################################
# Test PPI::Util::_slurp

my $source = _slurp( $slurpfile );
is_deeply( $source, \$slurpcode, '_slurp loads file as expected' );





#####################################################################
# Check the capability flags

my $have_unicode = PPI::Util::HAVE_UNICODE();
ok( defined $have_unicode, 'HAVE_UNICODE defined' );
is( $have_unicode, !! $have_unicode, 'HAVE_UNICODE is a boolean' );
