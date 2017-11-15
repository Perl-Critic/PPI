package Helper;

use strict;
use warnings;
use Exporter ();

our $VERSION = '1.237_001';

our @ISA = "Exporter";
our @EXPORT_OK = qw( check_with );

sub check_with {
    my ( $code, $checker ) = @_;
    my $Document = PPI::Document->new( \$code );
    is( PPI::Document->errstr, undef ) if PPI::Document->errstr;
    local $_ = $Document;
    $checker->();
}

1;
