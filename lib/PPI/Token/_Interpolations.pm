package PPI::Token::_Interpolations;

=pod

=head1 NAME

PPI::Token::_Interpolations - shared interpolation extraction logic

=head1 DESCRIPTION

This is a private module that provides the interpolation extraction
algorithm used by L<PPI::Token::Quote::Double>,
L<PPI::Token::Quote::Interpolate>, and L<PPI::Token::HereDoc> to
implement the C<interpolated_fragments> method.

=cut

use strict;
use PPI::Document           ();
use PPI::Document::Fragment ();

our $VERSION = '1.292';

sub _interpolated_fragments {
	my ($string) = @_;
	return () unless defined $string and length $string;

	my @raw = _extract($string);
	my @fragments;
	for my $str (@raw) {
		my $frag = PPI::Document->new(\$str);
		next unless $frag;
		bless $frag, 'PPI::Document::Fragment';
		push @fragments, $frag;
	}
	return @fragments;
}

sub _extract {
	my ($string) = @_;
	return () unless defined $string and length $string;

	my @results;
	my $len = length $string;
	my $pos = 0;

	while ($pos < $len) {
		my $char = substr($string, $pos, 1);

		if ($char eq '\\') {
			$pos += 2;
			next;
		}

		if ($char eq '$' or $char eq '@') {
			my $end = _scan_interpolation($string, $pos);
			if (defined $end and $end > $pos + 1) {
				push @results, substr($string, $pos, $end - $pos);
				$pos = $end;
				next;
			}
		}

		$pos++;
	}

	return @results;
}

sub _scan_interpolation {
	my ($string, $start) = @_;
	my $len   = length $string;
	my $sigil = substr($string, $start, 1);
	my $pos   = $start + 1;

	return undef if $pos >= $len;

	my $next = substr($string, $pos, 1);

	# Braced form: ${...} or @{...}
	if ($next eq '{') {
		my $brace_end = _scan_balanced($string, $pos, '{', '}');
		return undef unless defined $brace_end;
		return _scan_subscripts($string, $brace_end);
	}

	# Simple variable: $ident or @ident (with optional namespace)
	if ($next =~ /[a-zA-Z_]/) {
		pos($string) = $pos;
		if ($string =~ /\G([a-zA-Z_]\w*(?:::\w+)*)/gc) {
			return _scan_subscripts($string, pos($string));
		}
	}

	# Scalar-only patterns
	return undef unless $sigil eq '$';

	# $#ident (array last index)
	if ($next eq '#' and $pos + 1 < $len) {
		my $after_hash = $pos + 1;
		if (substr($string, $after_hash, 1) =~ /[a-zA-Z_]/) {
			pos($string) = $after_hash;
			if ($string =~ /\G([a-zA-Z_]\w*(?:::\w+)*)/gc) {
				return pos($string);
			}
		}
	}

	# $N capture variables: $1, $12, $123, etc.
	if ($next =~ /[1-9]/) {
		pos($string) = $pos;
		$string =~ /\G([0-9]+)/gc;
		return pos($string);
	}

	# $$ (process ID)
	return $start + 2 if $next eq '$';

	# $^X style magic variables
	if ($next eq '^' and $pos + 1 < $len and substr($string, $pos + 1, 1) =~ /[A-Z]/) {
		return $start + 3;
	}

	# Single-char magic: $_, $!, $@, $&, etc.
	return $start + 2 if $next =~ /[_!&`'+*.\/|\\";=\-~:?<>#()\[\]0,]/;

	return undef;
}

sub _scan_subscripts {
	my ($string, $pos) = @_;
	my $len = length $string;

	while ($pos < $len) {
		my $char = substr($string, $pos, 1);

		if ($char eq '[') {
			my $end = _scan_balanced($string, $pos, '[', ']');
			return $pos unless defined $end;
			$pos = $end;
			next;
		}

		if ($char eq '{') {
			my $end = _scan_balanced($string, $pos, '{', '}');
			return $pos unless defined $end;
			$pos = $end;
			next;
		}

		# Arrow dereference: ->[...] or ->{...}
		if ($char eq '-' and $pos + 1 < $len and substr($string, $pos + 1, 1) eq '>') {
			my $after_arrow = $pos + 2;
			return $pos if $after_arrow >= $len;
			my $after = substr($string, $after_arrow, 1);
			if ($after eq '[') {
				my $end = _scan_balanced($string, $after_arrow, '[', ']');
				return $pos unless defined $end;
				$pos = $end;
				next;
			}
			if ($after eq '{') {
				my $end = _scan_balanced($string, $after_arrow, '{', '}');
				return $pos unless defined $end;
				$pos = $end;
				next;
			}
			return $pos;
		}

		last;
	}

	return $pos;
}

sub _scan_balanced {
	my ($string, $pos, $open, $close) = @_;
	my $len = length $string;
	return undef if $pos >= $len or substr($string, $pos, 1) ne $open;

	my $depth = 1;
	my $i     = $pos + 1;

	while ($i < $len and $depth > 0) {
		my $char = substr($string, $i, 1);
		if ($char eq '\\') {
			$i += 2;
			next;
		}
		$depth++ if $char eq $open;
		$depth-- if $char eq $close;
		$i++;
	}

	return $depth == 0 ? $i : undef;
}

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
