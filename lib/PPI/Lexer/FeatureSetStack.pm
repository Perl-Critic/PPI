package PPI::Lexer::FeatureSetStack;

use strict;
use warnings;

sub new {
	my $class = shift;
	return bless {
		values => [],
	}, $class;
}

sub push_new {
	my ($self, $feats) = @_;
	# quick and dirty parameter validation: dies if $feats is not a hashref
	push @{$self->{values}}, \%$feats;
}

sub current {
	my ($self) = @_;
	return $self->{values}[-1] || {};
}

sub extend_current {
	my ($self, $new_feats) = @_;

	my $current_feats = $self->{values}[-1] || do {
		my $empty = {};
		push @{$self->{values}}, $empty;
		$empty
	};

	# always copy current feats; never modify a feature set on the stack
	return $self->{values}[-1] = { %$current_feats, %$new_feats };
}

sub clone_current {
	my ($self) = @_;
	# this can be a shallow copy because we never modify feature sets on the stack
	push @{$self->{values}}, $self->current;
}

sub pop {
	my ($self) = @_;
	pop @{$self->{values}};
}

1
