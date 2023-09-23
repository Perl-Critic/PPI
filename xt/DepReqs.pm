package    #
  DepReqs;

use 5.010;
use strictures 2;

use Test::DependentModules;
use IO::All;
use MetaCPAN::Client;
use List::Util 'uniqstr';
use Devel::Confess;

1;

__PACKAGE__->run unless caller;

sub exclusions {
    qr/^(
        # don't remember why i excluded these
        Apache2-SSI|Devel-IPerl|Padre
        # fails tests regarding directory write permissions, probably not PPI
        |Devel-Examine-Subs
        # their dependencies don't even install
        |Devel-ebug-HTTP|Padre-Plugin-ParserTool|Devel-PerlySense|PPI-Tester
        |Acme-ReturnValue|Bot-BasicBot-Pluggable-Module-Gitbot|Pinwheel
        |Dist-Zilla-Plugin-MetaProvides-Package|Dist-Zilla-Plugin-Readme-Brief
        |Apache2-PPI-HTML
        # author parsing issue
        |Spellunker-Perl
        # takes too long
        |RPerl
        # broken on cpan
        |Acme-VarMess|Module-Checkstyle|MooseX-Documenter|Perl-Achievements
        |Perl-Metrics|Ravenel|Test-LocalFunctions|UML-Class-Simple
        # maybe broken on cpan
        |App-Grepl|App-Midgen|App-PRT|Pod-Weaver-Section-SQL
        # investigate
        |Class-Discover|Devel-Decouple|File-PackageIndexer|Perl-Signature
        |Perl-Squish|Perl-ToPerl6|Test-Declare
        # RT 76417
        |Devel-Graph
        # meeds Class::Gomor as dep
        |Metabrik
        # depends on RPerl
        |MLPerl
        # RT 129344
        |Module-AnyEvent-Helper
    )$/x
}

sub force_big_metacpan_fetch {
    ## force metacpan to actually return the whole dependents list
    # https://github.com/metacpan/metacpan-client/issues/122
    my $old_fetch = \&MetaCPAN::Client::fetch;
    my $new_fetch = sub { $old_fetch->( shift, shift . "?size=5000", @_ ) };
    { no warnings 'redefine'; *MetaCPAN::Client::fetch = $new_fetch; }

    return $old_fetch;
}

sub run {
    my $old_fetch = force_big_metacpan_fetch;

    my @deps =
      Test::DependentModules::_get_deps PPI => { exclude => exclusions() };

    { no warnings 'redefine'; *MetaCPAN::Client::fetch = $old_fetch; }

    my $c = MetaCPAN::Client->new;
    my @reqs;
    for my $dependent (@deps) {
        say $dependent;
        my @dep_reqs = map @{ $c->release($_)->dependency }, $dependent;
        say "   $_->{module}" for @dep_reqs;
        push @reqs, @dep_reqs;
    }

    say "writing file";
    io("xt/cpanfile")
      ->print( join "\n",
        uniqstr map qq[requires "$_->{module}" => "$_->{version}";], @reqs );

    say "debug printing file";
    say io("xt/cpanfile")->all;

    # test early that all modules don't have an author that crashes tests later
    # !!! careful, this changes CWD !!!
    Test::DependentModules::_load_cpan;
    for my $name (@deps) {
        my $mod = $name;
        $mod =~ s/-/::/g;
        next unless    #
          my $dist = Test::DependentModules::_get_distro($mod);
        $dist->author->id;
    }

    say "done";
}
