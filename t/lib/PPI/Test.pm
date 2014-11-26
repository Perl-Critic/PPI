package t::lib::PPI::Test;

use warnings;
use strict;

use File::Spec::Functions ();

use vars qw{$VERSION @ISA @EXPORT_OK %EXPORT_TAGS};
BEGIN {
	$VERSION = '1.220';
	@ISA = 'Exporter';
	@EXPORT_OK = qw( find_files quotable pause );
}


# Find file names in named t/data dirs
sub find_files {
	my ( $testdir ) = @_;

	# Does the test directory exist?
	die "Failed to find test directory $testdir" if !-e $testdir or !-d $testdir or !-r $testdir;

	# Find the .code test files
	opendir my $TESTDIR, $testdir or die "opendir: $!";
	my @perl = map { File::Spec::Functions::catfile( $testdir, $_ ) } sort grep { /\.(?:code|pm|t)$/ } readdir $TESTDIR;
	closedir $TESTDIR or die "closedir: $!";

	return @perl;
}


sub quotable {
	my ( $quotable ) = @_;
	$quotable =~ s|\\|\\\\|g;
	$quotable =~ s|\t|\\t|g;
	$quotable =~ s|\n|\\n|g;
	$quotable =~ s|\$|\\\$|g;
	$quotable =~ s|\@|\\\@|g;
	$quotable =~ s|\"|\\\"|g;
	return $quotable;
}


sub pause {
	local $@;
	sleep 1 if !eval { require Time::HiRes; Time::HiRes::sleep(0.1); 1 };
}


1;
