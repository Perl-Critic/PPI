package t::lib::PPI::Test::Cmp;

use warnings;
use strict;

use Exporter ();
use List::Util ();
use PPI;
use Scalar::Util qw( blessed );
use Test::More;

use vars qw{$VERSION @ISA @EXPORT @EXPORT_OK};
BEGIN {
	$VERSION = '1.220';
	@ISA = 'Exporter';
	@EXPORT = qw(
		cmp_document cmp_sdocument
		cmp_statement cmp_sstatement
		cmp_element cmp_selement
	);
	@EXPORT_OK = @EXPORT;
}

use constant CMP_CONTEXT_BEFORE => 4;
use constant CMP_CONTEXT_AFTER => 2;


=pod

=head1 NAME

t::lib::PPI::Test::Cmp - check the results of parsing code snippets

=head1 TEST FUNCTIONS

=head2 cmp_document( $code, \@expected [, $msg ] )

Parses C<code> into a new PPI::Document and checks the resulting
elements one by one against C<expected>, failing the test if the
two do not compare correctly.

Each element of C<expected> is a hashref whose keys describe how to
compare it to the corresponding element from the parse.
Keys supported:

=over 4

=item class

The value of C<class> is compared to the parsed element's class.

=item isa

The value of C<isa> is passed to an isa call on parsed element.

=item name of any method on the parsed PPI element:

Any key not otherwise documented is used as a method name on the
parsed element.  The results of the method call must match the key's
value.  If the element being compared does not have that method, the test
will fail.

=item string containing '::' plus a scalar

Because it can be tedious to check a parsed element for just class and
content, instead of:

 { class => 'PPI::Foo', content => 'bar' }

keys that look like class names are special-cased so you can write:

 { PPI::Foo => 'bar' }

=item FUNC

The value for this key is a sub that accepts the parsed element
as its argument, along with a test description. Execute as many tests
on anything you like in the sub.  E.g.:

 FUNC => sub {
     my ( $elem, $msg ) = @_;
     is_deeply( [$elem->foo()], [1, 2, 3], "$msg: testing foo" );
 }

The return value of the sub is ignored.

=item STOP

When the key STOP has a true value, the test stops after all the other
keys in that hash has been processed.

=item NODESCEND

When the key NODESCEND has a true value,
no children of the parsed element will be visited.
The children must therefore not appear in C<expected>.

=back

The return is true for a successful test, false otherwise.

=head2 cmp_sdocument( $code, \@expected [, $msg ] )

The variant C<cmp_sdocument> ignores insignificant elements in C<expected>.

=cut

sub cmp_document {
	my ( $code, $expected, $msg ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_document( $code, $expected, $msg, 0 );
}

sub cmp_sdocument {
	my ( $code, $expected, $msg ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_document( $code, $expected, $msg, 1 );
}

sub _cmp_document {
	my ( $code, $expected, $msg, $significant_only ) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	$msg = 'cmp_document: ' . (defined $msg ? $msg : $code);

	return subtest $msg => sub {
		local $Test::Builder::Level = $Test::Builder::Level + 1;

		my $doc = PPI::Document->new( \$code );

		my $index = -1;
		my $failed_at = -1;
		my $stopped_at = -1;
		my $state = {
			significant_only => $significant_only,
			extracted =>  [],           # list of elements extracted from $doc so far
			expected =>   $expected,    # complete list of expected results
			indexref =>   \$index,      # reference to current index in 'expected'/'extracted'
			failed_at =>  \$failed_at,  # reference to first failure point in 'extracted'/'extracted'
			stopped_at => \$stopped_at, # whether extraction should stop
		};
		__cmp( $doc, $state );
		my $num_extracted = scalar( @{ $state->{extracted} } );
		if ( $stopped_at < 0 && $failed_at < 0 && $num_extracted < scalar(@$expected) ) {
			fail( "[$num_extracted]: ran out of parsed elements" );
			$failed_at = $num_extracted;
		}
		if ( $failed_at >= 0 ) {
			_report_side_by_side( $state->{extracted}, $expected, ${ $state->{failed_at} } );
		}
	};
}

# "Extract" more elements from the document until the 'stopped_at' flag is set.
sub __cmp {
	my ( $elem, $state ) = @_;

	return if $state->{significant_only} && !$elem->significant;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	# Consider $elem to have been extracted.
	my $index = ++${ $state->{indexref} };
	my $indexmsg = "[$index]:";
	push @{ $state->{extracted} }, $elem;

	my $nodescend;

	if ( $index < scalar(@{$state->{expected}}) ) {
		my $want = $state->{expected}->[ $index ];
		$nodescend = 1 if $want->{NODESCEND};

		my $failed;

		if ( exists $want->{class} ) {
			$failed ||= !is( ref($elem), $want->{class}, "$indexmsg class matches" );
		}
		if ( exists $want->{isa} ) {
			$failed ||= !isa_ok( $elem, $want->{isa}, "$indexmsg class " . ref($elem) );
		}
		foreach my $key ( keys %$want ) {
			next if $key eq 'class' || $key eq 'isa' || $key eq 'STOP' || $key eq 'NODESCEND';

			if ( $elem->can($key) ) {
				# Test results of method named $key.
				my $val = $elem->$key;
				$failed ||= !is( $val, $want->{$key}, "$indexmsg $key matches" );
			}
			elsif ( $key eq 'FUNC' ) {
				# Execute the caller's function, ignoring the return.
				$want->{$key}->( $elem, "$indexmsg arbitrary tests" );
			}
			elsif ( $key =~ /::/ && !ref $want->{$key} ) {
				# Test key as 'class' and the value as 'content'.
				$failed ||= !isa_ok( $elem, $key, "$indexmsg class " . ref($elem) . " isa $key" );
				$failed ||= !is( $elem->content, $want->{$key}, "$indexmsg content matches" );
			}
			else {
				$failed ||= !fail( "$indexmsg no method $key on object of type " . ref($elem) );
			}
		}
		${ $state->{failed_at} } = $index if $failed && ${ $state->{failed_at} } < 0;
		${ $state->{stopped_at} } = $index if $want->{STOP}; # last thing from $want to check
	}
	elsif ( $index == scalar(@{$state->{expected}}) ) {
		# We just ran out of results, so fail here.
		fail( "$indexmsg ran out of expected results " . ref($elem) );
		${ $state->{failed_at} } = $index if ${ $state->{failed_at} } < 0;
	}

	# Extract and/or compare more elements if we need to.
	# Keep extracting after failures, since we need to display
	# elements after the failed one.
	if ( ${ $state->{stopped_at} } < 0 && !$nodescend ) {
		my $max_extract =
			${ $state->{failed_at} } >= 0
			? ${ $state->{failed_at} } + CMP_CONTEXT_AFTER
			: scalar(@{ $state->{expected} }) + CMP_CONTEXT_AFTER
		;
		if ( $index < $max_extract ) {
			foreach my $child ( $elem->isa('PPI::Structure') ? $elem->elements : $elem->isa('PPI::Node') ? $elem->children : () ) {
				__cmp( $child, $state );
				last if ${ $state->{stopped_at} } >= 0;
			}
		}
		else {
			${ $state->{stopped_at} } = $index;
		}
	}

	return;
}


sub _report_side_by_side {
	my $parsed = shift;
	my $expected = shift;
	my $offending_index = shift;

	my $both_maxidx = List::Util::max( scalar(@$parsed)-1, scalar(@$expected)-1 );
	my $first_index = List::Util::max( $offending_index - CMP_CONTEXT_BEFORE, 0 );
	my $last_index = List::Util::min( $offending_index + CMP_CONTEXT_AFTER, $both_maxidx );

	my @parsed_descriptions = map { defined $parsed->[$_] ? ref $parsed->[$_] : '' } ( $first_index .. $last_index );
	my @expected_descriptions = map { defined $expected->[$_] ? _hash_to_str($expected->[$_]) : '' } ( $first_index .. $last_index );

	my $parsed_max_len = List::Util::max map { length($_) } @parsed_descriptions;
	my $expected_max_len = List::Util::max map { length($_) } @expected_descriptions;
	my $last_index_len = length( $last_index );
	my @output = sprintf( '%s %*s %-*s   %-*s', '   ', $last_index_len+2, '', $parsed_max_len, 'parsed', $expected_max_len, 'expected' );
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
you omit the C<PPI::Document> element at the beginning of C<expected>.

The variant C<cmp_sstatement> ignores insignificant elements in the
document so that you can omit them from C<expected>.

C<expected> can be passed as a hashref if you have only one element to
compare.

The return is true for a successful test, false otherwise.

=cut

sub cmp_statement {
	my ( $code, $expected, $msg ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_statement( $code, $expected, $msg, 0 );
}

sub cmp_sstatement {
	my ( $code, $expected, $msg ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_statement( $code, $expected, $msg, 1 );
}


sub _cmp_statement {
	my ( $code, $expected, $msg, $significant_only ) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	$expected = [ $expected ] if ref( $expected ) ne 'ARRAY';
	$expected = [ { class => 'PPI::Document' }, @$expected ];

	return _cmp_document( $code, $expected, $msg, $significant_only );
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
	my ( $code, $expected, $msg ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_element( $code, $expected, $msg, 0 );
}

sub cmp_selement {
	my ( $code, $expected, $msg ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return _cmp_element( $code, $expected, $msg, 1 );
}

sub _cmp_element {
	my ( $code, $expected, $msg, $significant_only ) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	$expected = [ $expected ] if ref( $expected ) ne 'ARRAY';
	$expected = [ { class => 'PPI::Document' }, { isa => 'PPI::Statement' }, @$expected ];

	return _cmp_document( $code, $expected, $msg, $significant_only );
}


sub _hash_to_str {
	my $hash = shift;
	my $str = '{ ' . join(', ', map { "$_ => " . (defined $hash->{$_} ? $hash->{$_} : 'undef') } keys %$hash) . ' }';
	return $str;
}


1;
