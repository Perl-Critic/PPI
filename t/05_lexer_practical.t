#!/usr/bin/perl -w

# Compare a large number of specific constructs
# with the expected Lexer dumps.

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI::Lexer;
use PPI::Dumper;





#####################################################################
# Prepare

use Test::More tests => 112;

use vars qw{$testdir};
BEGIN {
	$testdir = catdir( 't', 'data', '05_lexer_practical' );
}

# Does the test directory exist?
ok( (-e $testdir and -d $testdir and -r $testdir), "Test directory $testdir found" );

# Find the .code test files
opendir( TESTDIR, $testdir ) or die "opendir: $!";
my @code = map { catfile( $testdir, $_ ) } sort grep { /\.code$/ } readdir(TESTDIR);
closedir( TESTDIR ) or die "closedir: $!";
ok( scalar @code, 'Found at least one code file' );





#####################################################################
# Testing

my $Lexer = PPI::Lexer->new;
foreach my $codefile ( @code ) {
	# Does the .code file have a matching .dump file
	my $dumpfile = $codefile;
	$dumpfile =~ s/\.code$/\.dump/;
	ok( (-f $dumpfile and -r $dumpfile), "$codefile: Found matching .dump file" );

	# Create the lexer and get the Document object
	my $Document = $Lexer->lex_file( $codefile );
	ok( $Document,                          "$codefile: Lexer->Document returns true" );
	isa_ok( $Document, 'PPI::Document' );

	# Are there any unknown things?
	is( $Document->find_any('Token::Unknown'), '',
		"$codefile: Contains no PPI::Token::Unknown elements" );
	is( $Document->find_any('Structure::Unknown'), '',
		"$codefile: Contains no PPI::Structure::Unknown elements" );
	is( $Document->find_any('Statement::Unknown'), '',
		"$codefile: Contains no PPI::Statement::Unknown elements" );

	# Get the dump array ref for the Document object
	my $Dumper = PPI::Dumper->new( $Document );
	isa_ok( $Dumper, 'PPI::Dumper' );
	my @dump_list = $Dumper->list;
	ok( scalar @dump_list, "$codefile: Got dump content from dumper" );

	# Try to get the .dump file array
	open( DUMP, $dumpfile ) or die "open: $!";
	my @content = <DUMP>;
	close( DUMP ) or die "close: $!";
	chomp @content;

	# Compare the two
	is_deeply( \@dump_list, \@content, "$codefile: Generated dump matches stored dump" );

	# Also, do a round-trip check
	my $rv = open( CODEFILE, '<', $codefile );
	ok( $rv, "$codefile: Opened for reading" );
	SKIP: {
		skip "Failed to find file", 1 unless $rv;
		my $source = do { local $/ = undef; <CODEFILE> };
		close CODEFILE;
		$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;

		is( $Document->serialize, $source, "$codefile: Round-trip back to source was ok" );
	}
}

exit();
