package Helper;

use strict;
use warnings;

use parent 'Exporter';
use Test::More;
use B 'perlstring';

use PPI::Document ();
use PPI::Dumper   ();

our @EXPORT_OK = qw( check_with  safe_new  test_document  test_statement );

=head1 safe_new @args

	my $doc = safe_new \"use strict";

Creates a PPI::Document object from the arguments and reports errors if
necessary. Can be used to replace most document new calls in the tests for
easier testing.

=cut

sub safe_new {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $Document = PPI::Document->new(@_);
	my $errstr   = PPI::Document->errstr;
	PPI::Document->_clear;
	if ( Test::More->builder->in_todo ) {
		local $TODO = 1;
		fail "no errors";
		fail 'PPI::Document';
		return $Document;
	}
	is( $errstr, '', "no errors" );
	isa_ok $Document, 'PPI::Document';
	return $Document;
}

=head1 check_with

	check_with "1.eqm'bar';", sub {
		is $_->child( 0 )->child( 1 )->content, "eqm'bar",
		  "eqm' bareword after number and concat op is not mistaken for eq";
	};

Creates a document object from the given code and stores it in $_, so the sub
passed in the second argument can quickly run tests on it.

=cut

sub check_with {
	my ( $code, $checker ) = @_;
	local $_ = safe_new \$code;
	return $checker->();
}

=head1 test_document

	test_document(
		'my $x = 1;',
		[ 'PPI::Statement::Variable', 'my $x = 1;', ... ],
		"optional message"
	);

	test_document(
		[ feature_mods => { signatures => 1 } ],
		'sub foo ($x) {}',
		[ ... ],
		"with document options"
	);

Parses the given code into a PPI::Document, extracts all significant elements
(class name and content pairs), and compares against the expected arrayref.

An optional first arrayref argument passes options to PPI::Document->new().

=cut

sub test_document {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $args = ref $_[0] eq "ARRAY" ? shift : [];
	my ( $code, $expected, $msg ) = @_;
	$msg = perlstring $code if !defined $msg;

	my $d = PPI::Document->new( \$code, @{$args} ) or die explain $@;
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref($_), $_->content } @$tokens ];

	my $ok = is_deeply( $tokens, $expected, _main_level_line() . $msg );
	if ( !$ok ) {
		diag ">>> $code -- $msg\n";
		diag( PPI::Dumper->new($d)->string );
		diag _one_line_explain($tokens);
		diag _one_line_explain($expected);
	}

	return;
}

=head1 test_statement

	test_statement(
		'my $x = 1;',
		[
			'PPI::Token::Word'      => 'my',
			'PPI::Token::Symbol'    => '$x',
			'PPI::Token::Operator'  => '=',
			'PPI::Token::Number'    => '1',
			'PPI::Token::Structure' => ';',
		],
		"optional message"
	);

Parses the given code into a PPI::Document, extracts all significant elements
(class name and content pairs), and compares against the expected arrayref.

If the first element of the expected array does not start with
C<PPI::Statement>, the expected array is automatically wrapped with the
statement class and the full code as its content.

=cut

sub test_statement {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ( $code, $expected, $msg ) = @_;
	$msg = perlstring $code if !defined $msg;

	my $d = safe_new \$code;
	my $tokens = $d->find( sub { $_[1]->significant } );
	$tokens = [ map { ref($_), $_->content } @$tokens ];

	if ( $expected->[0] !~ /^PPI::Statement/ ) {
		$expected = [ 'PPI::Statement', $code, @$expected ];
	}
	my $ok = is_deeply( $tokens, $expected, _main_level_line() . $msg );
	if ( !$ok ) {
		diag ">>> $code -- $msg\n";
		diag( PPI::Dumper->new($d)->string );
		diag _one_line_explain($tokens);
		diag _one_line_explain($expected);
	}

	return;
}

sub _one_line_explain {
	my ($data) = @_;
	my @explain = explain $data;
	s/\n//g for @explain;
	return join "", @explain;
}

sub _main_level_line {
	return "" if not $TODO;
	my @outer_final;
	my $level = 0;
	while ( my @outer = caller( $level++ ) ) {
		@outer_final = @outer;
	}
	return "l $outer_final[2] - ";
}

1;
