#!/usr/bin/perl

# Unit testing for PPI::Token::Prototype

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 120 + ( $ENV{AUTHOR_TESTING} ? 1 : 0 );

use PPI ();
use Helper 'safe_new';

sub check;
sub check_w_subs;

PARSING: {
	my @sub_patterns;
	for my $block ( '{1;}', ';' ) {
		push @sub_patterns,    #
		  map [ $_, $block ], 'sub foo', 'sub', 'sub AUTOLOAD', 'sub DESTROY';
	}
	check_w_subs \@sub_patterns, '',           '',           '';
	check_w_subs \@sub_patterns, '()',         '()',         '';
	check_w_subs \@sub_patterns, '( )',        '( )',        '';
	check_w_subs \@sub_patterns, ' () ',       '()',         '';
	check_w_subs \@sub_patterns, '(+@)',       '(+@)',       '+@';
	check_w_subs \@sub_patterns, ' (+@) ',     '(+@)',       '+@';
	check_w_subs \@sub_patterns, '(\[$;$_@])', '(\[$;$_@])', '\[$;$_@]';
	check_w_subs \@sub_patterns, '(\ [ $ ])',  '(\ [ $ ])',  '\[$]';
	## nonsense, but perl accepts it
	check_w_subs \@sub_patterns, '(\\\ [ $ ])', '(\\\ [ $ ])', '\\\[$]';
	check_w_subs \@sub_patterns, '($ _ %)',     '($ _ %)',     '$_%';
	## invalid chars in prototype
	check_w_subs \@sub_patterns, '( Z)', '( Z)', 'Z';
	## invalid chars in prototype
	check_w_subs \@sub_patterns, '(!-=|)', '(!-=|)', '!-=|';
	## perl refuses to compile this
	check_w_subs \@sub_patterns, '(()', '(()', '(', 1;
	check_w_subs \@sub_patterns, '((a))', '((a))', '(a)';
	check_w_subs \@sub_patterns,    #
	  "(\n(\na\n)\n)", "(\n(\na\n)\n)", "(a)";
}

sub check_w_subs {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	check @{$_}, @_ for @{ shift() };
	return;
}

sub check {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ( $name, $block, $code_prototype, $expected_content,
		$expected_prototype, $tail )
	  = @_;
	my $desc = my $code = "$name$code_prototype$block";
	$desc =~ s/\n/\\n/g;
	subtest $desc => sub {
		my $document = safe_new \$code;

		my $all_prototypes = $document->find('PPI::Token::Prototype');
		return is $all_prototypes, "", "got no prototypes"
		  if $code_prototype eq '';

		$all_prototypes = [] if !ref $all_prototypes;
		is scalar(@$all_prototypes), 1, "got exactly one prototype";
		my $prototype_obj = $all_prototypes->[0];
		is $prototype_obj, $expected_content . ( $tail ? $block : "" ),
		  "prototype object content matches";
		is $prototype_obj->prototype,
		  $expected_prototype . ( $tail ? ")$block" : "" ),
		  "prototype characters match";
	};
	return;
}
