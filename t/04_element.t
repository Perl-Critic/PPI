#!/usr/bin/perl

# Formal testing for PPI

# This does an empiric test that when we try to parse something,
# something ( anything ) comes out the other side.

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	no warnings 'once';
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use PPI::Lexer ();

# Execute the tests
use Test::More tests => 221;
use Test::NoWarnings;
use Scalar::Util 'refaddr';

sub is_object {
	my ($left, $right, $message) = @_;
	$message ||= "Objects match";
	my $condition = (
		defined $left
		and ref $left,
		and defined $right,
		and ref $right,
		and refaddr($left) == refaddr($right)
		);
	ok( $condition, $message );
}

use vars qw{$RE_IDENTIFIER};
BEGIN {
	$RE_IDENTIFIER = qr/[^\W\d]\w*/;
}

sub omethod_fails {
	my $object  = ref($_[0])->isa('UNIVERSAL') ? shift : die "Failed to pass method_fails test an object";
	my $method  = (defined $_[0] and $_[0] =~ /$RE_IDENTIFIER/o) ? shift : die "Failed to pass method_fails an identifier";
	my $arg_set = ( ref $_[0] eq 'ARRAY' and scalar(@{$_[0]}) ) ? shift : die "Failed to pass method_fails a set of arguments";

	foreach my $args ( @$arg_set ) {
		is( $object->$method( $args ), undef, ref($object) . "->$method fails correctly" );
	}
}

sub pause {
	local $@;
	eval { require Time::HiRes; };
	$@ ? sleep(1) : Time::HiRes::sleep(0.1);
}





#####################################################################
# Miscellaneous

# Confirm that C< weaken( $hash{scalar} = $object ) > works as expected,
# adding a weak reference to the has index.
use Scalar::Util ();
SCOPE: {
	my %hash = ();
	my $counter = 0;

	SCOPE: {
		my $object1 = bless { }, 'My::WeakenTest';
		my $object2 = bless { }, 'My::WeakenTest';
		my $object3 = bless { }, 'My::WeakenTest';
		isa_ok( $object1, 'My::WeakenTest' );
		isa_ok( $object2, 'My::WeakenTest' );
		isa_ok( $object3, 'My::WeakenTest' );

		# Do nothing for object1.
		
		# Add object2 to a has index normally
		$hash{foo} = $object2;

		# Add object2 and weaken
		Scalar::Util::weaken($hash{bar} = $object3);
		ok( Scalar::Util::isweak( $hash{bar} ), 'index entry is weak' );
		ok( ! Scalar::Util::isweak( $object3 ), 'original is not weak' );

		pause();

		# Do all the objects still exist
		isa_ok( $object1, 'My::WeakenTest' );
		isa_ok( $object2, 'My::WeakenTest' );
		isa_ok( $object3, 'My::WeakenTest' );
		isa_ok( $hash{foo}, 'My::WeakenTest' );
		isa_ok( $hash{bar}, 'My::WeakenTest' );
	}
	pause();
	# Two of the three should have destroyed
	is( $counter, 2, 'Counter increments as expected normally' );

	# foo should still be there
	isa_ok( $hash{foo}, 'My::WeakenTest' );

	# bar should ->exists, but be undefined
	ok( exists $hash{bar}, 'weakened object hash slot exists' );
	ok( ! defined $hash{bar}, 'weakened object hash slot is undefined' );

	package My::WeakenTest;
	
	sub DESTROY {
		$counter++;
	}
}
	



# Test interaction between weaken and Clone
SCOPE: {
	my $object = { a => undef };
	# my $object = bless { a => undef }, 'Foo';
	my $object2 = $object;
	Scalar::Util::weaken($object2);
	my $clone = Clone::clone($object);
	is_deeply( $clone, $object, 'Object is cloned OK when a different reference is weakened' );
}





#####################################################################
# Prepare

# Build a basic source tree to test with
my $source   = 'my@foo =  (1,   2);';
my $Document = PPI::Lexer->lex_source( $source );
isa_ok( $Document, 'PPI::Document' );
is( $Document->content, $source, "Document round-trips ok" );
is( scalar($Document->tokens), 12, "Basic source contains the correct number of tokens" );
is( scalar(@{$Document->{children}}), 1, "Document contains one element" );
my $Statement = $Document->{children}->[0];
isa_ok( $Statement, 'PPI::Statement' );
isa_ok( $Statement, 'PPI::Statement::Variable' );
is( scalar(@{$Statement->{children}}), 7, "Statement contains the correct number of elements" );
my $Token1 = $Statement->{children}->[0];
my $Token2 = $Statement->{children}->[1];
my $Token3 = $Statement->{children}->[2];
my $Braces = $Statement->{children}->[5];
my $Token7 = $Statement->{children}->[6];
isa_ok( $Token1, 'PPI::Token::Word'   );
isa_ok( $Token2, 'PPI::Token::Symbol'     );
isa_ok( $Token3, 'PPI::Token::Whitespace' );
isa_ok( $Braces, 'PPI::Structure::List'   );
isa_ok( $Token7, 'PPI::Token::Structure'  );
ok( ($Token1->isa('PPI::Token::Word') and $Token1->content eq 'my'), 'First token is correct'   );
ok( ($Token2->isa('PPI::Token::Symbol') and $Token2->content eq '@foo'), 'Second token is correct'  );
ok( ($Token3->isa('PPI::Token::Whitespace') and $Token3->content eq ' '), 'Third token is correct'  );
is( $Braces->braces, '()', 'Braces seem correct' );
ok( ($Token7->isa('PPI::Token::Structure') and $Token7->content eq ';'), 'Seventh token is correct' );
isa_ok( $Braces->start, 'PPI::Token::Structure' );
ok( ($Braces->start->isa('PPI::Token::Structure') and $Braces->start->content eq '('),
	'Start brace token matches expected' );
isa_ok( $Braces->finish, 'PPI::Token::Structure' );
ok( ($Braces->finish->isa('PPI::Token::Structure') and $Braces->finish->content eq ')'),
	'Finish brace token matches expected' );





#####################################################################
# Testing of PPI::Element basic information methods

# Testing the ->content method
is( $Document->content,  $source,    "Document content is correct" );
is( $Statement->content, $source,    "Statement content is correct" );
is( $Token1->content,    'my',       "Token content is correct" );
is( $Token2->content,    '@foo',     "Token content is correct" );
is( $Token3->content,    ' ',        "Token content is correct" );
is( $Braces->content,    '(1,   2)', "Token content is correct" );
is( $Token7->content,    ';',        "Token content is correct" );

# Testing the ->tokens method
is( scalar($Document->tokens),  12, "Document token count is correct" );
is( scalar($Statement->tokens), 12, "Statement token count is correct" );
isa_ok( $Token1->tokens, 'PPI::Token',  "Token token count is correct" );
isa_ok( $Token2->tokens, 'PPI::Token',  "Token token count is correct" );
isa_ok( $Token3->tokens, 'PPI::Token',  "Token token count is correct" );
is( scalar($Braces->tokens),    6,  "Token token count is correct" );
isa_ok( $Token7->tokens, 'PPI::Token',  "Token token count is correct" );

# Testing the ->significant method
is( $Document->significant,  1,  'Document is significant' );
is( $Statement->significant, 1,  'Statement is significant' );
is( $Token1->significant,    1,  'Token is significant' );
is( $Token2->significant,    1,  'Token is significant' );
is( $Token3->significant,    '', 'Token is significant' );
is( $Braces->significant,    1,  'Token is significant' );
is( $Token7->significant,    1,  'Token is significant' );





#####################################################################
# Testing of PPI::Element navigation

# Test the ->parent method
is( $Document->parent, undef, "Document does not have a parent" );
is_object( $Statement->parent,  $Document,  "Statement sees document as parent" );
is_object( $Token1->parent,     $Statement, "Token sees statement as parent" );
is_object( $Token2->parent,     $Statement, "Token sees statement as parent" );
is_object( $Token3->parent,     $Statement, "Token sees statement as parent" );
is_object( $Braces->parent,     $Statement, "Braces sees statement as parent" );
is_object( $Token7->parent,     $Statement, "Token sees statement as parent" );

# Test the special case of parents for the Braces opening and closing braces
is_object( $Braces->start->parent, $Braces, "Start brace sees the PPI::Structure as it's parent" );
is_object( $Braces->finish->parent, $Braces, "Finish brace sees the PPI::Structure as it's parent" );

# Test the ->top method
is_object( $Document->top,  $Document, "Document sees itself as top" );
is_object( $Statement->top, $Document, "Statement sees document as top" );
is_object( $Token1->top,    $Document, "Token sees document as top" );
is_object( $Token2->top,    $Document, "Token sees document as top" );
is_object( $Token3->top,    $Document, "Token sees document as top" );
is_object( $Braces->top,    $Document, "Braces sees document as top" );
is_object( $Token7->top,    $Document, "Token sees document as top" );

# Test the ->document method
is_object( $Document->document,  $Document, "Document sees itself as document" );
is_object( $Statement->document, $Document, "Statement sees document correctly" );
is_object( $Token1->document,    $Document, "Token sees document correctly" );
is_object( $Token2->document,    $Document, "Token sees document correctly" );
is_object( $Token3->document,    $Document, "Token sees document correctly" );
is_object( $Braces->document,    $Document, "Braces sees document correctly" );
is_object( $Token7->document,    $Document, "Token sees document correctly" );

# Test the ->next_sibling method
is( $Document->next_sibling, '', "Document returns false for next_sibling" );
is( $Statement->next_sibling, '', "Statement returns false for next_sibling" );
is_object( $Token1->next_sibling, $Token2, "First token sees second token as next_sibling" );
is_object( $Token2->next_sibling, $Token3, "Second token sees third token as next_sibling" );
is_object( $Braces->next_sibling, $Token7, "Braces sees seventh token as next_sibling" );
is( $Token7->next_sibling, '', 'Last token returns false for next_sibling' );

# More extensive test for next_sibling
SCOPE: {
	my $doc = PPI::Document->new( \"sub foo { bar(); }" );
	my $end = $doc->last_token;
	isa_ok( $end, 'PPI::Token::Structure' );
	is( $end->content, '}', 'Got end token' );
	is( $end->next_sibling, '', '->next_sibling for an end closing brace returns false' );
	my $braces = $doc->find_first( sub {
		$_[1]->isa('PPI::Structure') and $_[1]->braces eq '()'
		} );
	isa_ok( $braces, 'PPI::Structure' );
	isa_ok( $braces->next_token, 'PPI::Token::Structure' );
	is( $braces->next_token->content, ';', 'Got the correct next_token for structure' );
}

# Test the ->previous_sibling method
is( $Document->previous_sibling,  '', "Document returns false for previous_sibling" );
is( $Statement->previous_sibling, '', "Statement returns false for previous_sibling" );
is( $Token1->previous_sibling,    '', "First token returns false for previous_sibling" );
is_object( $Token2->previous_sibling, $Token1, "Second token sees first token as previous_sibling" );
is_object( $Token3->previous_sibling, $Token2, "Third token sees second token as previous_sibling" );
is_object( $Token7->previous_sibling, $Braces, "Last token sees braces as previous_sibling" );

# More extensive test for next_sibling
SCOPE: {
	my $doc = PPI::Document->new( \"{ no strict; bar(); }" );
	my $start = $doc->first_token;
	isa_ok( $start, 'PPI::Token::Structure' );
	is( $start->content, '{', 'Got start token' );
	is( $start->previous_sibling, '', '->previous_sibling for an start opening brace returns false' );
	my $braces = $doc->find_first( sub {
		$_[1]->isa('PPI::Structure') and $_[1]->braces eq '()'
		} );
	isa_ok( $braces, 'PPI::Structure' );
	isa_ok( $braces->previous_token, 'PPI::Token::Word' );
	is( $braces->previous_token->content, 'bar', 'Got the correct previous_token for structure' );
}

# Test the ->snext_sibling method
my $Token4 = $Statement->{children}->[3];
is( $Document->snext_sibling, '', "Document returns false for snext_sibling" );
is( $Statement->snext_sibling, '', "Statement returns false for snext_sibling" );
is_object( $Token1->snext_sibling, $Token2, "First token sees second token as snext_sibling" );
is_object( $Token2->snext_sibling, $Token4, "Second token sees third token as snext_sibling" );
is_object( $Braces->snext_sibling, $Token7, "Braces sees seventh token as snext_sibling" );
is( $Token7->snext_sibling, '', 'Last token returns false for snext_sibling' );

# Test the ->sprevious_sibling method
is( $Document->sprevious_sibling,  '', "Document returns false for sprevious_sibling" );
is( $Statement->sprevious_sibling, '', "Statement returns false for sprevious_sibling" );
is( $Token1->sprevious_sibling,    '', "First token returns false for sprevious_sibling" );
is_object( $Token2->sprevious_sibling, $Token1, "Second token sees first token as sprevious_sibling" );
is_object( $Token3->sprevious_sibling, $Token2, "Third token sees second token as sprevious_sibling" );
is_object( $Token7->sprevious_sibling, $Braces, "Last token sees braces as sprevious_sibling" );

# Test snext_sibling and sprevious_sibling cases when inside a parent block
SCOPE: {
	my $cpan13454 = PPI::Document->new( \'{ 1 }' );
	isa_ok( $cpan13454, 'PPI::Document' );
	my $num = $cpan13454->find_first('Token::Number');
	isa_ok( $num, 'PPI::Token::Number' );
	my $prev = $num->sprevious_sibling;
	is( $prev, '', '->sprevious_sibling returns false' );
	my $next = $num->snext_sibling;
	is( $next, '', '->snext_sibling returns false' );
}





#####################################################################
# Test the PPI::Element and PPI::Node analysis methods

# Test the find method
SCOPE: {
	is( $Document->find('PPI::Token::End'), '', '->find returns false if nothing found' );
	isa_ok( $Document->find('PPI::Structure')->[0], 'PPI::Structure' );
	my $found = $Document->find('PPI::Token::Number');
	ok( $found, 'Multiple find succeeded' );
	is( ref $found, 'ARRAY', '->find returned an array' );
	is( scalar(@$found), 2, 'Multiple find returned expected number of items' );

	# Test for the ability to shorten the names
	$found = $Document->find('Token::Number');
	ok( $found, 'Multiple find succeeded' );
	is( ref $found, 'ARRAY', '->find returned an array' );
	is( scalar(@$found), 2, 'Multiple find returned expected number of items' );
}

# Test for CPAN #7799 - Unsupported element types are accepted by find
#
# The correct behaviour for a bad string is a warning, and return C<undef>
SCOPE: {
	local $^W = 0;
	is( $Document->find(undef), undef, '->find(undef) failed' );
	is( $Document->find([]),    undef, '->find([]) failed'    );
	is( $Document->find('Foo'), undef, '->find(BAD) failed'   );
}

# Test the find_first method
SCOPE: {
	is( $Document->find_first('PPI::Token::End'), '', '->find_first returns false if nothing found' );
	isa_ok( $Document->find_first('PPI::Structure'), 'PPI::Structure' );
	my $found = $Document->find_first('PPI::Token::Number');
	ok( $found, 'Multiple find_first succeeded' );
	isa_ok( $found, 'PPI::Token::Number' );

	# Test for the ability to shorten the names
	$found = $Document->find_first('Token::Number');
	ok( $found, 'Multiple find_first succeeded' );
	isa_ok( $found, 'PPI::Token::Number' );
}

# Test the find_any method
SCOPE: {
	is( $Document->find_any('PPI::Token::End'), '', '->find_any returns false if nothing found' );
	is( $Document->find_any('PPI::Structure'), 1, '->find_any returns true is something found' );
	is( $Document->find_any('PPI::Token::Number'), 1, '->find_any returns true for multiple find' );
	is( $Document->find_any('Token::Number'), 1, '->find_any returns true for shortened multiple find' );
}

# Test the contains method
SCOPE: {
	omethod_fails( $Document, 'contains', [ undef, '', 1, [], bless( {}, 'Foo') ] );
	my $found = $Document->find('PPI::Element');
	is( ref $found, 'ARRAY', '(preparing for contains tests) ->find returned an array' );
	is( scalar(@$found), 15, '(preparing for contains tests) ->find returns correctly for all elements' );
	foreach my $Element ( @$found ) {
		is( $Document->contains( $Element ), 1, 'Document contains ' . ref($Element) . ' known to be in it' );
	}
	shift @$found;
	foreach my $Element ( @$found ) {
		is( $Document->contains( $Element ), 1, 'Statement contains ' . ref($Element) . ' known to be in it' );
	}
}





#####################################################################
# Test the PPI::Element manipulation methods

# Cloning an Element/Node
SCOPE: {
	my $Doc2 = $Document->clone;
	isa_ok( $Doc2, 'PPI::Document' );
	isa_ok( $Doc2->schild(0), 'PPI::Statement' );
	is_object( $Doc2->schild(0)->parent, $Doc2, 'Basic parent links stay intact after ->clone' );
	is_object( $Doc2->schild(0)->schild(3)->start->document, $Doc2,
		'Clone goes deep, and Structure braces get relinked properly' );
	isnt( refaddr($Document), refaddr($Doc2),
		'Cloned Document has a different memory location' );
	isnt( refaddr($Document->schild(0)), refaddr($Doc2->schild(0)),
		'Cloned Document has children at different memory locations' );
}

# Delete the second token
ok( $Token2->delete, "Deletion of token 2 returns true" );
is( $Document->content, 'my =  (1,   2);', "Content is modified correctly" );
is( scalar($Document->tokens), 11, "Modified source contains the correct number of tokens" );
ok( ! defined $Token2->parent, "Token 2 is detached from parent" );

# Delete the braces
ok( $Braces->delete, "Deletion of braces returns true" );
is( $Document->content, 'my =  ;', "Content is modified correctly" );
is( scalar($Document->tokens), 5, "Modified source contains the correct number of tokens" );
ok( ! defined $Braces->parent, "Braces are detached from parent" );





#####################################################################
# Test DESTROY

# Start with DESTROY for an element that never has a parent
SCOPE: {
	my $Token = PPI::Token::Whitespace->new( ' ' );
	my $k1 = scalar keys %PPI::Element::_PARENT;
	$Token->DESTROY;
	my $k2 = scalar keys %PPI::Element::_PARENT;
	is( $k1, $k2, '_PARENT key count remains unchanged after naked Element DESTROY' );
}

# Next, a single element within a parent
SCOPE: {
	my $k1 = scalar keys %PPI::Element::_PARENT;
	my $k2;
	my $k3;
	SCOPE: {
		my $Token     = PPI::Token::Number->new( '1' );
		my $Statement = PPI::Statement->new;
		$Statement->add_element( $Token );
		$k2 = scalar keys %PPI::Element::_PARENT;
		is( $k2, $k1 + 1, 'PARENT keys increases after adding element' );
		$Statement->DESTROY;
	}
	pause();
	$k3 = scalar keys %PPI::Element::_PARENT;
	is( $k3, $k1, 'PARENT keys returns to original on DESTROY' );
}

# Repeat for an entire (large) file
SCOPE: {
	my $k1 = scalar keys %PPI::Element::_PARENT;
	my $k2;
	my $k3;
	SCOPE: {
		my $NodeDocument = PPI::Document->new( $INC{"PPI/Node.pm"} );
		isa_ok( $NodeDocument, 'PPI::Document' );
		$k2 = scalar keys %PPI::Element::_PARENT;
		ok( $k2 > ($k1 + 3000), 'PARENT keys increases after loading document' );
		$NodeDocument->DESTROY;
	}
	pause();
	$k3 = scalar keys %PPI::Element::_PARENT;
	is( $k3, $k1, 'PARENT keys returns to original on explicit Document DESTROY' );
}

# Repeat again, but with an implicit DESTROY
SCOPE: {
	my $k1 = scalar keys %PPI::Element::_PARENT;
	my $k2;
	my $k3;
	SCOPE: {
		my $NodeDocument = PPI::Document->new( $INC{"PPI/Node.pm"} );
		isa_ok( $NodeDocument, 'PPI::Document' );
		$k2 = scalar keys %PPI::Element::_PARENT;
		ok( $k2 > ($k1 + 3000), 'PARENT keys increases after loading document' );
	}
	pause();
	$k3 = scalar keys %PPI::Element::_PARENT;
	is( $k3, $k1, 'PARENT keys returns to original on implicit Document DESTROY' );
}





#####################################################################
# Token-related methods

# Test first_token, last_token, next_token and previous_token
SCOPE: {
my $code = <<'END_PERL';
my $foo = bar();

sub foo {
	my ($foo, $bar, undef) = ('a', shift(@_), 'bar');
	return [ $foo, $bar ];
}
END_PERL
	# Trim off the trailing newline to test last_token better
	$code =~ s/\s+$//s;

	# Create the document
	my $doc = PPI::Document->new( \$code );
	isa_ok( $doc, 'PPI::Document' );

	# Basic first_token and last_token using a single non-trival sample
	### FIXME - Make this more thorough
	my $first_token = $doc->first_token;
	isa_ok( $first_token, 'PPI::Token::Word' );
	is( $first_token->content, 'my', '->first_token works as expected' );
	my $last_token = $doc->last_token;
	isa_ok( $last_token, 'PPI::Token::Structure' );
	is( $last_token->content, '}', '->last_token works as expected' );

	# Test next_token
	is( $last_token->next_token, '', 'last->next_token returns false' );
	is( $doc->next_token,        '', 'doc->next_token returns false'  );
	my $next_token = $first_token->next_token;
	isa_ok( $next_token, 'PPI::Token::Whitespace' );
	is( $next_token->content, ' ', 'Trivial ->next_token works as expected' );
	my $counter = 1;
	my $token   = $first_token;
	while ( $token = $token->next_token ) {
		$counter++;
	}
	is( $counter, scalar($doc->tokens),
		'->next_token iterated the expected number of times for a sample document' );

	# Test previous_token
	is( $first_token->previous_token, '', 'last->previous_token returns false' );
	is( $doc->previous_token,         '', 'doc->previous_token returns false'  );
	my $previous_token = $last_token->previous_token;
	isa_ok( $previous_token, 'PPI::Token::Whitespace' );
	is( $previous_token->content, "\n", 'Trivial ->previous_token works as expected' );
	$counter = 1;
	$token   = $last_token;
	while ( $token = $token->previous_token ) {
		$counter++;
	}
	is( $counter, scalar($doc->tokens),
		'->previous_token iterated the expected number of times for a sample document' );
}

#####################################################################
#  Simple overload tests

# Make sure the 'use overload' is working on Element subclasses

SCOPE: {
   my $source   = '1;';
   my $Document = PPI::Lexer->lex_source( $source );
   isa_ok( $Document, 'PPI::Document' );
   ok($Document eq $source, 'overload eq');
   ok($Document ne 'foo', 'overload ne');
   ok($Document == $Document, 'overload ==');
   ok($Document != $Document->schild(0), 'overload !=');
}
