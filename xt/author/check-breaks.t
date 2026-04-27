use strict;
use warnings;

use Test::More 0.88;

use CPAN::Meta 2.120900;

SKIP: {
    skip 'no META.json in source tree (requires dzil build)', 1
      if not -f 'META.json';

    my $meta = CPAN::Meta->load_file('META.json');
    my $breaks = $meta->custom('x_breaks') || {};

    ok( exists $breaks->{'Perl::Critic'},
        'x_breaks declares Perl::Critic < 1.122 (incompatible with PPI >= 1.218 operator token changes)'
    );
}

done_testing;
