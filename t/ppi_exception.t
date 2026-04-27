#!/usr/bin/perl

# Unit testing for PPI::Exception and PPI::Exception::ParserRejection

use lib 't/lib';
use PPI::Test::pragmas;
use Test::More tests => 24 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

use PPI::Exception ();
use PPI::Exception::ParserRejection ();
use Params::Util qw{_INSTANCE};


# ====== PPI::Exception::new ======

NEW_NO_ARGS: {
	my $e = PPI::Exception->new;
	isa_ok $e, 'PPI::Exception';
	is $e->message, 'Unknown Exception', 'new() with no args gives default message';
}

NEW_STRING: {
	my $e = PPI::Exception->new('something happened');
	isa_ok $e, 'PPI::Exception';
	is $e->message, 'something happened', 'new($string) sets message';
}

NEW_NAMED: {
	my $e = PPI::Exception->new( message => 'named msg' );
	isa_ok $e, 'PPI::Exception';
	is $e->message, 'named msg', 'new(message => $str) sets message';
}


# ====== PPI::Exception::message ======

MESSAGE: {
	my $e = PPI::Exception->new('test message');
	is $e->message, 'test message', 'message() returns the message';
}


# ====== PPI::Exception::throw as class method ======

THROW_CLASS: {
	my $caught;
	eval { PPI::Exception->throw('class throw'); 1 };
	$caught = $@;
	ok _INSTANCE($caught, 'PPI::Exception'), 'class throw dies with PPI::Exception';
	is $caught->message, 'class throw', 'class throw sets message';
	my @callers = $caught->callers;
	ok scalar @callers >= 1, 'class throw records caller info';
}

THROW_CLASS_DEFAULT: {
	my $caught;
	eval { PPI::Exception->throw; 1 };
	$caught = $@;
	ok _INSTANCE($caught, 'PPI::Exception'), 'class throw with no args dies with PPI::Exception';
	is $caught->message, 'Unknown Exception', 'class throw with no args uses default message';
}


# ====== PPI::Exception::throw as instance method ======

THROW_INSTANCE: {
	my $e = PPI::Exception->new('instance throw');
	my $caught;
	eval { $e->throw; 1 };
	$caught = $@;
	ok _INSTANCE($caught, 'PPI::Exception'), 'instance throw dies with PPI::Exception';
	is $caught->message, 'instance throw', 'instance throw preserves message';
	my @callers = $caught->callers;
	ok scalar @callers >= 1, 'instance throw records caller info';
}


# ====== PPI::Exception::callers ======

CALLERS_BEFORE_THROW: {
	my $e = PPI::Exception->new('no throw');
	my @callers = $e->callers;
	is scalar @callers, 0, 'callers() is empty before throw';
}


# ====== Re-throw accumulates callers ======

RETHROW: {
	my $caught;
	eval { PPI::Exception->throw('rethrow test'); 1 };
	$caught = $@;
	my @callers_first = $caught->callers;
	eval { $caught->throw; 1 };
	$caught = $@;
	my @callers_second = $caught->callers;
	is scalar @callers_second, scalar @callers_first + 1, 're-throw adds to callers';
}


# ====== PPI::Exception::ParserRejection ======

PARSER_REJECTION_NEW: {
	my $e = PPI::Exception::ParserRejection->new('parser rejected');
	isa_ok $e, 'PPI::Exception::ParserRejection';
	isa_ok $e, 'PPI::Exception';
	is $e->message, 'parser rejected', 'ParserRejection sets message';
}

PARSER_REJECTION_THROW: {
	my $caught;
	eval { PPI::Exception::ParserRejection->throw('rejected'); 1 };
	$caught = $@;
	ok _INSTANCE($caught, 'PPI::Exception::ParserRejection'),
		'ParserRejection class throw dies with correct type';
	ok _INSTANCE($caught, 'PPI::Exception'),
		'ParserRejection isa PPI::Exception';
	is $caught->message, 'rejected', 'ParserRejection throw sets message';
	my @callers = $caught->callers;
	ok scalar @callers >= 1, 'ParserRejection throw records caller info';
}
