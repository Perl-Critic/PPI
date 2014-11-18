#!/usr/bin/perl

# Unit testing for PPI::Statement

use t::lib::PPI::Test::pragmas;
use Test::More tests => 23;

use PPI;


SPECIALIZED: {
	my $Document = PPI::Document->new(\<<'END_PERL');
package Foo;
use strict;
;
while (1) { last; }
BEGIN { }
sub foo { }
state $x;
$x = 5;
END_PERL

	isa_ok( $Document, 'PPI::Document' );

	my $statements = $Document->find('Statement');
	is( scalar @{$statements}, 10, 'Found the 10 test statements' );

	isa_ok( $statements->[0], 'PPI::Statement::Package',    'Statement 1: isa Package'            );
	ok( $statements->[0]->specialized,                      'Statement 1: is specialized'         );
	isa_ok( $statements->[1], 'PPI::Statement::Include',    'Statement 2: isa Include'            );
	ok( $statements->[1]->specialized,                      'Statement 2: is specialized'         );
	isa_ok( $statements->[2], 'PPI::Statement::Null',       'Statement 3: isa Null'               );
	ok( $statements->[2]->specialized,                      'Statement 3: is specialized'         );
	isa_ok( $statements->[3], 'PPI::Statement::Compound',   'Statement 4: isa Compound'           );
	ok( $statements->[3]->specialized,                      'Statement 4: is specialized'         );
	isa_ok( $statements->[4], 'PPI::Statement::Expression', 'Statement 5: isa Expression'         );
	ok( $statements->[4]->specialized,                      'Statement 5: is specialized'         );
	isa_ok( $statements->[5], 'PPI::Statement::Break',      'Statement 6: isa Break'              );
	ok( $statements->[5]->specialized,                      'Statement 6: is specialized'         );
	isa_ok( $statements->[6], 'PPI::Statement::Scheduled',  'Statement 7: isa Scheduled'          );
	ok( $statements->[6]->specialized,                      'Statement 7: is specialized'         );
	isa_ok( $statements->[7], 'PPI::Statement::Sub',        'Statement 8: isa Sub'                );
	ok( $statements->[7]->specialized,                      'Statement 8: is specialized'         );
	isa_ok( $statements->[8], 'PPI::Statement::Variable',   'Statement 9: isa Variable'           );
	ok( $statements->[8]->specialized,                      'Statement 9: is specialized'         );
	is( ref $statements->[9], 'PPI::Statement',             'Statement 10: is a simple Statement' );
	ok( ! $statements->[9]->specialized,                    'Statement 10: is not specialized'    );
}
