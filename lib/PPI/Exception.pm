package PPI::Exception;

use strict;
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.202_01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { }, $class;
	if ( @_ ) {
		$self->{message} = shift;
	} else {
		$self->{message} = 'Unknown Reason';
	}
	$self;
}

sub message {
	$_[0]->{message};
}





#####################################################################
# Main Methods

sub throw {
	my $it = shift;
	unless ( _INSTANCE($it, 'PPI::Exception') ) {
		$it = $it->new( @_ );
	}
	die $it;
}

1;
