#!/usr/bin/perl

use lib 't/lib';
use PPI::Test::pragmas;
use PPI::Document;

use Test::More tests => 1 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );
use Time::HiRes 'time';

my ( $small, $big, @times ) = ( 20, 100 );

for my $mult ( $small, $big ) {
	my $source = "use v5.36;\n";
	for my $i ( 0 .. $mult ) {
		my $sub = "sub foo_$i(\$x, \$y) {\n";
		for my $j ( 0 .. 29 ) {
			$sub .=
			  "    g(\$x->[\$y]" . join( '', map ", $_", 1 .. $j ) . ");\n";
		}
		$sub    .= "}\n";
		$source .= "$sub\n";
	}

	note "parsing mult $mult, " . length($source) . " chars of code ...";
	my $start = time;
	PPI::Document->new( \$source );
	push @times, time - $start;
	note "done";
	note "elapsed: $times[-1]";
}

my $code_size_ratio = $big / $small;
my $time_ratio      = $times[1] / $times[0];
my $increase        = ( $time_ratio / $code_size_ratio ) - 1;
my $stats =
  "code ratio: $code_size_ratio\ntime ratio: $time_ratio\nincrease: $increase";

if ( $increase > 0.15 ) {
	diag "performance regression? unexpectedly large time ratio\n$stats";
}
else {
	note $stats;
}

pass;
done_testing;
