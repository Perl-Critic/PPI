#!/usr/bin/perl

# PPI::Document tests

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;

# Execute the tests
use Test::More tests => 13;

# Test file
my $file  = catfile(qw{ t data 03_document test.dat  });
my $empty = catfile(qw{ t data 03_document empty.dat });
ok( -f $file,  'Found test file' );
ok( -f $empty, 'Found test file' );

# Test script
my $script = <<'END_PERL';
#!/usr/bin/perl

# A simple test script

print "Hello World!\n";
END_PERL





#####################################################################
# Test a basic document

# Parse a simple document in all possible ways
SCOPE: {
	my $doc1 = PPI::Document->new( $file );
	isa_ok( $doc1, 'PPI::Document' );

	my $doc2 = PPI::Document->new( \$script );
	isa_ok( $doc2, 'PPI::Document' );

	my $doc3 = PPI::Document->new( [
		"#!/usr/bin/perl",
		"",
		"# A simple test script",
		"",
		"print \"Hello World!\\n\";",
	] );
	isa_ok( $doc3, 'PPI::Document' );

	# Compare the three forms
	is_deeply( $doc1, $doc2, 'Stringref form matches file form' );
	is_deeply( $doc1, $doc3, 'Arrayref form matches file form'  );
}

# Repeat the above with a null document
SCOPE: {
	my $doc1 = PPI::Document->new( $empty );
	isa_ok( $doc1, 'PPI::Document' );

	my $doc2 = PPI::Document->new( \'' );
	isa_ok( $doc2, 'PPI::Document' );

	my $doc3 = PPI::Document->new( [ ] );
	isa_ok( $doc3, 'PPI::Document' );

	# Compare the three forms
	is_deeply( $doc1, $doc2, 'Stringref form matches file form' );
	is_deeply( $doc1, $doc3, 'Arrayref form matches file form'  );

	# Make sure the null document round-trips
	my $string = $doc1->serialize;
	is( $string, '', '->serialize ok' );
}
