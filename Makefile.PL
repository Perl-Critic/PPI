use strict;
use warnings;

use lib '.';
use inc::Module::Install 1.10;

all_from 'lib/PPI.pm';

# This code is only needed by author to generate README and README.md
eval {
	eval "use Module::Install::ReadmeFromPod 0.22";
	eval "use Pod::Markdown 2.002";

	my $pod = 'lib/PPI.pm';
	readme_from( $pod, { clean => 1 } );    # Module::Install::ReadmeFromPod

	my $parser = Pod::Markdown->new;
	open my $in,  "<", $pod;
	binmode $in;
	open my $out, ">", "README.md";
	binmode $out;
	if ($parser and $in and $out) {
		$parser->parse_from_filehandle($in);
		print $out $parser->as_markdown;
	}
};

requires 'Clone'           => '0.30';
requires 'File::Spec'      => win32() ? '3.2701' : '0.84';
requires 'IO::String'      => '1.07';
requires 'List::MoreUtils' => '0.16';
requires 'List::Util'      => '1.33';
requires 'Params::Util'    => '1.00';

# Modules needed for PPI::Cache
requires 'Digest::MD5' => '2.35';
requires 'Storable'    => '2.17';

# Test-time dependencies (bundle as many as we can)
test_requires 'Class::Inspector' => '1.22';
test_requires 'File::Remove'     => '1.42';
test_requires 'Test::More'       => '0.86';
test_requires 'Test::Warn'       => '0.30';
test_requires 'Test::Object'     => '0.07';
test_requires 'Test::SubCalls'   => '1.07';
test_requires 'Test::Deep';

# Force the existence of the weaken function
# (which some distributions annoyingly don't have)
requires 'Task::Weaken';

homepage   'https://github.com/adamkennedy/PPI';
bugtracker 'https://github.com/adamkennedy/PPI/issues';
repository 'https://github.com/adamkennedy/PPI';

no_index 'directory' => qw{ inc t xt };

WriteAll;
