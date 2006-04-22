package PPI::Structure;

# An abstract parent and a set of classes representing structures

use strict;
use base 'PPI::Node';
use Scalar::Util                'refaddr';
use Params::Util                '_INSTANCE';
use PPI::Structure::Block       ();
use PPI::Structure::Condition   ();
use PPI::Structure::Constructor ();
use PPI::Structure::ForLoop     ();
use PPI::Structure::List        ();
use PPI::Structure::Subscript   ();
use PPI::Structure::Unknown     ();

use vars qw{$VERSION *_PARENT};
BEGIN {
	$VERSION = '1.111';
	*_PARENT = *PPI::Element::_PARENT;
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $Token = PPI::Token::__LEXER__opens($_[0]) ? shift : return undef;

	# Create the object
	my $self = bless {
		children => [],
		start    => $Token,
		}, $class;

	# Set the start braces parent link
	Scalar::Util::weaken(
		$_PARENT{refaddr $Token} = $self
		);

	$self;
}

# Hacky method to let the Lexer set the finish token, so it doesn't
# have to import %PPI::Element::_PARENT itself.
sub _set_finish {
	my $self  = shift;

	# Check the Token
	my $Token = ($_[0] and $_[0]->isa('PPI::Token::Structure')) ? shift : return undef;
	$Token->parent and return undef; # Must be a detached token
	($self->start->__LEXER__opposite eq $Token->content) or return undef; # ... that matches the opening token

	# Set the token
	$self->{finish} = $Token;
	$_PARENT{refaddr $Token} = $self;

	1;
}





#####################################################################
# PPI::Structure API methods

sub start  { $_[0]->{start}  }
sub finish { $_[0]->{finish} }

# What general brace type are we
sub braces {
	my $self = $_[0]->{start} ? shift : return undef;
	return { '[' => '[]', '(' => '()', '{' => '{}' }->{ $self->{start}->{content} };
}





#####################################################################
# PPI::Node overloaded methods

# For us, the "elements" concept includes the brace tokens
sub elements {
	my $self = shift;

	if ( wantarray ) {
		# Return a list in array context
		return ( $self->{start} || (), @{$self->{children}}, $self->{finish} || () );
	} else {
		# Return the number of elements in scalar context.
		# This is memory-cheaper than creating another big array
		return scalar(@{$self->{children}})
			+ ($self->{start} ? 1 : 0)
			+ ($self->{start} ? 1 : 0);
	}
}

# For us, the first element is probably the opening brace
sub first_element {
	# Technically, if we have no children and no opening brace,
	# then the first element is the closing brace.
	$_[0]->{start} or $_[0]->{children}->[0] or $_[0]->{finish};
}

# For us, the last element is probably the closing brace
sub last_element {
	# Technically, if we have no children and no closing brace,
	# then the last element is the opening brace
	$_[0]->{finish} or $_[0]->{children}->[-1] or $_[0]->{start};
}





#####################################################################
# PPI::Element overloaded methods

# Get the full set of tokens, including start and finish
sub tokens {
	my $self = shift;
	my @tokens = (
		$self->{start}  || (),
		$self->SUPER::tokens(@_),
		$self->{finish} || (),
		);
	@tokens;
}

# Like the token method ->content, get our merged contents.
# This will recurse downwards through everything
### Reimplement this using List::Utils stuff
sub content {
	my $self = shift;
	my $content = $self->{start} ? $self->{start}->content : '';
	foreach my $child ( @{$self->{children}} ) {
		$content .= $child->content;
	}
	$content .= $self->{finish}->content if $self->{finish};
	$content;
}

# You can insert either another structure, or a token
sub insert_before {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	if ( $Element->isa('PPI::Structure') ) {
		return $self->__insert_before($Element);
	} elsif ( $Element->isa('PPI::Token') ) {
		return $self->__insert_before($Element);
	}
	'';
}

# As above, you can insert either another structure, or a token
sub insert_after {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	if ( $Element->isa('PPI::Structure') ) {
		return $self->__insert_after($Element);
	} elsif ( $Element->isa('PPI::Token') ) {
		return $self->__insert_after($Element);
	}
	'';
}

1;
