#!/usr/bin/env perl

# Release readiness report based on TODO test analysis.
# Implements the workflow from https://github.com/Perl-Critic/PPI/issues/176
#
# Usage:
#   perl xt/author/todo-report.pl          # full test run + categorized report
#   perl xt/author/todo-report.pl --scan   # quick scan of TODO markers (no test run)

use strict;
use warnings;
use File::Find ();
use Getopt::Long ();

my $scan_only;
Getopt::Long::GetOptions( 'scan' => \$scan_only ) or die "Usage: $0 [--scan]\n";

$scan_only ? scan_files() : run_and_report();

sub scan_files {
    my @findings;

    File::Find::find(
        {
            wanted => sub {
                return unless /\.t$/ && -f;
                my $file = $File::Find::name;
                open my $fh, '<', $file or return;
                while ( my $line = <$fh> ) {
                    push @findings, { file => $file, line => $., expr => $1 }
                        if $line =~ /local \$TODO\s*=\s*(.+?)\s*;\s*$/;
                }
                close $fh;
            },
            no_chdir => 1,
        },
        't'
    );

    print "=== TODO Test Inventory ===\n\n";

    return print "No TODO markers found.\n" if !@findings;

    my $current_file = '';
    for my $f ( sort { $a->{file} cmp $b->{file} || $a->{line} <=> $b->{line} } @findings ) {
        if ( $f->{file} ne $current_file ) {
            print "\n" if $current_file;
            $current_file = $f->{file};
            print "$current_file:\n";
        }
        printf "  line %d: %s\n", $f->{line}, $f->{expr};
    }

    printf "\n%d TODO marker(s) across %d file(s).\n",
        scalar @findings,
        scalar keys %{ { map { $_->{file} => 1 } @findings } };

    print "\nRun without --scan to see which TODO tests pass or fail.\n";
}

sub run_and_report {
    my ( @todo_pass, @todo_fail, @regression );
    my $current_file = '';

    open my $pipe, '-|', 'prove', '--norc', '-l', '-v', 't'
        or die "Cannot run prove: $!\n";

    while (<$pipe>) {
        $current_file = $1 if /^(t\/\S+)/;

        if ( /^\s*ok\s+\d+\s+-?\s*(.*?)\s*#\s*TODO\s+(.*)/ ) {
            push @todo_pass, { file => $current_file, desc => $1, reason => $2 };
        }
        elsif ( /^\s*not ok\s+\d+\s+-?\s*(.*?)\s*#\s*TODO\s+(.*)/ ) {
            push @todo_fail, { file => $current_file, desc => $1, reason => $2 };
        }
        elsif ( /^\s*not ok\s+\d+\s+-?\s*(.*)/ && !/# TODO/ && !/# skip/i ) {
            push @regression, { file => $current_file, desc => $1 };
        }
    }
    close $pipe;

    print "=== PPI Release Readiness Report ===\n\n";

    section( "TODO tests now PASSING (can remove TODO marker)", \@todo_pass );
    section( "TODO tests still failing (known bugs, safe to release with)", \@todo_fail );

    if (@regression) {
        section( "Non-TODO test FAILURES (regressions, must fix before release)", \@regression );
    }

    printf "\nSummary: %d TODO-passing, %d TODO-failing, %d regression(s)\n",
        scalar @todo_pass, scalar @todo_fail, scalar @regression;

    print @regression
        ? "Release status: BLOCKED (regressions detected)\n"
        : "Release status: SAFE\n";
}

sub section {
    my ( $title, $items ) = @_;
    printf "%s: %d\n", $title, scalar @$items;
    return if !@$items;

    my %by_file;
    push @{ $by_file{ $_->{file} } }, $_ for @$items;

    for my $file ( sort keys %by_file ) {
        printf "  %s (%d)\n", $file, scalar @{ $by_file{$file} };
    }
    print "\n";
}
