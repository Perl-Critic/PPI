#!/usr/bin/perl

# Test the PPI::Util package

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI::Lexer ();
use PPI;
use PPI::Util '_Document',
              '_slurp';

# Execute the tests
use Test::More tests => 12;

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

my $have_alarm   = PPI::Util::HAVE_ALARM();
my $have_unicode = PPI::Util::HAVE_UNICODE();
ok( defined $have_alarm,   'HAVE_ALARM defined'   );
ok( defined $have_unicode, 'HAVE_UNICODE defined' );
is( $have_alarm,   !! $have_alarm,   'HAVE_ALARM is a boolean'   );
is( $have_unicode, !! $have_unicode, 'HAVE_UNICODE is a boolean' );
