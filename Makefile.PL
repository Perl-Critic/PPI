use inc::Module::Install;

name           'PPI';
all_from       'lib/PPI.pm';
requires       'Carp'             => 0;
requires       'Clone'            => '0.17';
requires       'List::Util'       => '1.17'; # Should be 1.18 ASAP
requires       'List::MoreUtils'  => '0.13';
requires       'Params::Util'     => '0.10';
requires       'IO::Scalar'       => '2.105';

# Modules needed for PPI::Cache
requires       'Digest::MD5'      => '2.27';
requires       'Storable'         => '2.14';

# Test-time dependencies (include as many as we can)
build_requires 'Test::More'       => '0.47';
build_requires 'Test::ClassAPI'   => '1.02';
build_requires 'Test::SubCalls'   => '0.01';
build_requires 'File::Spec'       => '0.84';
build_requires 'File::Remove'     => '0.22';
include        'Test::ClassAPI';
include        'Test::SubCalls';
include        'File::Remove';
include        'Class::Inspector';
include        'Config::Tiny';
include        'Hook::LexWrap';

auto_install;
WriteAll;
