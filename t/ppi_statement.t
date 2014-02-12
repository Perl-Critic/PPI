#!/usr/bin/perl

# Unit testing for PPI::Statement

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 49;
use Test::NoWarnings;
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
sub BEGIN { }
CHECK {}
sub CHECK {}
UNITCHECK {}
sub UNITCHECK {}
INIT {}
sub INIT {}
END {}
sub END {}
AUTOLOAD {}
sub AUTOLOAD {}
DESTROY {}
sub DESTROY {}
END_PERL

	isa_ok( $Document, 'PPI::Document' );

	my $statements = $Document->find('Statement');
	is( scalar @{$statements}, 23, 'Found the 23 test statements' );

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
	isa_ok( $statements->[10], 'PPI::Statement::Scheduled', 'Statement 11: isa Scheduled'         );
	ok( $statements->[10]->specialized,                     'Statement 11: is specialized'        );
	isa_ok( $statements->[11], 'PPI::Statement::Scheduled', 'Statement 12: isa Scheduled'         );
	ok( $statements->[11]->specialized,                     'Statement 12: is specialized'        );
	isa_ok( $statements->[12], 'PPI::Statement::Scheduled', 'Statement 13: isa Scheduled'         );
	ok( $statements->[12]->specialized,                     'Statement 13: is specialized'        );
	isa_ok( $statements->[13], 'PPI::Statement::Scheduled', 'Statement 14: isa Scheduled'         );
	ok( $statements->[13]->specialized,                     'Statement 14: is specialized'        );
	isa_ok( $statements->[14], 'PPI::Statement::Scheduled', 'Statement 15: isa Scheduled'         );
	ok( $statements->[14]->specialized,                     'Statement 15: is specialized'        );
	isa_ok( $statements->[15], 'PPI::Statement::Scheduled', 'Statement 16: isa Scheduled'         );
	ok( $statements->[15]->specialized,                     'Statement 16: is specialized'        );
	isa_ok( $statements->[16], 'PPI::Statement::Scheduled', 'Statement 17: isa Scheduled'         );
	ok( $statements->[16]->specialized,                     'Statement 17: is specialized'        );
	isa_ok( $statements->[17], 'PPI::Statement::Scheduled', 'Statement 18: isa Scheduled'         );
	ok( $statements->[17]->specialized,                     'Statement 18: is specialized'        );
	isa_ok( $statements->[18], 'PPI::Statement::Scheduled', 'Statement 19: isa Scheduled'         );
	ok( $statements->[18]->specialized,                     'Statement 19: is specialized'        );
	isa_ok( $statements->[19], 'PPI::Statement::Sub', 	'Statement 20: isa Scheduled'         );
	ok( $statements->[19]->specialized,                     'Statement 20: is specialized'        );
	isa_ok( $statements->[20], 'PPI::Statement::Sub', 	'Statement 21: isa Scheduled'         );
	ok( $statements->[20]->specialized,                     'Statement 21: is specialized'        );
	isa_ok( $statements->[21], 'PPI::Statement::Sub', 	'Statement 22: isa Scheduled'         );
	ok( $statements->[21]->specialized,                     'Statement 22: is specialized'        );
	isa_ok( $statements->[22], 'PPI::Statement::Sub', 	'Statement 23: isa Scheduled'         );
	ok( $statements->[22]->specialized,                     'Statement 23: is specialized'        );
}
