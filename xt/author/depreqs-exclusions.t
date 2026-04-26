use strict;
use warnings;
use Test::More;

eval {
    require IO::All;
    require MetaCPAN::Client;
    require Test::DependentModules;
    require Devel::Confess;
    require Safe::Isa;
    1;
} or plan skip_all => "dependents testing prerequisites not installed";

require( -e "xt" ? "xt/DepReqs.pm" : "../DepReqs.pm" );

my $excl = DepReqs::exclusions();

my @should_exclude = (
    'Dist-Zilla-Plugin-Subversion',
);

for my $mod (@should_exclude) {
    like( $mod, $excl, "$mod is excluded from dependents testing" );
}

done_testing;
