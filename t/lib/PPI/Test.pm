package PPI::Test;

use warnings;
use strict;

use vars qw{$VERSION @ISA @EXPORT_OK %EXPORT_TAGS};
BEGIN {
	$VERSION   = '1.220';
	@ISA       = 'Exporter';
	%EXPORT_TAGS = (
		'cmp' => [ qw(
			cmp_document cmp_sdocument
			cmp_statement cmp_sstatement
			cmp_element cmp_selement
		) ]
	);
	@EXPORT_OK = ( map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS );
}

use Exporter ();
use List::MoreUtils ();
use List::Util ();
use Scalar::Util qw( blessed );
use Test::More;

=pod

=head1 NAME

PPI::Test - stuff to help with testing PPI

=head1 TEST FUNCTIONS

=head2 cmp_document( $code, \@expected [, $msg ] )

=head2 cmp_sdocument( $code, \@expected [, $msg ] )

Parses C<code> into a new PPI::Document and checks the resulting
elements one by one against C<expected>, failing the test if the
two do not compare correctly.

The variant C<cmp_sdocument> ignores insignificant elements in the
document so that you can omit them from C<expected>.

Each element of C<expected> is a hashref whose keys describe how to
compare it to the corresponding element from the parse.
Hash keys supported:

=over 4

=item class

The value of C<class> is compared to the parsed element's class.

=item isa

The value of C<isa> is passed to an isa call on parsed element.

=item name of any method on the parsed PPI element:

Any hash key not otherwise documented is used as a method name on the
parsed element; the results of the method call must match the hash key's
value.  If the element being compared does not have that method, the test
will fail.

=item FUNC

The value for this attribute is a sub that accepts the parsed element
as its argument, along with a test description. Execute as many tests
on anything you like in the sub.  E.g.:

 FUNC => sub {
     my ( $elem, $msg ) = @_;
     is_deeply( [$elem->foo()], [1, 2, 3], "$msg: testing foo" );
 }

The return value of the sub is ignored.

=item STOP

When the key STOP appears with a true value in C<expected>,
comparison stops after that hash has been compared.

=back

The return is true for a successful test, false otherwise.

=cut

sub cmp_document {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_document( $code, $expected, $msg, 0 );
}

sub cmp_sdocument {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_document( $code, $expected, $msg, 1 );
}

sub _cmp_document {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	my $significant_only = shift;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	$msg = 'cmp_document: ' . (defined $msg ? $msg : $code);

	return subtest $msg => sub {
		my $doc = PPI::Document->new( \$code );

		my $parsed = _as_array( $doc, { significant_only => $significant_only } );

		my $iterator = List::MoreUtils::each_arrayref( $parsed, $expected );
		my $index = 0;
		my $dump = 0;
		while ( my ($elem, $want) = $iterator->() ) {
			my $indexmsg = "[$index]:";
			if ( !defined $want ) {
				$dump = !fail( "$indexmsg ran out of expected results for parsed element " . ref($elem) ) || $dump;
				last;
			}
			if ( !defined $elem ) {
				$dump = !fail( "$indexmsg ran out of parsed elements for expected result " . _hash_to_str($want) ) || $dump;
				last;
			}
			$dump = !ok( blessed $elem, "$indexmsg parsed element is an object" ) || $dump;

			if ( exists $want->{class} ) {
				$dump = !is( ref($elem), $want->{class}, "$indexmsg class matches" ) || $dump;
			}
			if ( exists $want->{isa} ) {
				$dump = !isa_ok( $elem, $want->{isa}, "$indexmsg class " . ref($elem) . " isa $want->{isa}" ) || $dump;
			}
			foreach my $key ( keys %$want ) {
				next if $key eq 'class' || $key eq 'isa' || $key eq 'STOP';
				if ( $elem->can($key) ) {
					my $val = $elem->$key;
					$dump = !is( $val, $want->{$key}, "$indexmsg $key matches" ) || $dump;
				}
				elsif ( $key eq 'FUNC' ) {
					# Execute the caller's function, ignoring the return.
					$want->{$key}->( $elem, "$indexmsg arbitrary tests" );
				}
				else {
					$dump = !fail( "$indexmsg no method $key on object of type " . ref($elem) ) || $dump;
				}
			}

			last if $dump;
			last if $want->{STOP};

			++$index;
		}

		if ( $dump ) {
			_report_side_by_side( $parsed, $expected, $index );
		}
	};
}


sub _report_side_by_side {
	my $parsed = shift;
	my $expected = shift;
	my $offending_index = shift;

	my $both_maxidx = List::Util::max( scalar(@$parsed)-1, scalar(@$expected)-1 ); 
	my $first_index = List::Util::max( $offending_index-4, 0 );
	my $last_index = List::Util::min( $offending_index+1, $both_maxidx );

	my @parsed_descriptions = map { defined $parsed->[$_] ? ref $parsed->[$_] : '' } ( $first_index .. $last_index );
	my @expected_descriptions = map { defined $expected->[$_] ? _hash_to_str($expected->[$_]) : '' } ( $first_index .. $last_index );

	my $parsed_max_len = List::Util::max map { length($_) } @parsed_descriptions;
	my $expected_max_len = List::Util::max map { length($_) } @expected_descriptions;
	my $last_index_len = length( $last_index );
	my @output;
	for my $i ( $first_index .. $last_index ) {
		push @output,
			sprintf(
				'%s [%*d] %-*s   %-*s %s',
				($i == $offending_index ? '>>>' : '   '),
				$last_index_len, $i,
				$parsed_max_len, $parsed_descriptions[$i - $first_index],
				$expected_max_len, $expected_descriptions[$i - $first_index],
				($i == $offending_index ? '<<<' : '   '),
			);
	}
	diag join( "\n", '', @output );

	return;
}


=pod

=head2 cmp_statement( $code, \@expected [, $msg ] )

=head2 cmp_statement( $code, \%expected [, $msg ] )

=head2 cmp_sstatement( $code, \@expected [, $msg ] )

=head2 cmp_sstatement( $code, \%expected [, $msg ] )

A convenience function that behaves like C<cmp_document>, except that
you don't have to have a C<PPI::Document> element at the beginning of
C<expected>.

The variant C<cmp_sstatement> ignores insignificant elements in the
document so that you can omit them from C<expected>.

C<expected> can be passed as a hashref if you have only one element to
compare.

The return is true for a successful test, false otherwise.

=cut

sub cmp_statement {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_statement( $code, $expected, $msg, 0 );
}

sub cmp_sstatement {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_statement( $code, $expected, $msg, 1 );
}


sub _cmp_statement {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	my $significant_only = shift;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	$expected = [ $expected ] if ref( $expected ) ne 'ARRAY';
	$expected = [ { class => 'PPI::Document' }, @$expected ];

	return _cmp_document( $code, $expected, $significant_only );
}


=pod

=head2 cmp_element( $code, \%expected [, $msg ] )

=head2 cmp_element( $code, \@expected [, $msg ] )

=head2 cmp_selement( $code, \%expected [, $msg ] )

=head2 cmp_selement( $code, \@expected [, $msg ] )

A convenience function that behaves like C<cmp_document>, except that
C<expected> is a single hashref. The parsed document's initial
C<PPI::Document> and C<PPI::Statement> are ignored, and comparison
begins with the element following the statement.

You can also pass a listref of hashes for C<expected>, in which case
all elements in C<expected> must match.

The variant C<cmp_selement> ignores insignificant elements in the
document so that you can omit them from C<expected>.

The return is true for a successful test, false otherwise.

=cut

sub cmp_element {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_element( $code, $expected, $msg, 0 );
}

sub cmp_selement {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_element( $code, $expected, $msg, 1 );
}

sub _cmp_element {
	my $code = shift;
	my $expected = shift;
	my $msg = shift;
	my $significant_only = shift;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	$expected = [ $expected ] if ref( $expected ) ne 'ARRAY';
	$expected = [ { class => 'PPI::Document' }, { isa => 'PPI::Statement' }, @$expected ];

	return _cmp_document( $code, $expected, $msg, $significant_only );
}


sub _as_array {
	my $elem    = shift;
	my $opts    = shift;
	my $output  = shift || [];

	if ( !$opts->{significant_only} || $elem->significant ) {
		push @$output, $elem;
	}

	# Recurse into our children
	foreach my $child ( @{$elem->{children}} ) {
		_as_array( $child, $opts, $output );
	}

	return $output;
}


sub _hash_to_str {
	my $hash = shift;
	my $str = '{ ' . join(', ', map { "$_ => $hash->{$_}" } keys %$hash) . ' }';
	return $str;
}


1;
