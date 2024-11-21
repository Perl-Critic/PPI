use Test2::V0;
use strictures 2;

use Test::DependentModules 'test_modules';
use MetaCPAN::Client;
use Devel::Confess;
use IO::All;

use lib '.';

require( -e "xt" ? "xt/DepReqs.pm" : "DepReqs.pm" );

skip_all "ENV var TEST_DEPENDENTS not set" if not $ENV{TEST_DEPENDENTS};

# duplicate error output into an array for later printing
my @error_log;
my $old_log = \&Test::DependentModules::_error_log;
my $new_log = sub { push @error_log, @_; $old_log->(@_); };
{ no warnings 'redefine'; *Test::DependentModules::_error_log = $new_log; }

DepReqs::force_big_metacpan_fetch();

my @deps = split /\n/, io( -e "xt" ? "xt/dependents" : "dependents" )->all;
test_modules @deps;

my $error_log = join "\n", @error_log;
my $fails     = join "\n", $error_log =~ /(FAIL: .*\w+)$/mg;

diag "\n\n---------- ERROR LOG START -----------\n\n",
  @error_log,
  "\n\n---------- FAILS: -----------\n\n",
  $fails,
  "\n\n---------- ERROR LOG END -----------\n\n";

done_testing;
