package    #
  DepReqs;

use 5.010;
use strictures 2;

use Test::DependentModules;
use IO::All;
use MetaCPAN::Client;
use List::Util 'uniqstr';
use Devel::Confess;
use Safe::Isa '$_call_if_object';

1;

__PACKAGE__->run unless caller;

sub exclusions {
	qr@^(
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
        |Test2-Plugin-DBBreak|Catalyst-View-EmbeddedPerl-PerRequest-ValiantRole
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
        # https://github.com/Perceptyx/perl-opentracing-roles/issues/8
        |OpenTracing-AutoScope
        # i'd rather spend the time on more broad users
        |Dist-Zilla-PluginBundle-.*|Task-.*|Acme-.*
        # requires modules that fail to install via cpm
        |Bundle-BDFOY|CHI-Driver-MongoDB|Mail-SpamAssassin|MyCPAN-Indexer
        |Net-API-Stripe-WebHook-Apache|Bencher-Scenario-Serializers|Bio-RNA-RNAaliSplit
        |Kafka|Mail-Milter-Authentication|Provision-Unix|Graphics-GVG-OpenGLRenderer
        |MarpaX-Demo-StringParser|MarpaX-Languages-Dash|App-depak Bio-ViennaNGS
        |Dist-Zilla-App-Command-Authordebs|Hyper-Developer|NIST-NVD-Store-SQLite3
        |WWW-AdventCalendar|App-depak|Bio-ViennaNGS|Dist-Zilla-Plugin-Manifest-Write
        |Game-Asset-GVG-OpenGL|Perl-PrereqScanner-Scanner-Hint
        # requires modules that don't resolve
        |Dist-Zilla-PluginBundle-Author-VDB
        # fail on master
        | Dallycot | Devel-Trepan | Devel-Trepan-Disassemble | Dist-Zilla-MintingProfile-FB11
        | Dist-Zilla-Plugin-ChangelogFromGit-CPAN-Changes | Dist-Zilla-Plugin-DistBuild
        | Dist-Zilla-Plugin-MakeMaker-IncShareDir | Dist-Zilla-Plugin-Prereqs-From-cpmfile
        | Farabi | GraphViz2-Marpa | GraphViz2-Marpa-PathUtils | Graphics-GVG-SVG
        | Kafka-Producer-Avro | MarpaX-Languages-PowerBuilder | Net-Async-OpenExchRates
        | Perl-Critic-Policy-PreferredModules | Pg-Corruption | PowerBuilder-DataWindow
        | Test-Kwalitee-Extra | Test-Legal | Test-Perl-Metrics-Simple
        # https://github.com/uperl/Perl-Critic-Plicease/pull/9
        | Perl-Critic-Plicease
    )$@x
}

sub cpm_install_fails {
	qr@^(
        Apache2::Const | AptPkg::Cache | AptPkg::Config | BSON::XS | Code::Splice
        | Config::ApacheFile | Data::Dump::Steamer | Devel::MyDebugger
        | Dist::Zilla::Plugin::Test::NewVersion | Git::Github::Creator | Hook::Lex::Wrap
        | JSON::Parser::Regexp | JSON::Rabbit | MacOSX::Alias | Module::NotThere
        | Mojo::Promise::Rile::HigherOrder | NicTool | Parse::DebianChangelog | PathTools
        | PeGS::PDF | Perl::Critic::DEVELOPER | Pod::Simple::Subclassing | Proc::ProcessTable
        | RNA | Razor2::Client::Agent | Some::Module | Tie::File::Timestamp | WordPress::Grep
        | die | perlbench | ptkdb | require | GraphViz2 | Bio::DB::Sam | File::LibMagic
        | OpenGL | Perl::Squish | Text::VimColor | DhMakePerl::Utils | HTTP::Server::Simple::Static
        | Pod::Elemental::Transformer::VimHTML | Dist::Zilla::PluginBundle::Author::VDB
        | Graphics::GVG::OpenGLRenderer
    )$@x
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

	{ no warnings 'redefine'; *MetaCPAN::Client::fetch = $old_fetch; }

	my $c = MetaCPAN::Client->new;

	my @deps = _resolve_reverse_dependencies( PPI => 10, exclusions(), $c );

	say "writing dependents file";
	io( -e "xt" ? "xt/dependents" : "dependents" )->print( join "\n", @deps );

	say "getting modules to pre-install";
	my $cpm_fails = cpm_install_fails;
	my @reqs;
	my @skip;
	for my $dependent (@deps) {
		say $dependent;
		my @dep_reqs = map @{ $c->release($_)->dependency }, $dependent;
		my @fails =    #
		  map $_->{module}, grep $_->{module} =~ $cpm_fails, @dep_reqs;
		if (@fails) {
			push @skip, $dependent;
			say "skipping dependent $dependent because "
			  . "it requires modules that fail to install: @fails";
			next;
		}
		push @reqs, @dep_reqs;
	}
	say "skipping dependents because "
	  . "they requires modules that fail to install: @skip"
	  if @skip;

	say "writing dependency pre-install file";
	io("xt/cpanfile")
	  ->print( join "\n",
		uniqstr map qq[requires "$_->{module}" => "$_->{version}";], @reqs );

	say "debug printing file";
	say io("xt/cpanfile")->all;

	# test early that all modules don't have an author that crashes tests later
	# !!! careful, this changes CWD !!!
	say "testing dists for author names";
	Test::DependentModules::_load_cpan;
	for my $name (@deps) {
		say $name;
		my $mod = $name;
		$mod =~ s/-/::/g;
		next unless    #
		  my $dist = Test::DependentModules::_get_distro($mod);
		$dist->author->id;
	}

	say "done";
}

sub _resolve_reverse_dependencies {
	my ( $base_dist, $depth, $exclude, $c ) = @_;

	my ( @work, %deps, %seen ) = ($base_dist);

	for my $level ( 1 .. $depth ) {
		say "resolving level: $level";
		for my $dist (@work) {
			my $deps = $c->rev_deps($dist);

			while ( my $dist = $deps->next->$_call_if_object("distribution") ) {
				next if $seen{$dist}++;
				next if $exclude and $dist =~ $exclude;
				$deps{$level}{$dist} = 1;
			}
		}

		@work = sort keys %{ $deps{$level} };
	}

	my @deps = uniqstr map keys %{$_}, values %deps;
	return sort @deps;
}
