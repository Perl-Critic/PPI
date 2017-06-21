package Helper;

use base 'Exporter';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.232';
}

@EXPORT_OK = qw( check_with );

sub check_with {
    my ( $code, $checker ) = @_;
    my $Document = PPI::Document->new( \$code );
    is( PPI::Document->errstr, undef ) if PPI::Document->errstr;
    local $_ = $Document;
    $checker->();
}

1;
