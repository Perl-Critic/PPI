#!/usr/bin/perl

# PPI doesn't know about signatures, but we just want to ensure that it doesn't
# lose newlines when it tracks the content of the token.

use strict;
use warnings;

use PPI::Document ();
use Test::More;

use lib 't/lib';
use Helper 'safe_new';

my $sigs = <<'EOF';
use strict;
use warnings;

use feature qw(signatures);
no warnings qw(experimental::signatures);

sub foo (
    $self, $bar,
    $thing_id = 12
) {
    1;
}

sub bar ($self,$bar,%) {
    2;
}

sub baz (


    $, $bar,

    $thing_id = 12,

    @


) {
    1;
}

sub other ( $= ) { }

sub default ( $default = foo() ) { }

EOF

my $doc = safe_new \$sigs;
$doc->serialize;
is( $doc->content, $sigs, 'whitespace in signatures is preserved' );

done_testing();
