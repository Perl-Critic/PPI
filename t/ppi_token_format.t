#!/usr/bin/perl

# Unit testing for PPI::Token::Format

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 4;

use PPI;


use lib 't/lib';
use Helper 'check_with';

my $Document = PPI::Document->new(\<<'END_PERL');
#!/usr/bin/env perl
use strict;

format BYDEPTH_TOP =
Top disk utilization in @*, @* level(s) deep
                        $BASEPATH, $DEPTH
================================================================================

subpath                                                         disk utilization
-------                                                         ----------------
.

__END__

=head1 SYNOPSIS

  ⋮
  -d, --depth DEPTH[,...]  displays disk usage DEPTH levels into hierarchy
                           (default: 2); separate multiple DEPTHs with commas
  --[no-]by-depth          [suppresses] displays usage by depth in hierarchy
  -q, --[no-]quiet         suppress progress messages (implied for '-r')
  FILE                     is the output of a previous 'find DIR -printf ...'
                           invocation, as described below; use '-' for stdin

=cut
END_PERL

isa_ok( $Document, 'PPI::Document' );
my $formats = $Document->find('Token::Format');
is( scalar @{$formats}, 1, 'Found the 1 format' );

my $uses = $Document->find('Statement::Include');
is( scalar @{$uses}, 1, 'Found the 1 include' );

my $pods = $Document->find('Token::Pod');
is( scalar @{$pods}, 1, 'Found the 1 pod section' );

