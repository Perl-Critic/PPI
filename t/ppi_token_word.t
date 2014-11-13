#!/usr/bin/perl

# Unit testing for PPI::Token::Word

use t::lib::PPI::Test::pragmas;
use Test::More tests => 1756;

use PPI;


LITERAL: {
	my @pairs = (
		"F",        'F',
		"Foo::Bar", 'Foo::Bar',
		"Foo'Bar",  'Foo::Bar',
	);
	while ( @pairs ) {
		my $from  = shift @pairs;
		my $to	= shift @pairs;
		my $doc   = PPI::Document->new( \"$from;" );
		isa_ok( $doc, 'PPI::Document' );
		my $word = $doc->find_first('Token::Word');
		isa_ok( $word, 'PPI::Token::Word' );
		is( $word->literal, $to, "The source $from becomes $to ok" );
	}
}


METHOD_CALL: {
	my $Document = PPI::Document->new(\<<'END_PERL');
indirect $foo;
indirect_class_with_colon Foo::;
$bar->method_with_parentheses;
print SomeClass->method_without_parentheses + 1;
sub_call();
$baz->chained_from->chained_to;
a_first_thing a_middle_thing a_last_thing;
(first_list_element, second_list_element, third_list_element);
first_comma_separated_word, second_comma_separated_word, third_comma_separated_word;
single_bareword_statement;
{ bareword_no_semicolon_end_of_block }
$buz{hash_key};
fat_comma_left_side => $thingy;
END_PERL

	isa_ok( $Document, 'PPI::Document' );
	my $words = $Document->find('Token::Word');
	is( scalar @{$words}, 23, 'Found the 23 test words' );
	my %words = map { $_ => $_ } @{$words};
	is(
		scalar $words{indirect}->method_call,
		undef,
		'Indirect notation is unknown.',
	);
	is(
		scalar $words{indirect_class_with_colon}->method_call,
		1,
		'Indirect notation with following word ending with colons is true.',
	);
	is(
		scalar $words{method_with_parentheses}->method_call,
		1,
		'Method with parentheses is true.',
	);
	is(
		scalar $words{method_without_parentheses}->method_call,
		1,
		'Method without parentheses is true.',
	);
	is(
		scalar $words{print}->method_call,
		undef,
		'Plain print is unknown.',
	);
	is(
		scalar $words{SomeClass}->method_call,
		undef,
		'Class in class method call is unknown.',
	);
	is(
		scalar $words{sub_call}->method_call,
		0,
		'Subroutine call is false.',
	);
	is(
		scalar $words{chained_from}->method_call,
		1,
		'Method that is chained from is true.',
	);
	is(
		scalar $words{chained_to}->method_call,
		1,
		'Method that is chained to is true.',
	);
	is(
		scalar $words{a_first_thing}->method_call,
		undef,
		'First bareword is unknown.',
	);
	is(
		scalar $words{a_middle_thing}->method_call,
		undef,
		'Bareword in the middle is unknown.',
	);
	is(
		scalar $words{a_last_thing}->method_call,
		0,
		'Bareword at the end is false.',
	);
	foreach my $false_word (
		qw<
			first_list_element second_list_element third_list_element
			first_comma_separated_word second_comma_separated_word third_comma_separated_word
			single_bareword_statement
			bareword_no_semicolon_end_of_block
			hash_key
			fat_comma_left_side
		>
	) {
		is(
			scalar $words{$false_word}->method_call,
			0,
			"$false_word is false.",
		);
	}
}


__TOKENIZER__ON_CHAR: {
	# PPI::Statement::Operator
	for my $test (
		[ q{$foo and'bar';}, 'and' ],
		[ q{$foo cmp'bar';}, 'cmp' ],
		[ q{$foo eq'bar';},  'eq' ],
		[ q{$foo ge'bar';},  'ge' ],
		[ q{$foo gt'bar';},  'gt' ],
		[ q{$foo le'bar';},  'le' ],
		[ q{$foo lt'bar';},  'lt' ],
		[ q{$foo ne'bar';},  'ne' ],
		[ q{$foo not'bar';}, 'not' ],
		[ q{$foo or'bar';},  'or' ],
		[ q{$foo x'bar';},   'x' ],
		[ q{$foo xor'bar';}, 'xor' ],
	) {
		my ( $code, $expected ) = @$test;
		my ( $Document, $statement ) = _parse_to_statement( $code, 'PPI::Statement' );
		is( $statement, $code, "$code: statement text matches" );
		_compare_child( $statement, 2, 'PPI::Token::Operator', $expected, $code );
		_compare_child( $statement, 3, 'PPI::Token::Quote::Single', "'bar'", $code );
		_compare_child( $statement, 4, 'PPI::Token::Structure', ';', $code );
	}


	# PPI::Token::Quote::*
	for my $test (
		[ q{q'foo';},  q{q'foo'},  'PPI::Token::Quote::Literal' ],
		[ q{qq'foo';}, q{qq'foo'}, 'PPI::Token::Quote::Interpolate' ],
		[ q{qr'foo';}, q{qr'foo'}, 'PPI::Token::QuoteLike::Regexp' ],
		[ q{qw'foo';}, q{qw'foo'}, 'PPI::Token::QuoteLike::Words' ],
		[ q{qx'foo';}, q{qx'foo'}, 'PPI::Token::QuoteLike::Command' ],
	) {
		my ( $code, $expected, $type ) = @$test;
		my ( $Document, $statement ) = _parse_to_statement( $code, 'PPI::Statement' );
		is( $statement, $code, "$code: statement text matches" );
		_compare_child( $statement, 0, $type, $expected, $code );
		_compare_child( $statement, 1, 'PPI::Token::Structure', ';', $code );
	}


	# PPI::Token::Regexp::*
	for my $test (
		[ q{m'foo';},     q{m'foo'},     'PPI::Token::Regexp::Match' ],
		[ q{s'foo'bar';}, q{s'foo'bar'}, 'PPI::Token::Regexp::Substitute' ],
		[ q{tr'fo'ba';},  q{tr'fo'ba'},  'PPI::Token::Regexp::Transliterate' ],
		[ q{y'fo'ba';},   q{y'fo'ba'},   'PPI::Token::Regexp::Transliterate' ],
	) {
		my ( $code, $expected, $type ) = @$test;
		my ( $Document, $statement ) = _parse_to_statement( $code, 'PPI::Statement' );
		is( $statement, $code, "$code: statement text matches" );
		_compare_child( $statement, 0, $type, $expected, $code );
		_compare_child( $statement, 1, 'PPI::Token::Structure', ';', $code );
	}


	# PPI::Token::Word
	for my $test (
		[ q{abs'3';},             'abs' ],
		[ q{accept'1234',2345;},  'accept' ],
		[ q{alarm'5';},           'alarm' ],
		[ q{atan2'5';},           'atan2' ],
		[ q{bind'5',"";},         'bind' ],
		[ q{binmode'5';},         'binmode' ],
		[ q{bless'foo', 'bar';},  'bless' ],
		[ q{break'foo' when 1;},  'break' ],
		[ q{caller'3';},          'caller' ],
		[ q{chdir'foo';},         'chdir' ],
		[ q{chmod'0777', 'foo';}, 'chmod' ],
		[ q{chomp'a';},           'chomp' ],
		[ q{chop'a';},            'chop' ],
		[ q{chown'a';},           'chown' ],
		[ q{chr'32';},            'chr' ],
		[ q{chroot'a';},          'chroot' ],
		[ q{close'1';},           'close' ],
		[ q{closedir'1';},        'closedir' ],
		[ q{connect'1234',$foo;}, 'connect' ],
		[ q{continue'a';},        'continue' ],
		[ q{cos'3';},             'cos' ],
		[ q{crypt'foo', 'bar';},  'crypt' ],
		[ q{dbmclose'foo';},      'dbmclose' ],
		[ q{dbmopen'foo','bar';}, 'dbmopen' ],
		[ q{default'a' {}},       'default' ],
		[ q{defined'foo';},       'defined' ],
		[ q{delete'foo';},        'delete' ],
		[ q{die'foo';},           'die' ],
		[ q{do'foo';},            'do' ],
		[ q{dump'foo';},          'dump' ],
		[ q{each'foo';},          'each' ],
		[ q{else'foo' {};},       'else' ],
		[ q{elsif'foo' {};},      'elsif' ],
		[ q{endgrent'foo';},      'endgrent' ],
		[ q{endhostent'foo';},    'endhostent' ],
		[ q{endnetent'foo';},     'endnetent' ],
		[ q{endprotoent'foo';},   'endprotoent' ],
		[ q{endpwent'foo';},      'endpwent' ],
		[ q{endservent'foo';},    'endservent' ],
		[ q{eof'foo';},           'eof' ],
		[ q{eval'foo';},          'eval' ],
		[ q{evalbytes'foo';},     'evalbytes' ],
		[ q{exec'foo';},          'exec' ],
		[ q{exists'foo';},        'exists' ],
		[ q{exit'foo';},          'exit' ],
		[ q{exp'foo';},           'exp' ],
		[ q{fc'foo';},            'fc' ],
		[ q{fcntl'1';},           'fcntl' ],
		[ q{fileno'1';},          'fileno' ],
		[ q{flock'1', LOCK_EX;},  'flock' ],
		[ q{fork'';},             'fork' ],
		[ qq{format''=\n.},       'format' ],
		[ q{formline'@',1;},      'formline' ],
		[ q{getc'1';},            'getc' ],
		[ q{getgrent'foo';},      'getgrent' ],
		[ q{getgrgid'1';},        'getgrgid' ],
		[ q{getgrnam'foo';},      'getgrnam' ],
		[ q{gethostbyaddr'1', AF_INET;}, 'gethostbyaddr' ],
		[ q{gethostbyname'foo';}, 'gethostbyname' ],
		[ q{gethostent'foo';},    'gethostent' ],
		[ q{getlogin'foo';},      'getlogin' ],
		[ q{getnetbyaddr'1', AF_INET;}, 'getnetbyaddr' ],
		[ q{getnetbyname'foo';},  'getnetbyname' ],
		[ q{getnetent'foo';},     'getnetent' ],
		[ q{getpeername'foo';},   'getpeername' ],
		[ q{getpgrp'1';},         'getpgrp' ],
		[ q{getppid'1';},         'getppid' ],
		[ q{getpriority'1',2;},   'getpriority' ],
		[ q{getprotobyname'tcp';}, 'getprotobyname' ],
		[ q{getprotobynumber'6';}, 'getprotobynumber' ],
		[ q{getprotoent'foo';},   'getprotoent' ],
		[ q{getpwent'foo';},      'getpwent' ],
		[ q{getpwnam'foo';},      'getpwnam' ],
		[ q{getpwuid'1';},        'getpwuid' ],
		[ q{getservbyname'foo', 'bar';}, 'getservbyname' ],
		[ q{getservbyport'23', 'tcp';}, 'getservbyport' ],
		[ q{getservent'foo';},    'getservent' ],
		[ q{getsockname'foo';},   'getsockname' ],
		[ q{getsockopt'foo', 'bar', TCP_NODELAY;}, 'getsockopt' ],
		[ q{glob'foo';},          'glob' ],
		[ q{gmtime'1';},          'gmtime' ],
		[ q{goto'label';},        'goto' ],
		[ q{hex'1';},             'hex' ],
		[ q{index'1','foo';},     'index' ],
		[ q{int'1';},             'int' ],
		[ q{ioctl'1',1;},         'ioctl' ],
		[ q{join'a',@foo;},       'join' ],
		[ q{keys'foo';},          'keys' ],
		[ q{kill'KILL';},         'kill' ],
		[ q{last'label';},        'last' ],
		[ q{lc'foo';},            'lc' ],
		[ q{lcfirst'foo';},       'lcfirst' ],
		[ q{length'foo';},        'length' ],
		[ q{link'foo','bar';},    'link' ],
		[ q{listen'1234',10;},    'listen' ],
		[ q{local'foo';},         'local' ],
		[ q{localtime'1';},       'localtime' ],
		[ q{lock'foo';},          'lock' ],
		[ q{log'foo';},           'log' ],
		[ q{lstat'foo';},         'lstat' ],
		[ q{mkdir'foo';},         'mkdir' ],
		[ q{msgctl'1','foo',1;},  'msgctl' ],
		[ q{msgget'1',1},         'msgget' ],
		[ q{msgrcv'1',$foo,1,1,1;}, 'msgrcv' ],
		[ q{msgsnd'1',$foo,1;},   'msgsnd' ],
		[ q{my'foo';},            'my' ],
		[ q{next'label';},        'next' ],
		[ q{oct'foo';},           'oct' ],
		[ q{open'foo';},          'open' ],
		[ q{opendir'foo';},       'opendir' ],
		[ q{ord'foo';},           'ord' ],
		[ q{our'foo';},           'our' ],
		[ q{pack'H*',$data;},     'pack' ],
		[ q{pipe'in','out';},     'pipe' ],
		[ q{pop'foo';},           'pop' ],
		[ q{pos'foo';},           'pos' ],
		[ q{print'foo';},         'print' ],
		[ q{printf'foo','bar';},  'printf' ],
		[ q{prototype'foo';},     'prototype' ],
		[ q{push'foo','bar';},    'push' ],
		[ q{quotemeta'foo';},     'quotemeta' ],
		[ q{rand'1';},            'rand' ],
		[ q{read'1',$foo,100;},   'read' ],
		[ q{readdir'1';},         'readdir' ],
		[ q{readline'1';},        'readline' ],
		[ q{readlink'1';},        'readlink' ],
		[ q{readpipe'1';},        'readpipe' ],
		[ q{recv'1',$foo,100,1;}, 'recv' ],
		[ q{redo'label';},        'redo' ],
		[ q{ref'foo';},           'ref' ],
		[ q{rename'foo','bar';},  'rename' ],
		[ q{require'foo';},       'require' ],
		[ q{reset'f';},           'reset' ],
		[ q{return'foo';},        'return' ],
		[ q{reverse'foo','bar';}, 'reverse' ],
		[ q{rewinddir'1';},       'rewinddir' ],
		[ q{rindex'1','foo';},    'rindex' ],
		[ q{rmdir'foo';},         'rmdir' ],
		[ q{say'foo';},           'say' ],
		[ q{scalar'foo','bar';},  'scalar' ],
		[ q{seek'1',100,0;},      'seek' ],
		[ q{seekdir'1',100;},     'seekdir' ],
		[ q{select'1';},          'select' ],
		[ q{semctl'1',1,1;},      'semctl' ],
		[ q{semget'foo',1,1;},    'semget' ],
		[ q{semop'foo','bar';},   'semop' ],
		[ q{send'1',$foo'100,1;}, 'send' ],
		[ q{setgrent'foo';},      'setgrent' ],
		[ q{sethostent'1';},      'sethostent' ],
		[ q{setnetent'1';},       'setnetent' ],
		[ q{setpgrp'1',2;},       'setpgrp' ],
		[ q{setpriority'1',2, 3;}, 'setpriority' ],
		[ q{setprotoent'1';},     'setprotoent' ],
		[ q{setpwent'foo';},      'setpwent' ],
		[ q{setservent'1';},      'setservent' ],
		[ q{setsockopt'1',2,'foo',3;}, 'setsockopt' ],
		[ q{shift'1','2';},       'shift' ],
		[ q{shmctl'1',2,$foo;},   'shmctl' ],
		[ q{shmget'1',2,1;},      'shmget' ],
		[ q{shmread'1',$foo,0,10;}, 'shmread' ],
		[ q{shmwrite'1',$foo,0,10;}, 'shmwrite' ],
		[ q{shutdown'1',0;},      'shutdown' ],
		[ q{sin'1';},             'sin' ],
		[ q{sleep'1';},           'sleep' ],
		[ q{socket'1',2,3,6;},    'socket' ],
		[ q{socketpair'1',2,3,4,6;}, 'socketpair' ],
		[ q{splice'1',2;},        'splice' ],
		[ q{split'1','foo';},     'split' ],
		[ q{sprintf'foo','bar';}, 'sprintf' ],
		[ q{sqrt'1';},            'sqrt' ],
		[ q{srand'1';},           'srand' ],
		[ q{stat'foo';},          'stat' ],
		[ q{state'foo';},         'state' ],
		[ q{study'foo';},         'study' ],
		[ q{substr'foo',1;},      'substr' ],
		[ q{symlink'foo','bar';}, 'symlink' ],
		[ q{syscall'foo';},       'syscall' ],
		[ q{sysopen'foo','bar',1;}, 'sysopen' ],
		[ q{sysread'1',$bar,1;},  'sysread' ],
		[ q{sysseek'1',0,0;},     'sysseek' ],
		[ q{system'foo';},        'system' ],
		[ q{syswrite'1',$bar,1;}, 'syswrite' ],
		[ q{tell'1';},            'tell' ],
		[ q{telldir'1';},         'telldir' ],
		[ q{tie'foo',$bar;},      'tie' ],
		[ q{tied'foo';},          'tied' ],
		[ q{time'foo';},          'time' ],
		[ q{times'foo';},         'times' ],
		[ q{truncate'foo',1;},    'truncate' ],
		[ q{uc'foo';},            'uc' ],
		[ q{ucfirst'foo';},       'ucfirst' ],
		[ q{umask'foo';},         'umask' ],
		[ q{undef'foo';},         'undef' ],
 		[ q{unlink'foo';},        'unlink' ],
		[ q{unpack'H*',$data;},   'unpack' ],
		[ q{unshift'1';},         'unshift' ],
		[ q{untie'foo';},         'untie' ],
		[ q{utime'1','2';},       'utime' ],
		[ q{values'foo';},        'values' ],
		[ q{vec'1',0.0;},         'vec' ],
		[ q{wait'1';},            'wait' ],
		[ q{waitpid'1',0;},       'waitpid' ],
		[ q{wantarray'foo';},     'wantarray' ],
		[ q{warn'foo';},          'warn' ],
		[ q{when'foo' {}},        'when' ],
		[ q{write'foo';},         'write' ],
	) {
		my ( $code, $expected ) = @$test;
		my ( $Document, $statement ) = _parse_to_statement( $code, 'PPI::Statement' );
		is( $statement, $code, "$code: statement text matches" );
		_compare_child( $statement, 0, 'PPI::Token::Word', $expected, $code );
		isa_ok( $statement->child(1), 'PPI::Token::Quote::Single', "$code: second child is a 'PPI::Token::Quote::Single'" );
	}
	for my $test (
		[ q{1 for'foo';},        'for' ],
		[ q{1 foreach'foo';},    'foreach' ],
		[ q{1 if'foo';},          'if' ],
		[ q{1 unless'foo';},      'unless' ],
		[ q{1 until'foo';},       'until' ],
		[ q{1 while'foo';},       'while' ],
	) {
		my ( $code, $expected ) = @$test;
		my ( $Document, $statement ) = _parse_to_statement( $code, 'PPI::Statement' );
		is( $statement, $code, "$code: statement text matches" );
		_compare_child( $statement, 2, 'PPI::Token::Word', $expected, $code );
		_compare_child( $statement, 3, 'PPI::Token::Quote::Single', "'foo'", $code );
	}
	# Untested: given, grep map, sort, sub


	# PPI::Statement::Include
	for my $test (
		[ "no'foo';",      'no' ],
		[ "require'foo';", 'require' ],
		[ "use'foo';",     'use' ],
	) {
		my ( $code, $expected ) = @$test;
		my ( $Document, $statement ) = _parse_to_statement( $code, 'PPI::Statement::Include' );
		is( $statement, $code, "$code: statement text matches" );
		_compare_child( $statement, 0, 'PPI::Token::Word', $expected, $code );
		_compare_child( $statement, 1, 'PPI::Token::Quote::Single', "'foo'", $code );
		_compare_child( $statement, 2, 'PPI::Token::Structure', ';', $code );
	}


	# PPI::Statement::Package
	my ( $PackageDocument, $statement ) = _parse_to_statement( "package'foo';", 'PPI::Statement::Package' );
	is( $statement, q{package'foo';}, q{package'foo'} );
	_compare_child( $statement, 0, 'PPI::Token::Word', 'package', 'package statement' );
	_compare_child( $statement, 1, 'PPI::Token::Quote::Single', "'foo'", 'package statement' );
	_compare_child( $statement, 2, 'PPI::Token::Structure', ';', 'package statement' );
}


sub _parse_to_statement {
	local $Test::Builder::Level = $Test::Builder::Level+1;
	my $code = shift;
	my $type = shift;

	my $Document = PPI::Document->new( \$code );
	isa_ok( $Document, 'PPI::Document', "$code: got the document" );
	my $statements = $Document->find( $type );
	is( scalar(@$statements), 1, "$code: got one $type" );
	isa_ok( $statements->[0], $type, "$code: got the statement" );

	return ( $Document, $statements->[0] );
}


sub _compare_child {
	local $Test::Builder::Level = $Test::Builder::Level+1;
	my $statement = shift;
	my $childno = shift;
	my $type = shift;
	my $content = shift;
	my $desc = shift;

	isa_ok( $statement->child($childno), $type, "$desc child $childno is a $type");
	is( $statement->child($childno), $content, "$desc child $childno is 1" );

	return;
}
