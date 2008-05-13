use inc::Module::Install;

all_from      'lib/PPI.pm';
requires      'Clone'           => '0.25';
requires      'List::Util'      => '1.19';
requires      'List::MoreUtils' => '0.16';
requires      'Params::Util'    => '0.21';
requires      'IO::String'      => '1.07';

# Modules needed for PPI::Cache
requires      'Digest::MD5'     => '2.27';
requires      'Storable'        => '2.14';

# Test-time dependencies (include as many as we can)
test_requires 'Test::More'      => '0.47';
test_requires 'Test::Object'    => '0.07';
test_requires 'Test::ClassAPI'  => '1.03';
test_requires 'Test::SubCalls'  => '1.07';
test_requires 'File::Spec'      => '0.84';
test_requires 'File::Remove'    => '0.39';
include       'Test::Object';
include       'Test::ClassAPI';
include       'Test::SubCalls';
include       'File::Remove';
include       'Class::Inspector';
include       'Config::Tiny';
include       'Hook::LexWrap';

# Force the existance of the weaken function
# (which some distributions annoyingly don't have)
requires      'Task::Weaken';

# Maintainers should probably also install this
# so that they can regenerate the inline tests
# test_requires 'Test::Inline' => '2.203';

WriteAll;
