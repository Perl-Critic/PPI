#!/usr/bin/perl

# Unit testing for PPI::Statement::Package

use t::lib::PPI::Test::pragmas;
use Test::More tests => 2506 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI;


HASH_CONSTRUCTORS_DONT_CONTAIN_PACKAGES_RT52259: {
	my $Document = PPI::Document->new(\<<'END_PERL');
{    package  => "", };
+{   package  => "", };
{   'package' => "", };
+{  'package' => "", };
{   'package' ,  "", };
+{  'package' ,  "", };
END_PERL
	isa_ok( $Document, 'PPI::Document' );

	my $packages = $Document->find('PPI::Statement::Package');
	my $test_name = 'Found no package statements in hash constructors - RT #52259';
	if (not $packages) {
		pass $test_name;
	} elsif ( not is(scalar @{$packages}, 0, $test_name) ) {
		diag 'Package statements found:';
		diag $_->parent()->parent()->content() foreach @{$packages};
	}
}


INSIDE_SCOPE: {
	# Create a document with various example package statements
	my $Document = PPI::Document->new( \<<'END_PERL' );
package Foo;
SCOPE: {
	package # comment
	Bar::Baz;
	1;
}
package Other v1.23;
package Again 0.09;
1;
END_PERL
	isa_ok( $Document, 'PPI::Document' );

	# Check that both of the package statements are detected
	my $packages = $Document->find('Statement::Package');
	is( scalar(@$packages), 4, 'Found 2 package statements' );
	is( $packages->[0]->namespace, 'Foo', 'Package 1 returns correct namespace' );
	is( $packages->[1]->namespace, 'Bar::Baz', 'Package 2 returns correct namespace' );
	is( $packages->[2]->namespace, 'Other', 'Package 3 returns correct namespace' );
	is( $packages->[3]->namespace, 'Again', 'Package 4 returns correct namespace' );
	is( $packages->[0]->file_scoped, 1,  '->file_scoped returns true for package 1' );
	is( $packages->[1]->file_scoped, '', '->file_scoped returns false for package 2' );
	is( $packages->[2]->file_scoped, 1, '->file_scoped returns true for package 3' );
	is( $packages->[3]->file_scoped, 1, '->file_scoped returns true for package 4' );
	is( $packages->[0]->version, '', 'Package 1 has no version' );
	is( $packages->[1]->version, '', 'Package 2 has no version' );
	is( $packages->[2]->version, 'v1.23', 'Package 3 returns correct version' );
	is( $packages->[3]->version, '0.09', 'Package 4 returns correct version' );
}

my %known_bad = map { ( "package $_" => 1 ) }
  'AUTOLOAD 0.50 { 1 }', 'AUTOLOAD 0.50{ 1 }', 'AUTOLOAD v1.2.3 { 1 }', 'AUTOLOAD v1.2.3{ 1 }', 'AUTOLOAD { 1 }', 'Foo 0.50 { 1 }', 'Foo 0.50{ 1 }', 'Foo v1.2.3 { 1 }', 'Foo v1.2.3{ 1 }', 'Foo { 1 }', '__FILE__ 0.50 { 1 }', '__FILE__ 0.50{ 1 }', '__FILE__ v1.2.3 { 1 }', '__FILE__ v1.2.3{ 1 }', '__FILE__ { 1 }', '__LINE__ 0.50 { 1 }', '__LINE__ 0.50{ 1 }', '__LINE__ v1.2.3 { 1 }', '__LINE__ v1.2.3{ 1 }', '__LINE__ { 1 }', '__PACKAGE__ 0.50 { 1 }', '__PACKAGE__ 0.50{ 1 }', '__PACKAGE__ v1.2.3 { 1 }', '__PACKAGE__ v1.2.3{ 1 }', '__PACKAGE__ { 1 }', '__SUB__ 0.50 { 1 }', '__SUB__ 0.50{ 1 }', '__SUB__ v1.2.3 { 1 }', '__SUB__ v1.2.3{ 1 }', '__SUB__ { 1 }', 'abs 0.50 { 1 }', 'abs 0.50{ 1 }', 'abs v1.2.3 { 1 }', 'abs v1.2.3{ 1 }', 'abs { 1 }', 'accept 0.50 { 1 }', 'accept 0.50{ 1 }', 'accept v1.2.3 { 1 }', 'accept v1.2.3{ 1 }', 'accept { 1 }', 'alarm 0.50 { 1 }', 'alarm 0.50{ 1 }', 'alarm v1.2.3 { 1 }', 'alarm v1.2.3{ 1 }', 'alarm { 1 }', 'and 0.50 ;', 'and 0.50 { 1 }', 'and 0.50;', 'and 0.50{ 1 }', 'and ;', 'and v1.2.3 ;', 'and v1.2.3 { 1 }', 'and v1.2.3;', 'and v1.2.3{ 1 }', 'and { 1 }', 'atan2 0.50 { 1 }', 'atan2 0.50{ 1 }', 'atan2 v1.2.3 { 1 }', 'atan2 v1.2.3{ 1 }', 'atan2 { 1 }', 'bind 0.50 { 1 }', 'bind 0.50{ 1 }', 'bind v1.2.3 { 1 }', 'bind v1.2.3{ 1 }', 'bind { 1 }', 'binmode 0.50 { 1 }', 'binmode 0.50{ 1 }', 'binmode v1.2.3 { 1 }', 'binmode v1.2.3{ 1 }', 'binmode { 1 }', 'bless 0.50 { 1 }', 'bless 0.50{ 1 }', 'bless v1.2.3 { 1 }', 'bless v1.2.3{ 1 }', 'bless { 1 }', 'break 0.50 { 1 }', 'break 0.50{ 1 }', 'break v1.2.3 { 1 }', 'break v1.2.3{ 1 }', 'break { 1 }', 'caller 0.50 { 1 }', 'caller 0.50{ 1 }', 'caller v1.2.3 { 1 }', 'caller v1.2.3{ 1 }', 'caller { 1 }', 'chdir 0.50 { 1 }', 'chdir 0.50{ 1 }', 'chdir v1.2.3 { 1 }', 'chdir v1.2.3{ 1 }', 'chdir { 1 }', 'chmod 0.50 { 1 }', 'chmod 0.50{ 1 }', 'chmod v1.2.3 { 1 }', 'chmod v1.2.3{ 1 }', 'chmod { 1 }', 'chomp 0.50 { 1 }', 'chomp 0.50{ 1 }', 'chomp v1.2.3 { 1 }', 'chomp v1.2.3{ 1 }', 'chomp { 1 }', 'chop 0.50 { 1 }', 'chop 0.50{ 1 }', 'chop v1.2.3 { 1 }', 'chop v1.2.3{ 1 }', 'chop { 1 }', 'chown 0.50 { 1 }', 'chown 0.50{ 1 }', 'chown v1.2.3 { 1 }', 'chown v1.2.3{ 1 }', 'chown { 1 }', 'chr 0.50 { 1 }', 'chr 0.50{ 1 }', 'chr v1.2.3 { 1 }', 'chr v1.2.3{ 1 }', 'chr { 1 }', 'chroot 0.50 { 1 }', 'chroot 0.50{ 1 }', 'chroot v1.2.3 { 1 }', 'chroot v1.2.3{ 1 }', 'chroot { 1 }', 'close 0.50 { 1 }', 'close 0.50{ 1 }', 'close v1.2.3 { 1 }', 'close v1.2.3{ 1 }', 'close { 1 }', 'closedir 0.50 { 1 }', 'closedir 0.50{ 1 }', 'closedir v1.2.3 { 1 }', 'closedir v1.2.3{ 1 }', 'closedir { 1 }', 'cmp 0.50 ;', 'cmp 0.50 { 1 }', 'cmp 0.50;', 'cmp 0.50{ 1 }', 'cmp ;', 'cmp v1.2.3 ;', 'cmp v1.2.3 { 1 }', 'cmp v1.2.3;', 'cmp v1.2.3{ 1 }', 'cmp { 1 }', 'connect 0.50 { 1 }', 'connect 0.50{ 1 }', 'connect v1.2.3 { 1 }', 'connect v1.2.3{ 1 }', 'connect { 1 }', 'continue 0.50 { 1 }', 'continue 0.50{ 1 }', 'continue v1.2.3 { 1 }', 'continue v1.2.3{ 1 }', 'continue { 1 }', 'cos 0.50 { 1 }', 'cos 0.50{ 1 }', 'cos v1.2.3 { 1 }', 'cos v1.2.3{ 1 }', 'cos { 1 }', 'crypt 0.50 { 1 }', 'crypt 0.50{ 1 }', 'crypt v1.2.3 { 1 }', 'crypt v1.2.3{ 1 }', 'crypt { 1 }', 'dbmclose 0.50 { 1 }', 'dbmclose 0.50{ 1 }', 'dbmclose v1.2.3 { 1 }', 'dbmclose v1.2.3{ 1 }', 'dbmclose { 1 }', 'dbmopen 0.50 { 1 }', 'dbmopen 0.50{ 1 }', 'dbmopen v1.2.3 { 1 }',
  'dbmopen v1.2.3{ 1 }', 'dbmopen { 1 }', 'default 0.50 { 1 }', 'default 0.50{ 1 }', 'default v1.2.3 { 1 }', 'default v1.2.3{ 1 }', 'default { 1 }', 'defined 0.50 { 1 }', 'defined 0.50{ 1 }', 'defined v1.2.3 { 1 }', 'defined v1.2.3{ 1 }', 'defined { 1 }', 'delete 0.50 { 1 }', 'delete 0.50{ 1 }', 'delete v1.2.3 { 1 }', 'delete v1.2.3{ 1 }', 'delete { 1 }', 'die 0.50 { 1 }', 'die 0.50{ 1 }', 'die v1.2.3 { 1 }', 'die v1.2.3{ 1 }', 'die { 1 }', 'do 0.50 { 1 }', 'do 0.50{ 1 }', 'do v1.2.3 { 1 }', 'do v1.2.3{ 1 }', 'do { 1 }', 'dump 0.50 { 1 }', 'dump 0.50{ 1 }', 'dump v1.2.3 { 1 }', 'dump v1.2.3{ 1 }', 'dump { 1 }', 'each 0.50 { 1 }', 'each 0.50{ 1 }', 'each v1.2.3 { 1 }', 'each v1.2.3{ 1 }', 'each { 1 }', 'else 0.50 { 1 }', 'else 0.50{ 1 }', 'else v1.2.3 { 1 }', 'else v1.2.3{ 1 }', 'else { 1 }', 'elsif 0.50 { 1 }', 'elsif 0.50{ 1 }', 'elsif v1.2.3 { 1 }', 'elsif v1.2.3{ 1 }', 'elsif { 1 }', 'endgrent 0.50 { 1 }', 'endgrent 0.50{ 1 }', 'endgrent v1.2.3 { 1 }', 'endgrent v1.2.3{ 1 }', 'endgrent { 1 }', 'endhostent 0.50 { 1 }', 'endhostent 0.50{ 1 }', 'endhostent v1.2.3 { 1 }', 'endhostent v1.2.3{ 1 }', 'endhostent { 1 }', 'endnetent 0.50 { 1 }', 'endnetent 0.50{ 1 }', 'endnetent v1.2.3 { 1 }', 'endnetent v1.2.3{ 1 }', 'endnetent { 1 }', 'endprotoent 0.50 { 1 }', 'endprotoent 0.50{ 1 }', 'endprotoent v1.2.3 { 1 }', 'endprotoent v1.2.3{ 1 }', 'endprotoent { 1 }', 'endpwent 0.50 { 1 }', 'endpwent 0.50{ 1 }', 'endpwent v1.2.3 { 1 }', 'endpwent v1.2.3{ 1 }', 'endpwent { 1 }', 'endservent 0.50 { 1 }', 'endservent 0.50{ 1 }', 'endservent v1.2.3 { 1 }', 'endservent v1.2.3{ 1 }', 'endservent { 1 }', 'eof 0.50 { 1 }', 'eof 0.50{ 1 }', 'eof v1.2.3 { 1 }', 'eof v1.2.3{ 1 }', 'eof { 1 }', 'eq 0.50 ;', 'eq 0.50 { 1 }', 'eq 0.50;', 'eq 0.50{ 1 }', 'eq ;', 'eq v1.2.3 ;', 'eq v1.2.3 { 1 }', 'eq v1.2.3;', 'eq v1.2.3{ 1 }', 'eq { 1 }', 'eval 0.50 { 1 }', 'eval 0.50{ 1 }', 'eval v1.2.3 { 1 }', 'eval v1.2.3{ 1 }', 'eval { 1 }', 'evalbytes 0.50 { 1 }', 'evalbytes 0.50{ 1 }', 'evalbytes v1.2.3 { 1 }', 'evalbytes v1.2.3{ 1 }', 'evalbytes { 1 }', 'exec 0.50 { 1 }', 'exec 0.50{ 1 }', 'exec v1.2.3 { 1 }', 'exec v1.2.3{ 1 }', 'exec { 1 }', 'exists 0.50 { 1 }', 'exists 0.50{ 1 }', 'exists v1.2.3 { 1 }', 'exists v1.2.3{ 1 }', 'exists { 1 }', 'exit 0.50 { 1 }', 'exit 0.50{ 1 }', 'exit v1.2.3 { 1 }', 'exit v1.2.3{ 1 }', 'exit { 1 }', 'exp 0.50 { 1 }', 'exp 0.50{ 1 }', 'exp v1.2.3 { 1 }', 'exp v1.2.3{ 1 }', 'exp { 1 }', 'fc 0.50 { 1 }', 'fc 0.50{ 1 }', 'fc v1.2.3 { 1 }', 'fc v1.2.3{ 1 }', 'fc { 1 }', 'fcntl 0.50 { 1 }', 'fcntl 0.50{ 1 }', 'fcntl v1.2.3 { 1 }', 'fcntl v1.2.3{ 1 }', 'fcntl { 1 }', 'fileno 0.50 { 1 }', 'fileno 0.50{ 1 }', 'fileno v1.2.3 { 1 }', 'fileno v1.2.3{ 1 }', 'fileno { 1 }', 'flock 0.50 { 1 }', 'flock 0.50{ 1 }', 'flock v1.2.3 { 1 }', 'flock v1.2.3{ 1 }', 'flock { 1 }', 'for 0.50 { 1 }', 'for 0.50{ 1 }', 'for v1.2.3 { 1 }', 'for v1.2.3{ 1 }', 'for { 1 }', 'foreach 0.50 { 1 }', 'foreach 0.50{ 1 }', 'foreach v1.2.3 { 1 }', 'foreach v1.2.3{ 1 }', 'foreach { 1 }', 'fork 0.50 { 1 }', 'fork 0.50{ 1 }', 'fork v1.2.3 { 1 }', 'fork v1.2.3{ 1 }', 'fork { 1 }', 'format 0.50 { 1 }', 'format 0.50{ 1 }', 'format v1.2.3 { 1 }', 'format v1.2.3{ 1 }', 'format { 1 }', 'formline 0.50 { 1 }', 'formline 0.50{ 1 }', 'formline v1.2.3 { 1 }', 'formline v1.2.3{ 1 }', 'formline { 1 }', 'ge 0.50 ;',
  'ge 0.50 { 1 }', 'ge 0.50;', 'ge 0.50{ 1 }', 'ge ;', 'ge v1.2.3 ;', 'ge v1.2.3 { 1 }', 'ge v1.2.3;', 'ge v1.2.3{ 1 }', 'ge { 1 }', 'getc 0.50 { 1 }', 'getc 0.50{ 1 }', 'getc v1.2.3 { 1 }', 'getc v1.2.3{ 1 }', 'getc { 1 }', 'getgrent 0.50 { 1 }', 'getgrent 0.50{ 1 }', 'getgrent v1.2.3 { 1 }', 'getgrent v1.2.3{ 1 }', 'getgrent { 1 }', 'getgrgid 0.50 { 1 }', 'getgrgid 0.50{ 1 }', 'getgrgid v1.2.3 { 1 }', 'getgrgid v1.2.3{ 1 }', 'getgrgid { 1 }', 'getgrnam 0.50 { 1 }', 'getgrnam 0.50{ 1 }', 'getgrnam v1.2.3 { 1 }', 'getgrnam v1.2.3{ 1 }', 'getgrnam { 1 }', 'gethostbyaddr 0.50 { 1 }', 'gethostbyaddr 0.50{ 1 }', 'gethostbyaddr v1.2.3 { 1 }', 'gethostbyaddr v1.2.3{ 1 }', 'gethostbyaddr { 1 }', 'gethostbyname 0.50 { 1 }', 'gethostbyname 0.50{ 1 }', 'gethostbyname v1.2.3 { 1 }', 'gethostbyname v1.2.3{ 1 }', 'gethostbyname { 1 }', 'gethostent 0.50 { 1 }', 'gethostent 0.50{ 1 }', 'gethostent v1.2.3 { 1 }', 'gethostent v1.2.3{ 1 }', 'gethostent { 1 }', 'getlogin 0.50 { 1 }', 'getlogin 0.50{ 1 }', 'getlogin v1.2.3 { 1 }', 'getlogin v1.2.3{ 1 }', 'getlogin { 1 }', 'getnetbyaddr 0.50 { 1 }', 'getnetbyaddr 0.50{ 1 }', 'getnetbyaddr v1.2.3 { 1 }', 'getnetbyaddr v1.2.3{ 1 }', 'getnetbyaddr { 1 }', 'getnetbyname 0.50 { 1 }', 'getnetbyname 0.50{ 1 }', 'getnetbyname v1.2.3 { 1 }', 'getnetbyname v1.2.3{ 1 }', 'getnetbyname { 1 }', 'getnetent 0.50 { 1 }', 'getnetent 0.50{ 1 }', 'getnetent v1.2.3 { 1 }', 'getnetent v1.2.3{ 1 }', 'getnetent { 1 }', 'getpeername 0.50 { 1 }', 'getpeername 0.50{ 1 }', 'getpeername v1.2.3 { 1 }', 'getpeername v1.2.3{ 1 }', 'getpeername { 1 }', 'getpgrp 0.50 { 1 }', 'getpgrp 0.50{ 1 }', 'getpgrp v1.2.3 { 1 }', 'getpgrp v1.2.3{ 1 }', 'getpgrp { 1 }', 'getppid 0.50 { 1 }', 'getppid 0.50{ 1 }', 'getppid v1.2.3 { 1 }', 'getppid v1.2.3{ 1 }', 'getppid { 1 }', 'getpriority 0.50 { 1 }', 'getpriority 0.50{ 1 }', 'getpriority v1.2.3 { 1 }', 'getpriority v1.2.3{ 1 }', 'getpriority { 1 }', 'getprotobyname 0.50 { 1 }', 'getprotobyname 0.50{ 1 }', 'getprotobyname v1.2.3 { 1 }', 'getprotobyname v1.2.3{ 1 }', 'getprotobyname { 1 }', 'getprotobynumber 0.50 { 1 }', 'getprotobynumber 0.50{ 1 }', 'getprotobynumber v1.2.3 { 1 }', 'getprotobynumber v1.2.3{ 1 }', 'getprotobynumber { 1 }', 'getprotoent 0.50 { 1 }', 'getprotoent 0.50{ 1 }', 'getprotoent v1.2.3 { 1 }', 'getprotoent v1.2.3{ 1 }', 'getprotoent { 1 }', 'getpwent 0.50 { 1 }', 'getpwent 0.50{ 1 }', 'getpwent v1.2.3 { 1 }', 'getpwent v1.2.3{ 1 }', 'getpwent { 1 }', 'getpwnam 0.50 { 1 }', 'getpwnam 0.50{ 1 }', 'getpwnam v1.2.3 { 1 }', 'getpwnam v1.2.3{ 1 }', 'getpwnam { 1 }', 'getpwuid 0.50 { 1 }', 'getpwuid 0.50{ 1 }', 'getpwuid v1.2.3 { 1 }', 'getpwuid v1.2.3{ 1 }', 'getpwuid { 1 }', 'getservbyname 0.50 { 1 }', 'getservbyname 0.50{ 1 }', 'getservbyname v1.2.3 { 1 }', 'getservbyname v1.2.3{ 1 }', 'getservbyname { 1 }', 'getservbyport 0.50 { 1 }', 'getservbyport 0.50{ 1 }', 'getservbyport v1.2.3 { 1 }', 'getservbyport v1.2.3{ 1 }', 'getservbyport { 1 }', 'getservent 0.50 { 1 }', 'getservent 0.50{ 1 }', 'getservent v1.2.3 { 1 }', 'getservent v1.2.3{ 1 }', 'getservent { 1 }', 'getsockname 0.50 { 1 }', 'getsockname 0.50{ 1 }', 'getsockname v1.2.3 { 1 }', 'getsockname v1.2.3{ 1 }', 'getsockname { 1 }', 'getsockopt 0.50 { 1 }', 'getsockopt 0.50{ 1 }', 'getsockopt v1.2.3 { 1 }', 'getsockopt v1.2.3{ 1 }', 'getsockopt { 1 }',
  'given 0.50 { 1 }', 'given 0.50{ 1 }', 'given v1.2.3 { 1 }', 'given v1.2.3{ 1 }', 'given { 1 }', 'glob 0.50 { 1 }', 'glob 0.50{ 1 }', 'glob v1.2.3 { 1 }', 'glob v1.2.3{ 1 }', 'glob { 1 }', 'gmtime 0.50 { 1 }', 'gmtime 0.50{ 1 }', 'gmtime v1.2.3 { 1 }', 'gmtime v1.2.3{ 1 }', 'gmtime { 1 }', 'goto 0.50 { 1 }', 'goto 0.50{ 1 }', 'goto v1.2.3 { 1 }', 'goto v1.2.3{ 1 }', 'goto { 1 }', 'grep 0.50 { 1 }', 'grep 0.50{ 1 }', 'grep v1.2.3 { 1 }', 'grep v1.2.3{ 1 }', 'grep { 1 }', 'gt 0.50 ;', 'gt 0.50 { 1 }', 'gt 0.50;', 'gt 0.50{ 1 }', 'gt ;', 'gt v1.2.3 ;', 'gt v1.2.3 { 1 }', 'gt v1.2.3;', 'gt v1.2.3{ 1 }', 'gt { 1 }', 'hex 0.50 { 1 }', 'hex 0.50{ 1 }', 'hex v1.2.3 { 1 }', 'hex v1.2.3{ 1 }', 'hex { 1 }', 'if 0.50 { 1 }', 'if 0.50{ 1 }', 'if v1.2.3 { 1 }', 'if v1.2.3{ 1 }', 'if { 1 }', 'index 0.50 { 1 }', 'index 0.50{ 1 }', 'index v1.2.3 { 1 }', 'index v1.2.3{ 1 }', 'index { 1 }', 'int 0.50 { 1 }', 'int 0.50{ 1 }', 'int v1.2.3 { 1 }', 'int v1.2.3{ 1 }', 'int { 1 }', 'ioctl 0.50 { 1 }', 'ioctl 0.50{ 1 }', 'ioctl v1.2.3 { 1 }', 'ioctl v1.2.3{ 1 }', 'ioctl { 1 }', 'join 0.50 { 1 }', 'join 0.50{ 1 }', 'join v1.2.3 { 1 }', 'join v1.2.3{ 1 }', 'join { 1 }', 'keys 0.50 { 1 }', 'keys 0.50{ 1 }', 'keys v1.2.3 { 1 }', 'keys v1.2.3{ 1 }', 'keys { 1 }', 'kill 0.50 { 1 }', 'kill 0.50{ 1 }', 'kill v1.2.3 { 1 }', 'kill v1.2.3{ 1 }', 'kill { 1 }', 'last 0.50 { 1 }', 'last 0.50{ 1 }', 'last v1.2.3 { 1 }', 'last v1.2.3{ 1 }', 'last { 1 }', 'lc 0.50 { 1 }', 'lc 0.50{ 1 }', 'lc v1.2.3 { 1 }', 'lc v1.2.3{ 1 }', 'lc { 1 }', 'lcfirst 0.50 { 1 }', 'lcfirst 0.50{ 1 }', 'lcfirst v1.2.3 { 1 }', 'lcfirst v1.2.3{ 1 }', 'lcfirst { 1 }', 'le 0.50 ;', 'le 0.50 { 1 }', 'le 0.50;', 'le 0.50{ 1 }', 'le ;', 'le v1.2.3 ;', 'le v1.2.3 { 1 }', 'le v1.2.3;', 'le v1.2.3{ 1 }', 'le { 1 }', 'length 0.50 { 1 }', 'length 0.50{ 1 }', 'length v1.2.3 { 1 }', 'length v1.2.3{ 1 }', 'length { 1 }', 'link 0.50 { 1 }', 'link 0.50{ 1 }', 'link v1.2.3 { 1 }', 'link v1.2.3{ 1 }', 'link { 1 }', 'listen 0.50 { 1 }', 'listen 0.50{ 1 }', 'listen v1.2.3 { 1 }', 'listen v1.2.3{ 1 }', 'listen { 1 }', 'local 0.50 { 1 }', 'local 0.50{ 1 }', 'local v1.2.3 { 1 }', 'local v1.2.3{ 1 }', 'local { 1 }', 'localtime 0.50 { 1 }', 'localtime 0.50{ 1 }', 'localtime v1.2.3 { 1 }', 'localtime v1.2.3{ 1 }', 'localtime { 1 }', 'lock 0.50 { 1 }', 'lock 0.50{ 1 }', 'lock v1.2.3 { 1 }', 'lock v1.2.3{ 1 }', 'lock { 1 }', 'log 0.50 { 1 }', 'log 0.50{ 1 }', 'log v1.2.3 { 1 }', 'log v1.2.3{ 1 }', 'log { 1 }', 'lstat 0.50 { 1 }', 'lstat 0.50{ 1 }', 'lstat v1.2.3 { 1 }', 'lstat v1.2.3{ 1 }', 'lstat { 1 }', 'lt 0.50 ;', 'lt 0.50 { 1 }', 'lt 0.50;', 'lt 0.50{ 1 }', 'lt ;', 'lt v1.2.3 ;', 'lt v1.2.3 { 1 }', 'lt v1.2.3;', 'lt v1.2.3{ 1 }', 'lt { 1 }', 'm 0.50 ;', 'm 0.50 { 1 }', 'm 0.50;', 'm 0.50{ 1 }', 'm ;', 'm v1.2.3 ;', 'm v1.2.3 { 1 }', 'm v1.2.3;', 'm v1.2.3{ 1 }', 'm { 1 }', 'map 0.50 { 1 }', 'map 0.50{ 1 }', 'map v1.2.3 { 1 }', 'map v1.2.3{ 1 }', 'map { 1 }', 'mkdir 0.50 { 1 }', 'mkdir 0.50{ 1 }', 'mkdir v1.2.3 { 1 }', 'mkdir v1.2.3{ 1 }', 'mkdir { 1 }', 'msgctl 0.50 { 1 }', 'msgctl 0.50{ 1 }', 'msgctl v1.2.3 { 1 }', 'msgctl v1.2.3{ 1 }', 'msgctl { 1 }', 'msgget 0.50 { 1 }', 'msgget 0.50{ 1 }', 'msgget v1.2.3 { 1 }', 'msgget v1.2.3{ 1 }', 'msgget { 1 }', 'msgrcv 0.50 { 1 }', 'msgrcv 0.50{ 1 }', 'msgrcv v1.2.3 { 1 }', 'msgrcv v1.2.3{ 1 }',
  'msgrcv { 1 }', 'msgsnd 0.50 { 1 }', 'msgsnd 0.50{ 1 }', 'msgsnd v1.2.3 { 1 }', 'msgsnd v1.2.3{ 1 }', 'msgsnd { 1 }', 'my 0.50 { 1 }', 'my 0.50{ 1 }', 'my v1.2.3 { 1 }', 'my v1.2.3{ 1 }', 'my { 1 }', 'ne 0.50 ;', 'ne 0.50 { 1 }', 'ne 0.50;', 'ne 0.50{ 1 }', 'ne ;', 'ne v1.2.3 ;', 'ne v1.2.3 { 1 }', 'ne v1.2.3;', 'ne v1.2.3{ 1 }', 'ne { 1 }', 'next 0.50 { 1 }', 'next 0.50{ 1 }', 'next v1.2.3 { 1 }', 'next v1.2.3{ 1 }', 'next { 1 }', 'no 0.50 { 1 }', 'no 0.50{ 1 }', 'no v1.2.3 { 1 }', 'no v1.2.3{ 1 }', 'no { 1 }', 'not 0.50 ;', 'not 0.50 { 1 }', 'not 0.50;', 'not 0.50{ 1 }', 'not ;', 'not v1.2.3 ;', 'not v1.2.3 { 1 }', 'not v1.2.3;', 'not v1.2.3{ 1 }', 'not { 1 }', 'oct 0.50 { 1 }', 'oct 0.50{ 1 }', 'oct v1.2.3 { 1 }', 'oct v1.2.3{ 1 }', 'oct { 1 }', 'open 0.50 { 1 }', 'open 0.50{ 1 }', 'open v1.2.3 { 1 }', 'open v1.2.3{ 1 }', 'open { 1 }', 'opendir 0.50 { 1 }', 'opendir 0.50{ 1 }', 'opendir v1.2.3 { 1 }', 'opendir v1.2.3{ 1 }', 'opendir { 1 }', 'or 0.50 ;', 'or 0.50 { 1 }', 'or 0.50;', 'or 0.50{ 1 }', 'or ;', 'or v1.2.3 ;', 'or v1.2.3 { 1 }', 'or v1.2.3;', 'or v1.2.3{ 1 }', 'or { 1 }', 'ord 0.50 { 1 }', 'ord 0.50{ 1 }', 'ord v1.2.3 { 1 }', 'ord v1.2.3{ 1 }', 'ord { 1 }', 'our 0.50 { 1 }', 'our 0.50{ 1 }', 'our v1.2.3 { 1 }', 'our v1.2.3{ 1 }', 'our { 1 }', 'pack 0.50 { 1 }', 'pack 0.50{ 1 }', 'pack v1.2.3 { 1 }', 'pack v1.2.3{ 1 }', 'pack { 1 }', 'package 0.50 { 1 }', 'package 0.50{ 1 }', 'package v1.2.3 { 1 }', 'package v1.2.3{ 1 }', 'package { 1 }', 'pipe 0.50 { 1 }', 'pipe 0.50{ 1 }', 'pipe v1.2.3 { 1 }', 'pipe v1.2.3{ 1 }', 'pipe { 1 }', 'pop 0.50 { 1 }', 'pop 0.50{ 1 }', 'pop v1.2.3 { 1 }', 'pop v1.2.3{ 1 }', 'pop { 1 }', 'pos 0.50 { 1 }', 'pos 0.50{ 1 }', 'pos v1.2.3 { 1 }', 'pos v1.2.3{ 1 }', 'pos { 1 }', 'print 0.50 { 1 }', 'print 0.50{ 1 }', 'print v1.2.3 { 1 }', 'print v1.2.3{ 1 }', 'print { 1 }', 'printf 0.50 { 1 }', 'printf 0.50{ 1 }', 'printf v1.2.3 { 1 }', 'printf v1.2.3{ 1 }', 'printf { 1 }', 'prototype 0.50 { 1 }', 'prototype 0.50{ 1 }', 'prototype v1.2.3 { 1 }', 'prototype v1.2.3{ 1 }', 'prototype { 1 }', 'push 0.50 { 1 }', 'push 0.50{ 1 }', 'push v1.2.3 { 1 }', 'push v1.2.3{ 1 }', 'push { 1 }', 'q 0.50 ;', 'q 0.50 { 1 }', 'q 0.50;', 'q 0.50{ 1 }', 'q ;', 'q v1.2.3 ;', 'q v1.2.3 { 1 }', 'q v1.2.3;', 'q v1.2.3{ 1 }', 'q { 1 }', 'qq 0.50 ;', 'qq 0.50 { 1 }', 'qq 0.50;', 'qq 0.50{ 1 }', 'qq ;', 'qq v1.2.3 ;', 'qq v1.2.3 { 1 }', 'qq v1.2.3;', 'qq v1.2.3{ 1 }', 'qq { 1 }', 'qr 0.50 ;', 'qr 0.50 { 1 }', 'qr 0.50;', 'qr 0.50{ 1 }', 'qr ;', 'qr v1.2.3 ;', 'qr v1.2.3 { 1 }', 'qr v1.2.3;', 'qr v1.2.3{ 1 }', 'qr { 1 }', 'quotemeta 0.50 { 1 }', 'quotemeta 0.50{ 1 }', 'quotemeta v1.2.3 { 1 }', 'quotemeta v1.2.3{ 1 }', 'quotemeta { 1 }', 'qw 0.50 ;', 'qw 0.50 { 1 }', 'qw 0.50;', 'qw 0.50{ 1 }', 'qw ;', 'qw v1.2.3 ;', 'qw v1.2.3 { 1 }', 'qw v1.2.3;', 'qw v1.2.3{ 1 }', 'qw { 1 }', 'qx 0.50 ;', 'qx 0.50 { 1 }', 'qx 0.50;', 'qx 0.50{ 1 }', 'qx ;', 'qx v1.2.3 ;', 'qx v1.2.3 { 1 }', 'qx v1.2.3;', 'qx v1.2.3{ 1 }', 'qx { 1 }', 'rand 0.50 { 1 }', 'rand 0.50{ 1 }', 'rand v1.2.3 { 1 }', 'rand v1.2.3{ 1 }', 'rand { 1 }', 'read 0.50 { 1 }', 'read 0.50{ 1 }', 'read v1.2.3 { 1 }', 'read v1.2.3{ 1 }', 'read { 1 }', 'readdir 0.50 { 1 }', 'readdir 0.50{ 1 }', 'readdir v1.2.3 { 1 }', 'readdir v1.2.3{ 1 }', 'readdir { 1 }', 'readline 0.50 { 1 }', 'readline 0.50{ 1 }',
  'readline v1.2.3 { 1 }', 'readline v1.2.3{ 1 }', 'readline { 1 }', 'readlink 0.50 { 1 }', 'readlink 0.50{ 1 }', 'readlink v1.2.3 { 1 }', 'readlink v1.2.3{ 1 }', 'readlink { 1 }', 'readpipe 0.50 { 1 }', 'readpipe 0.50{ 1 }', 'readpipe v1.2.3 { 1 }', 'readpipe v1.2.3{ 1 }', 'readpipe { 1 }', 'recv 0.50 { 1 }', 'recv 0.50{ 1 }', 'recv v1.2.3 { 1 }', 'recv v1.2.3{ 1 }', 'recv { 1 }', 'redo 0.50 { 1 }', 'redo 0.50{ 1 }', 'redo v1.2.3 { 1 }', 'redo v1.2.3{ 1 }', 'redo { 1 }', 'ref 0.50 { 1 }', 'ref 0.50{ 1 }', 'ref v1.2.3 { 1 }', 'ref v1.2.3{ 1 }', 'ref { 1 }', 'rename 0.50 { 1 }', 'rename 0.50{ 1 }', 'rename v1.2.3 { 1 }', 'rename v1.2.3{ 1 }', 'rename { 1 }', 'require 0.50 { 1 }', 'require 0.50{ 1 }', 'require v1.2.3 { 1 }', 'require v1.2.3{ 1 }', 'require { 1 }', 'reset 0.50 { 1 }', 'reset 0.50{ 1 }', 'reset v1.2.3 { 1 }', 'reset v1.2.3{ 1 }', 'reset { 1 }', 'return 0.50 { 1 }', 'return 0.50{ 1 }', 'return v1.2.3 { 1 }', 'return v1.2.3{ 1 }', 'return { 1 }', 'reverse 0.50 { 1 }', 'reverse 0.50{ 1 }', 'reverse v1.2.3 { 1 }', 'reverse v1.2.3{ 1 }', 'reverse { 1 }', 'rewinddir 0.50 { 1 }', 'rewinddir 0.50{ 1 }', 'rewinddir v1.2.3 { 1 }', 'rewinddir v1.2.3{ 1 }', 'rewinddir { 1 }', 'rindex 0.50 { 1 }', 'rindex 0.50{ 1 }', 'rindex v1.2.3 { 1 }', 'rindex v1.2.3{ 1 }', 'rindex { 1 }', 'rmdir 0.50 { 1 }', 'rmdir 0.50{ 1 }', 'rmdir v1.2.3 { 1 }', 'rmdir v1.2.3{ 1 }', 'rmdir { 1 }', 's 0.50 ;', 's 0.50 { 1 }', 's 0.50;', 's 0.50{ 1 }', 's ;', 's v1.2.3 ;', 's v1.2.3 { 1 }', 's v1.2.3;', 's v1.2.3{ 1 }', 's { 1 }', 'say 0.50 { 1 }', 'say 0.50{ 1 }', 'say v1.2.3 { 1 }', 'say v1.2.3{ 1 }', 'say { 1 }', 'scalar 0.50 { 1 }', 'scalar 0.50{ 1 }', 'scalar v1.2.3 { 1 }', 'scalar v1.2.3{ 1 }', 'scalar { 1 }', 'seek 0.50 { 1 }', 'seek 0.50{ 1 }', 'seek v1.2.3 { 1 }', 'seek v1.2.3{ 1 }', 'seek { 1 }', 'seekdir 0.50 { 1 }', 'seekdir 0.50{ 1 }', 'seekdir v1.2.3 { 1 }', 'seekdir v1.2.3{ 1 }', 'seekdir { 1 }', 'select 0.50 { 1 }', 'select 0.50{ 1 }', 'select v1.2.3 { 1 }', 'select v1.2.3{ 1 }', 'select { 1 }', 'semctl 0.50 { 1 }', 'semctl 0.50{ 1 }', 'semctl v1.2.3 { 1 }', 'semctl v1.2.3{ 1 }', 'semctl { 1 }', 'semget 0.50 { 1 }', 'semget 0.50{ 1 }', 'semget v1.2.3 { 1 }', 'semget v1.2.3{ 1 }', 'semget { 1 }', 'semop 0.50 { 1 }', 'semop 0.50{ 1 }', 'semop v1.2.3 { 1 }', 'semop v1.2.3{ 1 }', 'semop { 1 }', 'send 0.50 { 1 }', 'send 0.50{ 1 }', 'send v1.2.3 { 1 }', 'send v1.2.3{ 1 }', 'send { 1 }', 'setgrent 0.50 { 1 }', 'setgrent 0.50{ 1 }', 'setgrent v1.2.3 { 1 }', 'setgrent v1.2.3{ 1 }', 'setgrent { 1 }', 'sethostent 0.50 { 1 }', 'sethostent 0.50{ 1 }', 'sethostent v1.2.3 { 1 }', 'sethostent v1.2.3{ 1 }', 'sethostent { 1 }', 'setnetent 0.50 { 1 }', 'setnetent 0.50{ 1 }', 'setnetent v1.2.3 { 1 }', 'setnetent v1.2.3{ 1 }', 'setnetent { 1 }', 'setpgrp 0.50 { 1 }', 'setpgrp 0.50{ 1 }', 'setpgrp v1.2.3 { 1 }', 'setpgrp v1.2.3{ 1 }', 'setpgrp { 1 }', 'setpriority 0.50 { 1 }', 'setpriority 0.50{ 1 }', 'setpriority v1.2.3 { 1 }', 'setpriority v1.2.3{ 1 }', 'setpriority { 1 }', 'setprotoent 0.50 { 1 }', 'setprotoent 0.50{ 1 }', 'setprotoent v1.2.3 { 1 }', 'setprotoent v1.2.3{ 1 }', 'setprotoent { 1 }', 'setpwent 0.50 { 1 }', 'setpwent 0.50{ 1 }', 'setpwent v1.2.3 { 1 }', 'setpwent v1.2.3{ 1 }', 'setpwent { 1 }', 'setservent 0.50 { 1 }', 'setservent 0.50{ 1 }', 'setservent v1.2.3 { 1 }',
  'setservent v1.2.3{ 1 }', 'setservent { 1 }', 'setsockopt 0.50 { 1 }', 'setsockopt 0.50{ 1 }', 'setsockopt v1.2.3 { 1 }', 'setsockopt v1.2.3{ 1 }', 'setsockopt { 1 }', 'shift 0.50 { 1 }', 'shift 0.50{ 1 }', 'shift v1.2.3 { 1 }', 'shift v1.2.3{ 1 }', 'shift { 1 }', 'shmctl 0.50 { 1 }', 'shmctl 0.50{ 1 }', 'shmctl v1.2.3 { 1 }', 'shmctl v1.2.3{ 1 }', 'shmctl { 1 }', 'shmget 0.50 { 1 }', 'shmget 0.50{ 1 }', 'shmget v1.2.3 { 1 }', 'shmget v1.2.3{ 1 }', 'shmget { 1 }', 'shmread 0.50 { 1 }', 'shmread 0.50{ 1 }', 'shmread v1.2.3 { 1 }', 'shmread v1.2.3{ 1 }', 'shmread { 1 }', 'shmwrite 0.50 { 1 }', 'shmwrite 0.50{ 1 }', 'shmwrite v1.2.3 { 1 }', 'shmwrite v1.2.3{ 1 }', 'shmwrite { 1 }', 'shutdown 0.50 { 1 }', 'shutdown 0.50{ 1 }', 'shutdown v1.2.3 { 1 }', 'shutdown v1.2.3{ 1 }', 'shutdown { 1 }', 'sin 0.50 { 1 }', 'sin 0.50{ 1 }', 'sin v1.2.3 { 1 }', 'sin v1.2.3{ 1 }', 'sin { 1 }', 'sleep 0.50 { 1 }', 'sleep 0.50{ 1 }', 'sleep v1.2.3 { 1 }', 'sleep v1.2.3{ 1 }', 'sleep { 1 }', 'socket 0.50 { 1 }', 'socket 0.50{ 1 }', 'socket v1.2.3 { 1 }', 'socket v1.2.3{ 1 }', 'socket { 1 }', 'socketpair 0.50 { 1 }', 'socketpair 0.50{ 1 }', 'socketpair v1.2.3 { 1 }', 'socketpair v1.2.3{ 1 }', 'socketpair { 1 }', 'sort 0.50 { 1 }', 'sort 0.50{ 1 }', 'sort v1.2.3 { 1 }', 'sort v1.2.3{ 1 }', 'sort { 1 }', 'splice 0.50 { 1 }', 'splice 0.50{ 1 }', 'splice v1.2.3 { 1 }', 'splice v1.2.3{ 1 }', 'splice { 1 }', 'split 0.50 { 1 }', 'split 0.50{ 1 }', 'split v1.2.3 { 1 }', 'split v1.2.3{ 1 }', 'split { 1 }', 'sprintf 0.50 { 1 }', 'sprintf 0.50{ 1 }', 'sprintf v1.2.3 { 1 }', 'sprintf v1.2.3{ 1 }', 'sprintf { 1 }', 'sqrt 0.50 { 1 }', 'sqrt 0.50{ 1 }', 'sqrt v1.2.3 { 1 }', 'sqrt v1.2.3{ 1 }', 'sqrt { 1 }', 'srand 0.50 { 1 }', 'srand 0.50{ 1 }', 'srand v1.2.3 { 1 }', 'srand v1.2.3{ 1 }', 'srand { 1 }', 'stat 0.50 { 1 }', 'stat 0.50{ 1 }', 'stat v1.2.3 { 1 }', 'stat v1.2.3{ 1 }', 'stat { 1 }', 'state 0.50 { 1 }', 'state 0.50{ 1 }', 'state v1.2.3 { 1 }', 'state v1.2.3{ 1 }', 'state { 1 }', 'study 0.50 { 1 }', 'study 0.50{ 1 }', 'study v1.2.3 { 1 }', 'study v1.2.3{ 1 }', 'study { 1 }', 'sub 0.50 { 1 }', 'sub 0.50{ 1 }', 'sub v1.2.3 { 1 }', 'sub v1.2.3{ 1 }', 'sub { 1 }', 'substr 0.50 { 1 }', 'substr 0.50{ 1 }', 'substr v1.2.3 { 1 }', 'substr v1.2.3{ 1 }', 'substr { 1 }', 'symlink 0.50 { 1 }', 'symlink 0.50{ 1 }', 'symlink v1.2.3 { 1 }', 'symlink v1.2.3{ 1 }', 'symlink { 1 }', 'syscall 0.50 { 1 }', 'syscall 0.50{ 1 }', 'syscall v1.2.3 { 1 }', 'syscall v1.2.3{ 1 }', 'syscall { 1 }', 'sysopen 0.50 { 1 }', 'sysopen 0.50{ 1 }', 'sysopen v1.2.3 { 1 }', 'sysopen v1.2.3{ 1 }', 'sysopen { 1 }', 'sysread 0.50 { 1 }', 'sysread 0.50{ 1 }', 'sysread v1.2.3 { 1 }', 'sysread v1.2.3{ 1 }', 'sysread { 1 }', 'sysseek 0.50 { 1 }', 'sysseek 0.50{ 1 }', 'sysseek v1.2.3 { 1 }', 'sysseek v1.2.3{ 1 }', 'sysseek { 1 }', 'system 0.50 { 1 }', 'system 0.50{ 1 }', 'system v1.2.3 { 1 }', 'system v1.2.3{ 1 }', 'system { 1 }', 'syswrite 0.50 { 1 }', 'syswrite 0.50{ 1 }', 'syswrite v1.2.3 { 1 }', 'syswrite v1.2.3{ 1 }', 'syswrite { 1 }', 'tell 0.50 { 1 }', 'tell 0.50{ 1 }', 'tell v1.2.3 { 1 }', 'tell v1.2.3{ 1 }', 'tell { 1 }', 'telldir 0.50 { 1 }', 'telldir 0.50{ 1 }', 'telldir v1.2.3 { 1 }', 'telldir v1.2.3{ 1 }', 'telldir { 1 }', 'tie 0.50 { 1 }', 'tie 0.50{ 1 }', 'tie v1.2.3 { 1 }', 'tie v1.2.3{ 1 }', 'tie { 1 }',
  'tied 0.50 { 1 }', 'tied 0.50{ 1 }', 'tied v1.2.3 { 1 }', 'tied v1.2.3{ 1 }', 'tied { 1 }', 'time 0.50 { 1 }', 'time 0.50{ 1 }', 'time v1.2.3 { 1 }', 'time v1.2.3{ 1 }', 'time { 1 }', 'times 0.50 { 1 }', 'times 0.50{ 1 }', 'times v1.2.3 { 1 }', 'times v1.2.3{ 1 }', 'times { 1 }', 'tr 0.50 ;', 'tr 0.50 { 1 }', 'tr 0.50;', 'tr 0.50{ 1 }', 'tr ;', 'tr v1.2.3 ;', 'tr v1.2.3 { 1 }', 'tr v1.2.3;', 'tr v1.2.3{ 1 }', 'tr { 1 }', 'truncate 0.50 { 1 }', 'truncate 0.50{ 1 }', 'truncate v1.2.3 { 1 }', 'truncate v1.2.3{ 1 }', 'truncate { 1 }', 'uc 0.50 { 1 }', 'uc 0.50{ 1 }', 'uc v1.2.3 { 1 }', 'uc v1.2.3{ 1 }', 'uc { 1 }', 'ucfirst 0.50 { 1 }', 'ucfirst 0.50{ 1 }', 'ucfirst v1.2.3 { 1 }', 'ucfirst v1.2.3{ 1 }', 'ucfirst { 1 }', 'umask 0.50 { 1 }', 'umask 0.50{ 1 }', 'umask v1.2.3 { 1 }', 'umask v1.2.3{ 1 }', 'umask { 1 }', 'undef 0.50 { 1 }', 'undef 0.50{ 1 }', 'undef v1.2.3 { 1 }', 'undef v1.2.3{ 1 }', 'undef { 1 }', 'unless 0.50 { 1 }', 'unless 0.50{ 1 }', 'unless v1.2.3 { 1 }', 'unless v1.2.3{ 1 }', 'unless { 1 }', 'unlink 0.50 { 1 }', 'unlink 0.50{ 1 }', 'unlink v1.2.3 { 1 }', 'unlink v1.2.3{ 1 }', 'unlink { 1 }', 'unpack 0.50 { 1 }', 'unpack 0.50{ 1 }', 'unpack v1.2.3 { 1 }', 'unpack v1.2.3{ 1 }', 'unpack { 1 }', 'unshift 0.50 { 1 }', 'unshift 0.50{ 1 }', 'unshift v1.2.3 { 1 }', 'unshift v1.2.3{ 1 }', 'unshift { 1 }', 'untie 0.50 { 1 }', 'untie 0.50{ 1 }', 'untie v1.2.3 { 1 }', 'untie v1.2.3{ 1 }', 'untie { 1 }', 'until 0.50 { 1 }', 'until 0.50{ 1 }', 'until v1.2.3 { 1 }', 'until v1.2.3{ 1 }', 'until { 1 }', 'use 0.50 { 1 }', 'use 0.50{ 1 }', 'use v1.2.3 { 1 }', 'use v1.2.3{ 1 }', 'use { 1 }', 'utime 0.50 { 1 }', 'utime 0.50{ 1 }', 'utime v1.2.3 { 1 }', 'utime v1.2.3{ 1 }', 'utime { 1 }', 'v10 0.50 ;', 'v10 0.50 { 1 }', 'v10 0.50;', 'v10 0.50{ 1 }', 'v10 ;', 'v10 v1.2.3 ;', 'v10 v1.2.3 { 1 }', 'v10 v1.2.3;', 'v10 v1.2.3{ 1 }', 'v10 { 1 }', 'values 0.50 { 1 }', 'values 0.50{ 1 }', 'values v1.2.3 { 1 }', 'values v1.2.3{ 1 }', 'values { 1 }', 'vec 0.50 { 1 }', 'vec 0.50{ 1 }', 'vec v1.2.3 { 1 }', 'vec v1.2.3{ 1 }', 'vec { 1 }', 'wait 0.50 { 1 }', 'wait 0.50{ 1 }', 'wait v1.2.3 { 1 }', 'wait v1.2.3{ 1 }', 'wait { 1 }', 'waitpid 0.50 { 1 }', 'waitpid 0.50{ 1 }', 'waitpid v1.2.3 { 1 }', 'waitpid v1.2.3{ 1 }', 'waitpid { 1 }', 'wantarray 0.50 { 1 }', 'wantarray 0.50{ 1 }', 'wantarray v1.2.3 { 1 }', 'wantarray v1.2.3{ 1 }', 'wantarray { 1 }', 'warn 0.50 { 1 }', 'warn 0.50{ 1 }', 'warn v1.2.3 { 1 }', 'warn v1.2.3{ 1 }', 'warn { 1 }', 'when 0.50 { 1 }', 'when 0.50{ 1 }', 'when v1.2.3 { 1 }', 'when v1.2.3{ 1 }', 'when { 1 }', 'while 0.50 { 1 }', 'while 0.50{ 1 }', 'while v1.2.3 { 1 }', 'while v1.2.3{ 1 }', 'while { 1 }', 'write 0.50 { 1 }', 'write 0.50{ 1 }', 'write v1.2.3 { 1 }', 'write v1.2.3{ 1 }', 'write { 1 }', 'x 0.50 ;', 'x 0.50 { 1 }', 'x 0.50;', 'x 0.50{ 1 }', 'x ;', 'x v1.2.3 ;', 'x v1.2.3 { 1 }', 'x v1.2.3;', 'x v1.2.3{ 1 }', 'x { 1 }', 'x64 0.50 ;', 'x64 0.50 { 1 }', 'x64 0.50;', 'x64 0.50{ 1 }', 'x64 ;', 'x64 v1.2.3 ;', 'x64 v1.2.3 { 1 }', 'x64 v1.2.3;', 'x64 v1.2.3{ 1 }', 'x64 { 1 }', 'xor 0.50 ;', 'xor 0.50 { 1 }', 'xor 0.50;', 'xor 0.50{ 1 }', 'xor ;', 'xor v1.2.3 ;', 'xor v1.2.3 { 1 }', 'xor v1.2.3;', 'xor v1.2.3{ 1 }', 'xor { 1 }', 'y 0.50 ;', 'y 0.50 { 1 }', 'y 0.50;', 'y 0.50{ 1 }', 'y ;', 'y v1.2.3 ;', 'y v1.2.3 { 1 }', 'y v1.2.3;', 'y v1.2.3{ 1 }', 'y { 1 }';

PERL_5_12_SYNTAX: {
	my @names = (
		# normal name
		'Foo',
		# Keywords must parse as Word and not influence lexing
		# of subsequent curly braces.
		keys %PPI::Token::Word::KEYWORDS,
		# regression: misparsed as version string
		'v10',
		# regression GitHub #122: 'x' parsed as x operator
		'x64',
		# Other weird and/or special words, just in case
		'__PACKAGE__',
		'__FILE__',
		'__LINE__',
		'__SUB__',
		'AUTOLOAD',
	);
	my @versions = (
		[ 'v1.2.3 ', 'PPI::Token::Number::Version' ],
		[ 'v1.2.3', 'PPI::Token::Number::Version' ],
		[ '0.50 ', 'PPI::Token::Number::Float' ],
		[ '0.50', 'PPI::Token::Number::Float' ],
		[ '', '' ],  # omit version, traditional
	);
	my @blocks = (
		[ ';', 'PPI::Token::Structure' ],  # traditional package syntax
		[ '{ 1 }', 'PPI::Structure::Block' ],  # 5.12 package syntax
	);
	$_->[2] = strip_ws_padding( $_->[0] ) for @versions, @blocks;

	for my $name ( @names ) {
		for my $version_pair ( @versions ) {
			for my $block_pair ( @blocks ) {
				my @test = prepare_package_test( $version_pair, $block_pair, $name );
				test_package_blocks( @test );
			}
		}
	}
}

sub strip_ws_padding {
	my ( $string ) = @_;
	$string =~ s/(^\s+|\s+$)//g;
	return $string;
}

sub prepare_package_test {
	my ( $version_pair, $block_pair, $name ) = @_;

	my ( $version, $version_type, $version_stripped ) = @{$version_pair};
	my ( $block, $block_type, $block_stripped ) = @{$block_pair};

	my $code = "package $name $version$block";

	my $expected_package_tokens = [
		[ 'PPI::Token::Word', 'package' ],
		[ 'PPI::Token::Word', $name ],
		($version ne '') ? [ $version_type, $version_stripped ] : (),
		[ $block_type, $block_stripped ],
	];

	return ( $code, $expected_package_tokens );
}

sub test_package_blocks {
	my ( $code, $expected_package_tokens ) = @_;

TODO: {
	local $TODO = $known_bad{$code} ? "known bug" : undef;
	subtest "'$code'", sub {

	my $Document = PPI::Document->new( \"$code 999;" );
	is(     $Document->schildren, 2, "correct number of statements in document" );
	isa_ok( $Document->schild(0), 'PPI::Statement::Package', "entire code" );

	# first child is the package statement
	my $got_tokens = [ map { [ ref $_, "$_" ] } $Document->schild(0)->schildren ];
	is_deeply( $got_tokens, $expected_package_tokens, "tokens as expected" );

	# second child not swallowed up by the first
	isa_ok( $Document->schild(1), 'PPI::Statement', "code prior statement end recognized" );
	isa_ok( eval { $Document->schild(1)->schild(0) }, 'PPI::Token::Number', "inner code" );
	is(     eval { $Document->schild(1)->schild(0) }, '999', "number correct"  );
	};
}
	return;
}
