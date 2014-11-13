#!/usr/bin/perl

# Unit testing for PPI::Token::Number::Version

use t::lib::PPI::Test::pragmas;
use Test::More tests => 736;

use PPI;


LITERAL: {
	my $doc1 = new_ok( 'PPI::Document' => [ \'1.2.3.4'  ] );
	my $doc2 = new_ok( 'PPI::Document' => [ \'v1.2.3.4' ] );
	isa_ok( $doc1->child(0), 'PPI::Statement' );
	isa_ok( $doc2->child(0), 'PPI::Statement' );
	isa_ok( $doc1->child(0)->child(0), 'PPI::Token::Number::Version' );
	isa_ok( $doc2->child(0)->child(0), 'PPI::Token::Number::Version' );

	my $literal1 = $doc1->child(0)->child(0)->literal;
	my $literal2 = $doc2->child(0)->child(0)->literal;
	is( length($literal1), 4, 'The literal length of doc1 is 4' );
	is( length($literal2), 4, 'The literal length of doc1 is 4' );
	is( $literal1, $literal2, 'Literals match for 1.2.3.4 vs v1.2.3.4' );
}


VSTRING_ENDS_CORRECTLY: {
	my %known_bad = map { $_ => 1 } map { "v49$_" } qw'abs accept alarm and atan2 bind binmode bless break caller chdir chmod chomp chop chown chr chroot close closedir cmp connect continue cos crypt dbmclose dbmopen default defined delete die do dump e10 each else elsif endgrent endhostent endnetent endprotoent endpwent endservent eof eq eval evalbytes exec exists exit exp fc fcntl fileno flock for foreach fork format formline ge getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname gethostent getlogin getnetbyaddr getnetbyname getnetent getpeername getpgrp getppid getpriority getprotobyname getprotobynumber getprotoent getpwent getpwnam getpwuid getservbyname getservbyport getservent getsockname getsockopt given glob gmtime goto grep gt hex if index int ioctl join keys kill last lc lcfirst le length link listen local localtime lock log lstat lt m map mkdir msgctl msgget msgrcv msgsnd my ne next no not oct open opendir or ord our pack package pipe pop pos print printf prototype push q qq qr quotemeta qw qx rand read readdir readline readlink readpipe recv redo ref rename require reset return reverse rewinddir rindex rmdir s say scalar seek seekdir select semctl semget semop send setgrent sethostent setnetent setpgrp setpriority setprotoent setpwent setservent setsockopt shift shmctl shmget shmread shmwrite shutdown sin sleep socket socketpair sort splice split sprintf sqrt srand stat state study sub substr symlink syscall sysopen sysread sysseek system syswrite tell telldir tie tied time times tr truncate uc ucfirst umask undef unless unlink unpack unshift untie until use utime values vec wait waitpid wantarray warn when while write x x3 xor y';
	my @tests = (
		(
			map {
				{
					desc=>"no . in 'v49$_', so not a version string",
					code=>"v49$_",
					expected=>[ 'PPI::Token::Word' => "v49$_" ],
				}
			} (
				'x3', # not fooled by faux x operator with operand
				'e10', # not fooled by faux scientific notation
				keys %PPI::Token::Word::KEYWORDS,
			),
		),
		(
			map {
				{
					desc => "version string in 'v49.49$_' stops after number",
					code => "v49.49$_",
					expected => [
						'PPI::Token::Number::Version' => 'v49.49',
						get_class($_) => $_,
					],
				},
			} (
				keys %PPI::Token::Word::KEYWORDS,
			),
		),
		(
			map {
				{
					desc => "version string in '49.49.49$_' stops after number",
					code => "49.49.49$_",
					expected => [
						'PPI::Token::Number::Version' => '49.49.49',
						get_class($_) => $_,
					],
				},
			} (
				keys %PPI::Token::Word::KEYWORDS,
			),
		),
		{
			desc => 'version string, x, and operand',
			code => 'v49.49.49x3',
			expected => [
				'PPI::Token::Number::Version' => 'v49.49.49',
				'PPI::Token::Operator' => 'x',
				'PPI::Token::Number' => '3',
			],
		},
	);
	for my $test ( @tests ) {
		my $code = $test->{code};

		my $d = PPI::Document->new( \$test->{code} );
		my $tokens = $d->find( sub { 1; } );
		$tokens = [ map { ref($_), $_->content() } @$tokens ];
		my $expected = $test->{expected};
		unshift @$expected, 'PPI::Statement', $test->{code};
TODO: {
		local $TODO = $known_bad{$test->{code}} ? "known bug" : undef;
		my $ok = is_deeply( $tokens, $expected, $test->{desc} );
		if ( !$known_bad{$test->{code}} and !$ok ) {
			diag "$test->{code} ($test->{desc})\n";
			diag explain $tokens;
			diag explain $test->{expected};
		}
}
	}
}

sub get_class {
	my ( $t ) = @_;
	my $ql = $PPI::Token::Word::QUOTELIKE{$t};
	return "PPI::Token::$ql" if $ql;
	return 'PPI::Token::Operator' if $PPI::Token::Word::OPERATOR{$t};
	return 'PPI::Token::Word';
}
