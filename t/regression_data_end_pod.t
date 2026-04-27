#!/usr/bin/perl

# Regression test for GH #16:
# Pod below __END__ not parsed if __DATA__ section is present

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 12 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI ();
use Helper 'safe_new';

my $code = <<'END_PERL';
my $x = 1;

__DATA__
some data here

__END__

=head1 NAME

After END pod

=cut
END_PERL

my $doc = safe_new \$code;

{
	my $pods = $doc->find('PPI::Token::Pod');
	ok( $pods, 'found Pod tokens' );
	is( scalar @{ $pods || [] }, 1, 'found exactly one Pod section' );
	like( $pods->[0]->content, qr/After END pod/, 'Pod content from after __END__ is present' );

	my $seps = $doc->find('PPI::Token::Separator');
	is( scalar @{ $seps || [] }, 2, 'found two Separator tokens (__DATA__ and __END__)' );

	my $data_tokens = $doc->find('PPI::Token::Data');
	ok( $data_tokens, 'found Data tokens' );
	unlike( $data_tokens->[0]->content, qr/__END__/,
		'Data token does not contain __END__' );
}

is( $doc->serialize, $code, 'round-trip preserves original source' );

my $code2 = <<'END_PERL';
my $x = 1;

__DATA__
__END__

=head1 NAME

Immediate END after DATA

=cut
END_PERL

my $doc2 = safe_new \$code2;
{
	my $pods2 = $doc2->find('PPI::Token::Pod');
	ok( $pods2, 'found Pod when __END__ immediately follows __DATA__' );
}
