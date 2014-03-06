#!/usr/bin/perl

# Test compatibility with Storable

use strict;
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}

use Test::More tests => 43;
use Test::NoWarnings;
use File::Spec::Unix;
use File::Spec::Functions ':ALL';
use Scalar::Util  'refaddr';
use File::Remove  ();
use PPI::Document ();
use PPI::Cache    ();

use constant VMS  => !! ( $^O eq 'VMS' );
use constant FILE => VMS ? 'File::Spec::Unix' : 'File::Spec';

my $this_file  = FILE->catdir( 't', 'data', '03_document', 'test.dat' );
my $cache_dir  = FILE->catdir( 't', 'data', '18_cache' );

# Define, create and clear the test cache
File::Remove::remove( \1, $cache_dir ) if -e $cache_dir;
ok( ! -e $cache_dir, 'The cache path does not exist' );
END { File::Remove::remove( \1, $cache_dir ) if -e $cache_dir }
ok( scalar(mkdir $cache_dir), 'mkdir $cache_dir returns true' );
ok( -d $cache_dir, 'Verified the cache path exists' );
ok( -w $cache_dir, 'Can write to the cache path'    );

my $sample_document = \'print "Hello World!\n";';





#####################################################################
# Basic Testing

# Create a basic cache object
my $Cache = PPI::Cache->new(
	path => $cache_dir,
	);
isa_ok( $Cache, 'PPI::Cache' );
is( scalar($Cache->path), $cache_dir, '->path returns the original path'    );
is( scalar($Cache->readonly), '',      '->readonly returns false by default' );

# Create a test document
my $doc = PPI::Document->new( $sample_document );
isa_ok( $doc, 'PPI::Document' );
my $doc_md5  = '64568092e7faba16d99fa04706c46517';
is( $doc->hex_id, $doc_md5, '->hex_id specifically matches the UNIX newline md5' );
my $doc_file = catfile($cache_dir, '6', '64', '64568092e7faba16d99fa04706c46517.ppi');
my $bad_md5  = 'abcdef1234567890abcdef1234567890';
my $bad_file = catfile($cache_dir, 'a', 'ab', 'abcdef1234567890abcdef1234567890.ppi');

# Save to an arbitrary location
ok( $Cache->_store($bad_md5, $doc), '->_store returns true' );
ok( -f $bad_file, 'Created file where expected' );
my $loaded = $Cache->_load($bad_md5);
isa_ok( $loaded, 'PPI::Document' );
is_deeply( $doc, $loaded, '->_load loads the same document back in' );

# Store the test document in the cache in it's proper place
is( scalar( $Cache->store_document($doc) ), 1,
	'->store_document(Document) returns true' );
ok( -f $doc_file, 'The document was stored in the expected location' );

# Check the _md5hex method
is( PPI::Cache->_md5hex($sample_document), $doc_md5,
	'->_md5hex returns as expected for sample document' );
is( PPI::Cache->_md5hex($doc_md5), $doc_md5,
	'->_md5hex null transform works as expected' );
is( $Cache->_md5hex($sample_document), $doc_md5,
	'->_md5hex returns as expected for sample document' );
is( $Cache->_md5hex($doc_md5), $doc_md5,
	'->_md5hex null transform works as expected' );

# Retrieve the Document by content
$loaded = $Cache->get_document( $sample_document );
isa_ok( $loaded, 'PPI::Document' );
is_deeply( $doc, $loaded, '->get_document(\$source) loads the same document back in' );

# Retrieve the Document by md5 directly
$loaded = $Cache->get_document( $doc_md5 );
isa_ok( $loaded, 'PPI::Document' );
is_deeply( $doc, $loaded, '->get_document($md5hex) loads the same document back in' );






#####################################################################
# Empiric Testing

# Load a test document twice, and see how many tokenizer objects get
# created internally.
is( PPI::Document->get_cache, undef,    'PPI::Document cache initially undef' );
ok( PPI::Document->set_cache( $Cache ), 'PPI::Document->set_cache returned true' );
isa_ok( PPI::Document->get_cache, 'PPI::Cache' );
is( refaddr($Cache), refaddr(PPI::Document->get_cache),
	'->get_cache returns the same cache object' );

SKIP: {
	skip("Test::SubCalls requires >= 5.6", 7 ) if $] < 5.006;
	require Test::SubCalls;

	# Set the tracking on the Tokenizer constructor
	ok( Test::SubCalls::sub_track( 'PPI::Tokenizer::new' ), 'Tracking calls to PPI::Tokenizer::new' );
	Test::SubCalls::sub_calls( 'PPI::Tokenizer::new', 0 );
	my $doc1 = PPI::Document->new( $this_file );
	my $doc2 = PPI::Document->new( $this_file );
	isa_ok( $doc1, 'PPI::Document' );
	isa_ok( $doc2, 'PPI::Document' );

	unless ( $doc1 and $doc2 ) {
		skip( "Skipping due to previous failures", 3 );
	}
	Test::SubCalls::sub_calls( 'PPI::Tokenizer::new', 1,
		'Two calls to PPI::Document->new results in one Tokenizer object creation' );
	ok( refaddr($doc1) != refaddr($doc2),
		'PPI::Document->new with cache enabled does NOT return the same object' );
	is_deeply( $doc1, $doc2,
		'PPI::Document->new with cache enabled returns two identical objects' );
}

SKIP: {
	skip("Test::SubCalls requires >= 5.6", 8 ) if $] < 5.006;

	# Done now, can we clear the cache?
	is( PPI::Document->set_cache(undef), 1, '->set_cache(undef) returns true' );
	is( PPI::Document->get_cache, undef,    '->get_cache returns undef' );

	# Next, test the import mechanism
	is( eval "use PPI::Cache path => '$cache_dir'; 1", 1, 'use PPI::Cache path => ...; succeeded' );
	isa_ok( PPI::Document->get_cache, 'PPI::Cache' );
	is( scalar(PPI::Document->get_cache->path), $cache_dir, '->path returns the original path'    );
	is( scalar(PPI::Document->get_cache->readonly), '',      '->readonly returns false by default' );

	# Does it still keep the previously cached documents
	Test::SubCalls::sub_reset( 'PPI::Tokenizer::new' );
	my $doc3 = PPI::Document->new( $this_file );
	isa_ok( $doc3, 'PPI::Document' );
	Test::SubCalls::sub_calls( 'PPI::Tokenizer::new', 0,
		'Tokenizer was not created. Previous cache used ok' );
}

1;
