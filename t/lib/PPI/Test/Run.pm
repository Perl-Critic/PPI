package PPI::Test::Run;

use File::Spec::Functions ':ALL';
use Params::Util qw{_INSTANCE};
use PPI::Document;
use PPI::Dumper;
use Test::More;
use Test::Object;
use lib 't/lib';
use PPI::Test::Object;
use Helper 'safe_new';

#####################################################################
# Process a .code/.dump file pair
# plan: 2 + 14 * npairs

sub run_testdir {
	my $pkg     = shift;
	my $testdir = catdir(@_);

	# Does the test directory exist?
	ok( ( -e $testdir and -d $testdir and -r $testdir ),
		"Test directory $testdir found" );

	# Find the .code test files
	my @code = do {
		opendir my $TESTDIR, $testdir or die "opendir: $!";
		map { catfile $testdir, $_ } sort grep /\.code$/, readdir $TESTDIR;
	};
	ok( scalar @code, 'Found at least one code file' );

	foreach my $codefile (@code) {
		# Does the .code file have a matching .dump file
		my $dumpfile = $codefile;
		$dumpfile =~ s/\.code$/\.dump/;
		my $codename = $codefile;
		$codename =~ s/\.code$//;
		my $has_dumpfile = -f $dumpfile and -r $dumpfile;
		ok( $has_dumpfile, "$codename: Found matching .dump file" );

		# Create the lexer and get the Document object
		my $document = safe_new $codefile;
		ok( $document, "$codename: Lexer->Document returns true" );

	  SKIP: {
			skip "No Document to test", 12 unless $document;

			# Index locations
			ok( $document->index_locations, "$codename: ->index_locations ok" );

			# Check standard things
			object_ok($document);    # 7 tests contained within

			# Get the dump array ref for the Document object
			my $Dumper = PPI::Dumper->new($document);
			ok(
				_INSTANCE( $Dumper, 'PPI::Dumper' ),
				"$codename: Object isa PPI::Dumper"
			);
			my @dump_list = $Dumper->list;
			ok( scalar @dump_list, "$codename: Got dump content from dumper" );

			# Try to get the .dump file array
			my @content = !$has_dumpfile ? () : do {
				open my $DUMP, '<', $dumpfile or die "open: $!";
				binmode $DUMP;
				<$DUMP>;
			};
			chomp @content;

			# Compare the two
			{
				local $TODO = $ENV{TODO} if $ENV{TODO};
				is_deeply( \@dump_list, \@content,
					"$codename: Generated dump matches stored dump" )
				  or diag map "$_\n", @dump_list;
			}
		}
	  SKIP: {
			# Also, do a round-trip check
			skip "No roundtrip check: Couldn't parse code file before", 1
			  if !$document;
			skip "No roundtrip check: Couldn't open code file '$codename', $!",
			  1
			  unless    #
			  my $source = do {
				open my $CODEFILE, '<', $codefile;
				binmode $CODEFILE;
				local $/;
				<$CODEFILE>;
			  };
			$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;

			is( $document->serialize, $source,
				"$codename: Round-trip back to source was ok" );
		}
	}
}

#####################################################################
# Process a .code/.dump file pair
# plan: 2 + 14 * npairs

sub increment_testdir {
	my $pkg     = shift;
	my $testdir = catdir(@_);

	# Does the test directory exist?
	ok( ( -e $testdir and -d $testdir and -r $testdir ),
		"Test directory $testdir found" );

	# Find the .code test files
	my @code = do {
		opendir my $TESTDIR, $testdir or die "opendir: $!";
		map { catfile $testdir, $_ } sort grep /\.code$/, readdir $TESTDIR;
	};
	ok( scalar @code, 'Found at least one code file' );

	for my $codefile (@code) {
		# Does the .code file have a matching .dump file
		my $codename = $codefile;
		$codename =~ s/\.code$//;

		# Load the file
		my $buffer = do {
			local $/;
			open my $CODEFILE, '<', $codefile or die "open: $!";
			binmode $CODEFILE;
			<$CODEFILE>;
		};

		# Cover every possible transitional state in
		# the regression test code fragments.
		for my $chars ( 1 .. length $buffer ) {
			my $string   = substr $buffer, 0, $chars;
			my $document = eval { safe_new \$string };
			is( $@ => '', "$codename: $chars chars ok" );
			is(
				$document->serialize => $string,
				"$codename: $chars char roundtrip"
			);
		}
	}
}

1;
