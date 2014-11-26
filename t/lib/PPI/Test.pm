package t::lib::PPI::Test;

use warnings;
use strict;

use vars qw{$VERSION @ISA @EXPORT_OK %EXPORT_TAGS};
BEGIN {
	$VERSION = '1.220';
	@ISA = 'Exporter';
	@EXPORT_OK = qw( pause );
}


sub pause {
	local $@;
	sleep 1 if !eval { require Time::HiRes; Time::HiRes::sleep(0.1); 1 };
}


1;
