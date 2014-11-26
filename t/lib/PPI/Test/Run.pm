package t::lib::PPI::Test::Run;

use File::Spec::Functions ':ALL';
use Params::Util qw{_INSTANCE};
use PPI::Document;
use PPI::Dumper;
use Test::More;
use Test::Object;
use t::lib::PPI::Test::Object;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.218';
}


#####################################################################
# Process a .code/.dump file pair
# plan: 2 + 14 * npairs

sub run_testdir {
	my $pkg     = shift;
	my $testdir = catdir(@_);

	# Does the test directory exist?
	ok( (-e $testdir and -d $testdir and -r $testdir), "Test directory $testdir found" );

	# Find the .code test files
	local *TESTDIR;
	opendir( TESTDIR, $testdir ) or die "opendir: $!";
	my @code = map { catfile( $testdir, $_ ) } sort grep { /\.code$/ } readdir(TESTDIR);
	closedir( TESTDIR ) or die "closedir: $!";
	ok( scalar @code, 'Found at least one code file' );

	foreach my $codefile ( @code ) {
		# Does the .code file have a matching .dump file
		my $dumpfile = $codefile;
		$dumpfile =~ s/\.code$/\.dump/;
		my $codename = $codefile;
		$codename =~ s/\.code$//;
		ok( (-f $dumpfile and -r $dumpfile), "$codename: Found matching .dump file" );

		# Create the lexer and get the Document object
		my $document = PPI::Document->new( $codefile );
		ok( $document, "$codename: Lexer->Document returns true" );
		ok( _INSTANCE($document, 'PPI::Document'), "$codename: Object isa PPI::Document" );

		my $rv;
		local *CODEFILE;
		SKIP: {
			skip "No Document to test", 12 unless $document;

			# Index locations
			ok( $document->index_locations, "$codename: ->index_locations ok" );

			# Check standard things
			object_ok( $document ); # 7 tests contained within

			# Get the dump array ref for the Document object
			my $Dumper = PPI::Dumper->new( $document );
			ok( _INSTANCE($Dumper, 'PPI::Dumper'), "$codename: Object isa PPI::Dumper" );
			my @dump_list = $Dumper->list;
			ok( scalar @dump_list, "$codename: Got dump content from dumper" );

			# Try to get the .dump file array
			local *DUMP;
			open( DUMP, '<', $dumpfile ) or die "open: $!";
			my @content = <DUMP>;
			close( DUMP ) or die "close: $!";
			chomp @content;

			# Compare the two
			is_deeply( \@dump_list, \@content, "$codename: Generated dump matches stored dump" );

			# Also, do a round-trip check
			$rv = open( CODEFILE, '<', $codefile );
			ok( $rv, "$codename: Opened file" );
		}
		SKIP: {
			unless ( $document and $rv ) {
				skip "Missing file", 1;
			}
			my $source = do { local $/ = undef; <CODEFILE> };
			close CODEFILE;
			$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;

			is( $document->serialize, $source, "$codename: Round-trip back to source was ok" );
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
	ok( (-e $testdir and -d $testdir and -r $testdir), "Test directory $testdir found" );

	# Find the .code test files
	local *TESTDIR;
	opendir( TESTDIR, $testdir ) or die "opendir: $!";
	my @code = map { catfile( $testdir, $_ ) } sort grep { /\.code$/ } readdir(TESTDIR);
	closedir( TESTDIR ) or die "closedir: $!";
	ok( scalar @code, 'Found at least one code file' );

	foreach my $codefile ( @code ) {
		# Does the .code file have a matching .dump file
		my $codename = $codefile;
		$codename =~ s/\.code$//;

		# Load the file
		local *CODEFILE;
		local $/ = undef;
		open( CODEFILE, '<', $codefile ) or die "open: $!";
		my $buffer = <CODEFILE>;
		close( CODEFILE ) or die "close: $!";

		# Cover every possible transitional state in
		# the regression test code fragments.
		foreach my $chars ( 1 .. length($buffer) ) {
			my $string   = substr( $buffer, 0, $chars );
			my $document = eval {
				PPI::Document->new( \$string );
			};
			is(
				$@ => '',
				"$codename: $chars chars ok",
			);
			is(
				ref($document) => 'PPI::Document',
				"$codename: $chars chars document",
			);
			is(
				$document->serialize => $string,
				"$codename: $chars char roundtrip",
			);
		}
	}
}

1;
