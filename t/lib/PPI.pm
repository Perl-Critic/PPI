package t::lib::PPI;

use File::Spec::Functions ':ALL';
use Test::More;
use Test::Object;
use Params::Util    '_INSTANCE';
use List::MoreUtils 'any';
use PPI::Dumper;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# PPI::Document Testing

Test::Object->register(
	class => 'PPI::Document',
	tests => 1,
	code  => \&document_ok,
);

sub document_ok {
	my $doc = shift;

	# A document should have zero or more children that are either
	# a statement or a non-significant child.
	my @children = $doc->children;
	my $good = grep {
		_INSTANCE($_, 'PPI::Statement')
		or (
			_INSTANCE($_, 'PPI::Token') and ! $_->significant
			)
		} @children;

	is( $good, scalar(@children),
		'Document contains only statements and non-significant tokens' );

	1;
}





#####################################################################
# Are there an unknowns

Test::Object->register(
	class => 'PPI::Document',
	tests => 3,
	code  => \&unknown_objects,
);

sub unknown_objects {
	my $doc = shift;

	is( $doc->find_any('Token::Unknown'), '',
		"Contains no PPI::Token::Unknown elements" );
	is( $doc->find_any('Structure::Unknown'), '',
		"Contains no PPI::Structure::Unknown elements" );
	is( $doc->find_any('Statement::Unknown'), '',
		"Contains no PPI::Statement::Unknown elements" );

	1;
}




#####################################################################
# Are there any invalid nestings?

Test::Object->register(
	class => 'PPI::Document',
	tests => 1,
	code  => \&nested_statements,
);

sub nested_statements {
	my $doc = shift;

	ok( ! $doc->find_any( sub {
		_INSTANCE($_[1], 'PPI::Statement')
		and
		any { _INSTANCE($_, 'PPI::Statement') } $_[1]->children
		} ),
		'Document contains no nested statements',
	);	
}

Test::Object->register(
	class => 'PPI::Document',
	tests => 1,
	code  => \&nested_structures,
);

sub nested_structures {
	my $doc = shift;

	ok( ! $doc->find_any( sub {
		_INSTANCE($_[1], 'PPI::Structure')
		and
		any { _INSTANCE($_, 'PPI::Structure') } $_[1]->children
		} ),
		'Document contains no nested structures',
	);	
}





#####################################################################
# Process a .code/.dump file pair
# plan: 2 + 14 * npairs

sub run_testdir {
	my $pkg = shift;
	my $testdir = shift;

	# Does the test directory exist?
	ok( (-e $testdir and -d $testdir and -r $testdir), "Test directory $testdir found" );

	# Find the .code test files
        local *TESTDIR;
	opendir( TESTDIR, $testdir ) or die "opendir: $!";
	my @code = map { catfile( $testdir, $_ ) } sort grep { /\.code$/ } readdir(TESTDIR);
	closedir( TESTDIR ) or die "closedir: $!";
	ok( scalar @code, 'Found at least one code file' );

	my $Lexer = PPI::Lexer->new;
	foreach my $codefile ( @code ) {
		# Does the .code file have a matching .dump file
		my $dumpfile = $codefile;
		$dumpfile =~ s/\.code$/\.dump/;
		my $codename = $codefile;
		$codename =~ s/\.code$//;
		ok( (-f $dumpfile and -r $dumpfile), "$codename: Found matching .dump file" );

		# Create the lexer and get the Document object
		my $Document = $Lexer->lex_file( $codefile );
		ok( $Document, "$codename: Lexer->Document returns true" );
		ok( _INSTANCE($Document, 'PPI::Document'), "$codename: Object isa PPI::Document" );

		my $rv;
		local *CODEFILE;
		SKIP: {
			skip "No Document to test", 10 unless $Document;

			# Check standard things
			object_ok( $Document ); # 6 tests contained within

			# Get the dump array ref for the Document object
			my $Dumper = PPI::Dumper->new( $Document );
			ok( _INSTANCE($Dumper, 'PPI::Dumper'), "$codename: Object isa PPI::Dumper" );
			my @dump_list = $Dumper->list;
			ok( scalar @dump_list, "$codename: Got dump content from dumper" );

			local *DUMP;
			# Try to get the .dump file array
			open( DUMP, $dumpfile ) or die "open: $!";
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
			unless ( $Document and $rv ) {
				skip "Missing file", 1;
			}
			my $source = do { local $/ = undef; <CODEFILE> };
			close CODEFILE;
			$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;

			is( $Document->serialize, $source, "$codename: Round-trip back to source was ok" );
		}
	}
}


1;
