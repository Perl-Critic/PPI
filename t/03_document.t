#!/usr/bin/perl

# PPI::Document tests

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 22 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use File::Spec::Functions qw( catfile );
use PPI                   ();
use Helper 'safe_new';

#####################################################################
# Test a basic document

# Parse a simple document in all possible ways
NEW: {
	my $file = catfile(qw{ t data 03_document test.dat  });
	ok( -f $file, 'Found test.dat' );

	my $doc1 = safe_new $file;

	# Test script
	my $script = <<'END_PERL';
#!/usr/bin/perl

# A simple test script

print "Hello World!\n";
END_PERL
	my $doc2 = safe_new \$script;

	my $doc3 = safe_new [
		"#!/usr/bin/perl", "", "# A simple test script", "",
		"print \"Hello World!\\n\";",
	];

	# Compare the three forms
	is_deeply( $doc1, $doc2, 'Stringref form matches file form' );
	is_deeply( $doc1, $doc3, 'Arrayref form matches file form' );
}

# Repeat the above with a null document
NEW_EMPTY: {
	my $empty = catfile(qw{ t data 03_document empty.dat });
	ok( -f $empty, 'Found empty.dat' );

	my $doc1 = safe_new $empty;
	my $doc2 = safe_new \'';
	my $doc3 = safe_new [];

	# Compare the three forms
	is_deeply( $doc1, $doc2, 'Stringref form matches file form' );
	is_deeply( $doc1, $doc3, 'Arrayref form matches file form' );

	# Make sure the null document round-trips
	my $string = $doc1->serialize;
	is( $string, '', '->serialize ok' );

	ok $doc1->location;
	ok $doc2->location;
	ok $doc3->location;
}
