use strict; use warnings;

    use Cpanel::JSON::XS 4.19 qw(decode_json);
use Test::Script 1.27 qw(script_compiles script_runs script_stderr_is script_stderr_like);
use Getopt::Long 2.40 qw();

my $foo = encode_json( { foo => 'bar' } );
my @foo = GetOptions();

script_compiles();
script_runs();
script_stderr_is();
script_stderr_like();
