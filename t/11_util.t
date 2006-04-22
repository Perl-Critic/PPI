#!/usr/bin/perl -w

# Test the PPI::Util package

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

# Load the code to test
BEGIN { $PPI::XS_DISABLE = 1 }
use PPI::Lexer ();
use PPI;
use PPI::Util '_Document',
              '_slurp';

# Execute the tests
use Test::More tests => 8;

my $testfile   = catfile( 't', 'data', '11_util', 'test.pm' );
my $testsource = 'print "Hello World!\n"';

my $slurpfile = catfile( 't', 'data', 'basic.pl' );
my $slurpcode = <<'END_FILE';
#!/usr/bin/perl

if ( 1 ) {
	print "Hello World!\n";
}

1;

END_FILE




#####################################################################
# Test PPI::Util::_Document

my $Document = PPI::Document->new( \$testsource );
isa_ok( $Document, 'PPI::Document' );

# Good things
foreach my $thing ( $testfile, \$testsource, $Document ) {
	isa_ok( _Document( $thing ), 'PPI::Document' );
}

# Bad things
### erm...

# Evil things
foreach my $thing ( [], {}, sub () { 1 } ) {
	is( _Document( $thing ), undef, '_Document(evil) returns undef' );
}




#####################################################################
# Test PPI::Util::_slurp

my $source = _slurp( $slurpfile );
is_deeply( $source, \$slurpcode, '_slurp loads file as expected' );

1;
