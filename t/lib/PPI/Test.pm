package t::lib::PPI::Test;

use warnings;
use strict;

use File::Spec::Functions ();

use vars qw{$VERSION @ISA @EXPORT_OK %EXPORT_TAGS};
BEGIN {
	$VERSION = '1.220';
	@ISA = 'Exporter';
	@EXPORT_OK = qw( pause find_files );
}


# Find file names in named t/data dirs
sub find_files {
	my $testdir  = shift;
	
	# Does the test directory exist?
	-e $testdir and -d $testdir and -r $testdir or die "Failed to find test directory $testdir";
	
	# Find the .code test files
	opendir( TESTDIR, $testdir ) or die "opendir: $!";
	my @perl = map { File::Spec::Functions::catfile( $testdir, $_ ) } sort grep { /\.(?:code|pm|t)$/ } readdir(TESTDIR);
	closedir( TESTDIR ) or die "closedir: $!";
	return @perl;
}


sub pause {
	local $@;
	sleep 1 if !eval { require Time::HiRes; Time::HiRes::sleep(0.1); 1 };
}


1;
