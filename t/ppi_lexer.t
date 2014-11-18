#!/usr/bin/perl

# Unit testing for PPI::Lexer

use t::lib::PPI::Test::pragmas;
use Test::More tests => 44;

use PPI;


UNMATCHED_BRACE: {
	my $token = new_ok( 'PPI::Token::Structure' => [ ')' ] );
	my $brace = new_ok( 'PPI::Statement::UnmatchedBrace' => [ $token ] );
	is( $brace->content, ')', '->content ok' );
}


_CURLY: {
	my $document = PPI::Document->new(\<<'END_PERL');
use constant { One => 1 };
use constant 1 { One => 1 };
$foo->{bar};
$foo[1]{bar};
$foo{bar};
sub {1};
grep { $_ } 0 .. 2;
map { $_ => 1 } 0 .. 2;
sort { $b <=> $a } 0 .. 2;
do {foo};
$foo = { One => 1 };
$foo ||= { One => 1 };
1, { One => 1 };
One => { Two => 2 };
{foo, bar};
{foo => bar};
{};
+{foo, bar};
{; => bar};
@foo{'bar', 'baz'};
@{$foo}{'bar', 'baz'};
${$foo}{bar};
return { foo => 'bar' };
bless { foo => 'bar' };
$foo &&= { One => 1 };
$foo //= { One => 1 };
$foo //= { 'a' => 1, 'b' => 2 };
0 || { One => 1 };
1 && { One => 1 };
undef // { One => 1 };
$x ? {a=>1} : 1;
$x ? 1 : {a=>1};
$x ? {a=>1} : {b=>1};
END_PERL

	isa_ok( $document, 'PPI::Document' );
	$document->index_locations();

	my @statements;
	foreach my $elem ( @{ $document->find( 'PPI::Statement' ) || [] } ) {
		$statements[ $elem->line_number() - 1 ] ||= $elem;
	}

	is( scalar(@statements), 33, 'Found 33 statements' );

	isa_ok( $statements[0]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[0]);
	isa_ok( $statements[1]->schild(3), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[1]);
	isa_ok( $statements[2]->schild(2), 'PPI::Structure::Subscript',
		'The curly in ' . $statements[2]);
	isa_ok( $statements[3]->schild(2), 'PPI::Structure::Subscript',
		'The curly in ' . $statements[3]);
	isa_ok( $statements[4]->schild(1), 'PPI::Structure::Subscript',
		'The curly in ' . $statements[4]);
	isa_ok( $statements[5]->schild(1), 'PPI::Structure::Block',
		'The curly in ' . $statements[5]);
	isa_ok( $statements[6]->schild(1), 'PPI::Structure::Block',
		'The curly in ' . $statements[6]);
	isa_ok( $statements[7]->schild(1), 'PPI::Structure::Block',
		'The curly in ' . $statements[7]);
	isa_ok( $statements[8]->schild(1), 'PPI::Structure::Block',
		'The curly in ' . $statements[8]);
	isa_ok( $statements[9]->schild(1), 'PPI::Structure::Block',
		'The curly in ' . $statements[9]);
	isa_ok( $statements[10]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[10]);
	isa_ok( $statements[11]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[11]);
	isa_ok( $statements[12]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[12]);
	isa_ok( $statements[13]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[13]);
	isa_ok( $statements[14]->schild(0), 'PPI::Structure::Block',
		'The curly in ' . $statements[14]);
	isa_ok( $statements[15]->schild(0), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[15]);
	isa_ok( $statements[16]->schild(0), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[16]);
	isa_ok( $statements[17]->schild(1), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[17]);
	isa_ok( $statements[18]->schild(0), 'PPI::Structure::Block',
		'The curly in ' . $statements[18]);
	isa_ok( $statements[19]->schild(1), 'PPI::Structure::Subscript',
		'The curly in ' . $statements[19]);
	isa_ok( $statements[20]->schild(2), 'PPI::Structure::Subscript',
		'The curly in ' . $statements[20]);
	isa_ok( $statements[21]->schild(2), 'PPI::Structure::Subscript',
		'The curly in ' . $statements[21]);
	isa_ok( $statements[22]->schild(1), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[22]);
	isa_ok( $statements[23]->schild(1), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[23]);
	isa_ok( $statements[24]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[24]);
	isa_ok( $statements[25]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[25]);
	isa_ok( $statements[26]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[26]);

	isa_ok( $statements[27]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[27]);
	isa_ok( $statements[28]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[28]);
	isa_ok( $statements[29]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[29]);
	isa_ok( $statements[30]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[30]);
	isa_ok( $statements[31]->schild(4), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[31]);

	# Check two things in the same statement
	isa_ok( $statements[32]->schild(2), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[32]);
	isa_ok( $statements[32]->schild(4), 'PPI::Structure::Constructor',
		'The curly in ' . $statements[32]);
}


LEX_STRUCTURE: {
	# Validate the creation of a null statement
	SCOPE: {
		my $token = new_ok( 'PPI::Token::Structure' => [ ';' ] );
		my $null  = new_ok( 'PPI::Statement::Null'  => [ $token ] );
		is( $null->content, ';', '->content ok' );
	}

	# Validate the creation of an empty statement
	new_ok( 'PPI::Statement' => [ ] );
}
