use strict;
use inc::Module::Install;

name           'PPI';
all_from       'lib/PPI.pm';
requires       'Carp'            => 0;
requires       'Clone'           => '0.22';
requires       'List::Util'      => $^O =~ /^(?:MSWin32|cygwin)$/
                                    ? '1.17'
                                    : '1.18';
requires       'List::MoreUtils' => '0.13';
requires       'Params::Util'    => '0.10';
requires       'IO::String'      => '1.07';

# Modules needed for PPI::Cache
requires       'Digest::MD5'     => '2.27';
requires       'Storable'        => '2.14';

# Test-time dependencies (include as many as we can)
build_requires 'Test::More'      => '0.47';
build_requires 'Test::Object'    => '0.07';
build_requires 'Test::ClassAPI'  => '1.03';
build_requires 'Test::SubCalls'  => '1.06';
build_requires 'File::Spec'      => '0.84';
build_requires 'File::Remove'    => '0.34';
include        'Test::Object';
include        'Test::ClassAPI';
include        'Test::SubCalls';
include        'File::Remove';
include        'Class::Inspector';
include        'Config::Tiny';
include        'Hook::LexWrap';

# Force the existance of the weaken function
# (which some distributions annoyingly don't have)
requires       'Task::Weaken';

WriteAll;
