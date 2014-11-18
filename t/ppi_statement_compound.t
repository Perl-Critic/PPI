#!/usr/bin/perl

# Unit testing for PPI::Statement::Compound

use t::lib::PPI::Test::pragmas;
use Test::More tests => 53;

use PPI;


TYPE: {
	my $Document = PPI::Document->new(\<<'END_PERL');
       while (1) { }
       until (1) { }
LABEL: while (1) { }
LABEL: until (1) { }

if (1) { }
unless (1) { }

       for              (@foo) { }
       foreach          (@foo) { }
       for     $x       (@foo) { }
       foreach $x       (@foo) { }
       for     my $x    (@foo) { }
       foreach my $x    (@foo) { }
       for     state $x (@foo) { }
       foreach state $x (@foo) { }
LABEL: for              (@foo) { }
LABEL: foreach          (@foo) { }
LABEL: for     $x       (@foo) { }
LABEL: foreach $x       (@foo) { }
LABEL: for     my $x    (@foo) { }
LABEL: foreach my $x    (@foo) { }
LABEL: for     state $x (@foo) { }
LABEL: foreach state $x (@foo) { }

       for              qw{foo} { }
       foreach          qw{foo} { }
       for     $x       qw{foo} { }
       foreach $x       qw{foo} { }
       for     my $x    qw{foo} { }
       foreach my $x    qw{foo} { }
       for     state $x qw{foo} { }
       foreach state $x qw{foo} { }
LABEL: for              qw{foo} { }
LABEL: foreach          qw{foo} { }
LABEL: for     $x       qw{foo} { }
LABEL: foreach $x       qw{foo} { }
LABEL: for     my $x    qw{foo} { }
LABEL: foreach my $x    qw{foo} { }
LABEL: for     state $x qw{foo} { }
LABEL: foreach state $x qw{foo} { }

       for     (             ;       ;     ) { }
       foreach (             ;       ;     ) { }
       for     ($x = 0       ; $x < 1; $x++) { }
       foreach ($x = 0       ; $x < 1; $x++) { }
       for     (my $x = 0    ; $x < 1; $x++) { }
       foreach (my $x = 0    ; $x < 1; $x++) { }
LABEL: for     (             ;       ;     ) { }
LABEL: foreach (             ;       ;     ) { }
LABEL: for     ($x = 0       ; $x < 1; $x++) { }
LABEL: foreach ($x = 0       ; $x < 1; $x++) { }
LABEL: for     (my $x = 0    ; $x < 1; $x++) { }
LABEL: foreach (my $x = 0    ; $x < 1; $x++) { }
END_PERL
	isa_ok( $Document, 'PPI::Document' );

	my $statements = $Document->find('Statement::Compound');
	is( scalar @{$statements}, 50, 'Found the 50 test statements' );

	is( $statements->[0]->type, 'while', q<Type of while is "while"> );
	is( $statements->[1]->type, 'while', q<Type of until is "while"> );
	is( $statements->[2]->type, 'while', q<Type of while with label is "while"> );
	is( $statements->[3]->type, 'while', q<Type of until with label is "while"> );
	is( $statements->[4]->type, 'if',    q<Type of if is "if"> );
	is( $statements->[5]->type, 'if',    q<Type of unless is "if"> );

	foreach my $index (6..37) {
		my $statement = $statements->[$index];
		is( $statement->type, 'foreach', qq<Type is "foreach": $statement> );
	}

	foreach my $index (38..49) {
		my $statement = $statements->[$index];
		is( $statement->type, 'for', qq<Type is "for": $statement> );
	}
}
