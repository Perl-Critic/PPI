use strict;
use warnings;

use inc::Module::Install 1.10;

# need by author to run 'perl Makefile.PL' only
# use Module::Install::ReadmeFromPod 0.22;

name 'PPI';
license 'perl';
perl_version '5.008000';

all_from 'lib/PPI.pm';
readme_from 'lib/PPI.pm';    # Module::Install::ReadmeFromPod

requires 'Class::XSAccessor' => '1.19' if can_xs;
requires 'Clone'             => '0.37';
requires 'File::Path'        => '2.09';
requires 'File::Spec'        => win32() ? '3.2701' : '0.84';
requires 'IO::String'        => '1.08';
requires 'List::Util'        => '1.20';
requires 'List::MoreUtils'   => '0.33';
requires 'Params::Util'      => '1.07';

# Modules needed for PPI::Cache
requires 'Digest::MD5' => '2.35';
requires 'Storable'    => '2.17';

# Test-time dependencies (bundle as many as we can)
test_requires 'Class::Inspector' => '1.28';
test_requires 'File::Remove'     => '1.52';
test_requires 'Test::More'       => '1.001003';
test_requires 'Test::NoWarnings' => '1.04';
test_requires 'Test::Object'     => '0.07';
test_requires 'Test::SubCalls'   => '1.09';

# Force the existence of the weaken function
# (which some distributions annoyingly don't have)
requires 'Task::Weaken';

homepage   'https://github.com/adamkennedy/PPI';
bugtracker 'https://github.com/adamkennedy/PPI/issues';
repository 'https://github.com/adamkennedy/PPI';

no_index 'directory' => qw{ inc t xt };

WriteAll;

