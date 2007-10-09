package PPI::Lexer;

=pod

=head1 NAME

PPI::Lexer - The PPI Lexer

=head1 SYNOPSIS

  use PPI;
  
  # Create a new Lexer
  my $Lexer = PPI::Lexer->new;
  
  # Build a PPI::Document object from a Token stream
  my $Tokenizer = PPI::Tokenizer->load( 'My/Module.pm' );
  my $Document = $Lexer->lex_tokenizer( $Tokenizer );
  
  # Build a PPI::Document object for some raw source
  my $source = "print 'Hello World!'; kill(Humans->all);";
  $Document = $Lexer->lex_source( $source );
  
  # Build a PPI::Document object for a particular file name
  $Document = $Lexer->lex_file( 'My/Module.pm' );

=head1 DESCRIPTION

The is the PPI Lexer. In the larger scheme of things, its job is to take
token streams, in a variety of forms, and "lex" them into nested structures.

Pretty much everything in this module happens behind the scenes at this
point. In fact, at the moment you don't really need to instantiate the lexer
at all, the three main methods will auto-instantiate themselves a
C<PPI::Lexer> object as needed.

All methods do a one-shot "lex this and give me a L<PPI::Document> object".

In fact, if you are reading this, what you B<probably> want to do is to
just "load a document", in which case you can do this in a much more
direct and concise manner with one of the following.

  use PPI;
  
  $Document = PPI::Document->load( $filename );
  $Document = PPI::Document->new( $string );

See L<PPI::Document> for more details.

For more unusual tasks, by all means forge onwards.

=head1 METHODS

=cut

use strict;
use Params::Util  '_INSTANCE';
use PPI           ();
use PPI::Token    ();
use PPI::Document ();

use vars qw{$VERSION $errstr};
BEGIN {
	$VERSION = '1.199_05';
	$errstr  = '';
}





#####################################################################
# Constructor

=pod

=head2 new

The C<new> constructor creates a new C<PPI::Lexer> object. The object itself
is merely used to hold various buffers and state data during the lexing
process, and holds no significant data between -E<gt>lex_xxxxx calls.

Returns a new C<PPI::Lexer> object

=cut

sub new {
	my $class = shift->_clear;
	bless {
		Tokenizer => undef, # Where we store the tokenizer for a run
		buffer    => [],    # The input token buffer
		delayed   => [],    # The "delayed insignificant tokens" buffer
		}, $class;
}





#####################################################################
# Main Lexing Methods

=pod

=head2 lex_file $filename

The C<lex_file> method takes a filename as argument. It then loads the file,
creates a L<PPI::Tokenizer> for the content and lexes the token stream
produced by the tokenizer. Basically, a sort of all-in-one method for
getting a L<PPI::Document> object from a file name.

Returns a L<PPI::Document> object, or C<undef> on error.

=cut

sub lex_file {
	my $self = ref $_[0] ? shift : shift->new;
	my $file = (defined $_[0] and ! ref $_[0]) ? shift
		: return $self->_error(
		"Did not pass a filename to PPI::Lexer::lex_file"
		);

	# Create the Tokenizer and hand off
	my $Tokenizer = PPI::Tokenizer->new( $file );
	unless ( $Tokenizer ) {
		# Import the tokenizer error
		my $errstr = PPI::Tokenizer->errstr
			|| "Unknown error creating PPI::Tokenizer";
		PPI::Tokenizer->_clear;
		return $self->_error( $errstr );
	}

	$self->lex_tokenizer( $Tokenizer );
}

=pod

=head2 lex_source $string

The C<lex_source> method takes a normal scalar string as argument. It
creates a L<PPI::Tokenizer> object for the string, and then lexes the
resulting token stream.

Returns a L<PPI::Document> object, or C<undef> on error.

=cut

sub lex_source {
	my $self   = ref $_[0] ? shift : shift->new;
	my $source = (defined $_[0] and ! ref $_[0]) ? shift
		: return $self->_error(
		"Did not pass a string to PPI::Lexer::lex_source"
		);

	# Create the Tokenizer and hand off to the next method
	my $Tokenizer = PPI::Tokenizer->new( \$source );
	unless ( $Tokenizer ) {
		# Import the tokenizer error
		my $errstr = PPI::Tokenizer->errstr
			|| "Unknown error creating PPI::Tokenizer";
		PPI::Tokenizer->_clear;
		return $self->_error( $errstr );
	}

	$self->lex_tokenizer( $Tokenizer );
}

=pod

=head2 lex_tokenizer $Tokenizer

The C<lex_tokenizer> takes as argument a L<PPI::Tokenizer> object. It
lexes the token stream from the tokenizer into a L<PPI::Document> object.

Returns a L<PPI::Document> object, or C<undef> on error.

=cut

sub lex_tokenizer {
	my $self      = ref $_[0] ? shift : shift->new;
	my $Tokenizer = _INSTANCE(shift, 'PPI::Tokenizer')
		or return $self->_error(
		"Did not pass a PPI::Tokenizer object to PPI::Lexer::lex_tokenizer"
		);

	# Create the empty document
	my $Document = PPI::Document->new;

	# Lex the token stream into the document
	$self->{Tokenizer} = $Tokenizer;
	my $rv = $self->_lex_document( $Document );
	$self->{Tokenizer} = undef;
	return $Document if $rv;

	# If an error occurs, DESTROY the partially built document.
	$Document->DESTROY;
	undef;
}





#####################################################################
# Lex Methods - Document Object

sub _lex_document {
	my $self     = shift;
	my $Document = _INSTANCE(shift, 'PPI::Document') or return undef;

	# Start the processing loop
	my $Token;
	while ( $Token = $self->_get_token ) {
		# Add insignificant tokens directly beneath us
		unless ( $Token->significant ) {
			$self->_add_element( $Document, $Token ) or return undef;
			next;
		}

		if ( $Token->content eq ';' ) {
			# It's a semi-colon on it's own.
			# We call this a null statement.
			my $Statement = PPI::Statement::Null->new( $Token ) or return undef;
			$self->_add_element( $Document, $Statement )        or return undef;
			next;
		}

		# Handle anything other than a structural element
		unless ( ref $Token eq 'PPI::Token::Structure' ) {
			# Determine the class for the Statement, and create it
			my $_class = $self->_resolve_new_statement($Document, $Token) or return undef;
			my $Statement = $_class->new( $Token ) or return undef;

			# Move the lexing down into the statement
			$self->_add_delayed( $Document )    or return undef;
			$self->_add_element( $Document, $Statement ) or return undef;
			$self->_lex_statement( $Statement ) or return undef;

			next;
		}

		# Is this the opening of a structure?
		if ( $Token->__LEXER__opens ) {
			# This should actually have a Statement instead
			$self->_rollback( $Token );
			my $Statement = PPI::Statement->new          or return undef;
			$self->_add_element( $Document, $Statement ) or return undef;
			$self->_lex_statement( $Statement )          or return undef;
			next;
		}

		# Is this the close of a structure.
		if ( $Token->__LEXER__closes ) {
			# Because we are at the top of the tree, this is an error.
			# This means either a mis-parsing, or an mistake in the code.
			# To handle this, we create a "Naked Close" statement
			my $UnmatchedBrace = PPI::Statement::UnmatchedBrace->new( $Token ) or return undef;
			$self->_add_element( $Document, $UnmatchedBrace ) or return undef;
			next;
		}

		# Shouldn't be able to get here
		return undef;
	}

	# Did we leave the main loop because of a Tokenizer error?
	unless ( defined $Token ) {
		my $errstr = $self->{Tokenizer} ? $self->{Tokenizer}->errstr : '';
		$errstr ||= 'Unknown Tokenizer error';
		return $self->_error( $errstr );
	}

	# No error, it's just the end of file.
	# Add any insignificant trailing tokens.
	$self->_add_delayed( $Document );
}





#####################################################################
# Lex Methods - Statement Object

use vars qw{%STATEMENT_CLASSES};
BEGIN {
	# Keyword -> Statement Subclass
	%STATEMENT_CLASSES = (
		# Things that affect the timing of execution
		'BEGIN'    => 'PPI::Statement::Scheduled',
		'CHECK'    => 'PPI::Statement::Scheduled',
		'INIT'     => 'PPI::Statement::Scheduled',
		'END'      => 'PPI::Statement::Scheduled',

		# Loading and context statement
		'package'  => 'PPI::Statement::Package',
		'use'      => 'PPI::Statement::Include',
		'no'       => 'PPI::Statement::Include',
		'require'  => 'PPI::Statement::Include',

		# Various declarations
		'my'       => 'PPI::Statement::Variable',
		'local'    => 'PPI::Statement::Variable',
		'our'      => 'PPI::Statement::Variable',
		# Statements starting with 'sub' could be any one of...
		# 'sub'    => 'PPI::Statement::Sub',
		# 'sub'    => 'PPI::Statement::Scheduled',
		# 'sub'    => 'PPI::Statement',

		# Compound statement
		'if'       => 'PPI::Statement::Compound',
		'unless'   => 'PPI::Statement::Compound',
		'for'      => 'PPI::Statement::Compound',
		'foreach'  => 'PPI::Statement::Compound',
		'while'    => 'PPI::Statement::Compound',
		'until'    => 'PPI::Statement::Compound',

		# Various ways of breaking out of scope
		'redo'     => 'PPI::Statement::Break',
		'next'     => 'PPI::Statement::Break',
		'last'     => 'PPI::Statement::Break',
		'return'   => 'PPI::Statement::Break',
                'goto'     => 'PPI::Statement::Break',

		# Special sections of the file
		'__DATA__' => 'PPI::Statement::Data',
		'__END__'  => 'PPI::Statement::End',
		);
}

sub _resolve_new_statement {
	my ($self, $Parent, $Token) = @_;
	# my $self   = shift;
	# my $Parent = _INSTANCE(shift, 'PPI::Node')  or die "Bad param 1";
	# my $Token  = _INSTANCE(shift, 'PPI::Token') or die "Bad param 2";

	# Check for things like ( parent => ... )
	if ( $Parent->isa('PPI::Structure::List') ) {
		if ( $Token->isa('PPI::Token::Word') ) {
			# Is the next significant token a =>
			# Read ahead to the next significant token
			my $Next;
			while ( $Next = $self->_get_token ) {
				unless ( $Next->significant ) {
					$self->_delay_element( $Next ) or return undef;
					next;
				}

				# Got the next token
				if ( $Next->isa('PPI::Token::Operator') and $Next->content eq '=>' ) {
					# Is an ordinary expression
					$self->_rollback( $Next );
					return 'PPI::Statement::Expression';
				} else {
					last;
				}
			}

			# Rollback and continue
			$self->_rollback( $Next );
		}
	}

	# Is it a token in our known classes list
	my $class = $STATEMENT_CLASSES{$Token->content};

	# Handle potential barewords for subscripts
	if ( $Parent->isa('PPI::Structure::Subscript') ) {
		# Fast obvious case, just an expression
		unless ( $class and $class->isa('PPI::Statement::Expression') ) {
			return 'PPI::Statement::Expression';
		}

		# This is something like "my" or "our" etc... more subtle.
		# Check if the next token is a closing curly brace.
		# This means we are something like $h{my}
		my $Next;
		while ( $Next = $self->_get_token ) {
			unless ( $Next->significant ) {
				$self->_delay_element( $Next ) or return undef;
				next;
			}

			# Found the next significant token.
			# Is it a closing curly brace?
			if ( $Next->content eq '}' ) {
				$self->_rollback( $Next );
				return 'PPI::Statement::Expression';
			} else {
				$self->_rollback( $Next );
				return $class;
			}
		}

		# End of file... this means it is something like $h{our
		# which is probably going to be $h{our} ... I think
		$self->_rollback( $Next );
		return 'PPI::Statement::Expression';
	}

	# If it's a token in our list, use that class
	return $class if $class;

	# Handle the more in-depth sub detection
	if ( $Token->content eq 'sub' ) {
		# Read ahead to the next significant token
		my $Next;
		while ( $Next = $self->_get_token ) {
			unless ( $Next->significant ) {
				$self->_delay_element( $Next ) or return undef;
				next;
			}

			# Got the next significant token
			my $_class = $STATEMENT_CLASSES{$Next->content};
			if ( $_class and $_class eq 'PPI::Statement::Scheduled' ) {
				$self->_rollback( $Next );
				return 'PPI::Statement::Scheduled';
			}
			if ( $Next->isa('PPI::Token::Word') ) {
				$self->_rollback( $Next );
				return 'PPI::Statement::Sub';
			}

			### Comment out these two, as they would return PPI::Statement anyway
			# if ( $content eq '{' ) {
			#	Anonymous sub at start of statement
			#	return 'PPI::Statement';
			# }
			#
			# if ( $Next->isa('PPI::Token::Prototype') ) {
			#	Anonymous sub at start of statement
			#	return 'PPI::Statement';
			# }

			# PPI::Statement is the safest fall-through
			$self->_rollback( $Next );
			return 'PPI::Statement';
		}

		# End of file... PPI::Statement::Sub is the most likely
		$self->_rollback( $Next );
		return 'PPI::Statement::Sub';
	}

	# If our parent is a Condition, we are an Expression
	if ( $Parent->isa('PPI::Structure::Condition') ) {
		return 'PPI::Statement::Expression';
	}

	# If our parent is a List, we are also an expression
	if ( $Parent->isa('PPI::Structure::List') ) {
		return 'PPI::Statement::Expression';
	}

	if ( _INSTANCE($Token, 'PPI::Token::Label') ) {
		return 'PPI::Statement::Compound';
	}

	# Beyond that, I have no idea for the moment.
	# Just keep adding more conditions above this.
	'PPI::Statement';
}

sub _lex_statement {
	my ($self, $Statement) = @_;
	# my $self      = shift;
	# my $Statement = _INSTANCE(shift, 'PPI::Statement') or die "Bad param 1";

	# Handle some special statements
	if ( $Statement->isa('PPI::Statement::End') ) {
		return $self->_lex_statement_end( $Statement );
	}

	# Begin processing tokens
	my $Token;
	while ( $Token = $self->_get_token ) {
		# Delay whitespace and comment tokens
		unless ( $Token->significant ) {
			$self->_delay_element( $Token ) or return undef;
			next;
		}

		# Structual closes, and __DATA__ and __END__ tags implicitly
		# end every type of statement
		if ( $Token->__LEXER__closes or $Token->isa('PPI::Token::Separator') ) {
			# Rollback and end the statement
			return $self->_rollback( $Token );
		}

		# Normal statements never implicitly end
		unless ( $Statement->__LEXER__normal ) {
			# Have we hit an implicit end to the statement
			unless ( $self->_statement_continues( $Statement, $Token ) ) {
				# Rollback and finish the statement
				return $self->_rollback( $Token );
			}
		}

		# Any normal character just gets added
		unless ( $Token->isa('PPI::Token::Structure') ) {
			$self->_add_element( $Statement, $Token ) or return undef;
			next;
		}

		# Handle normal statement terminators
		if ( $Token->content eq ';' ) {
			$self->_add_element( $Statement, $Token ) or return undef;
			return 1;
		}

		# Which leaves us with a new structure

		# Determine the class for the structure and create it
		my $sclass = $self->_resolve_new_structure($Statement, $Token) or return undef;
		my $Structure = $sclass->new( $Token ) or return undef;

		# Move the lexing down into the Structure
		$self->_add_delayed( $Statement )   or return undef;
		$self->_add_element( $Statement, $Structure ) or return undef;
		$self->_lex_structure( $Structure ) or return undef;
	}

	# Was it an error in the tokenizer?
	return undef unless defined $Token;

	# No, it's just the end of the file...
	# Roll back any insignificant tokens, they'll get added at the Document level
	$self->_rollback;
}

sub _lex_statement_end {
	my $self      = shift;
	my $Statement = _INSTANCE(shift, 'PPI::Statement::End') or die "Bad param 1";

	# End of the file, EVERYTHING is ours
	my $Token;
	while ( $Token = $self->_get_token ) {
		$Statement->__add_element( $Token );
	}

	# Was it an error in the tokenizer?
	return undef unless defined $Token;

	# No, it's just the end of the file...
	# Roll back any insignificant tokens, they'll get added at the Document level
	$self->_rollback;
}

# For many statements, it can be dificult to determine the end-point.
# This method takes a statement and the next significant token, and attempts
# to determine if the there is a statement boundary between the two, or if
# the statement can continue with the token.
sub _statement_continues {
	my ($self, $Statement, $Token) = @_;
	# my $self      = shift;
	# my $Statement = _INSTANCE(shift, 'PPI::Statement') or die "Bad param 1";
	# my $Token     = _INSTANCE(shift, 'PPI::Token')     or die "Bad param 2";

	# Handle the simple block case
	# { print 1; }
	if ( $Statement->schildren == 1 and $Statement->schild(0)->isa('PPI::Structure::Block') ) {
		return '';
	}

	# Alrighty then, there are only three implied end statement types,
	# ::Scheduled blocks, ::Sub declarations, and ::Compound statements.
	unless ( ref($Statement) =~ /\b(?:Scheduled|Sub|Compound)$/ ) {
		return 1;
	}

	# Of these three, ::Scheduled and ::Sub both follow the same simple
	# rule and can be handled first.
	my @part      = $Statement->schildren;
	my $LastChild = $part[-1] or return undef;
	unless ( $Statement->isa('PPI::Statement::Compound') ) {
		# If the last significant element of the statement is a block,
		# then a scheduled statement is done, no questions asked.
		return ! $LastChild->isa('PPI::Structure::Block');
	}

	# Now we get to compound statements, which kind of suck (to lex).
	# However, of them all, the 'if' type, which includes unless, are
	# relatively easy to handle compared to the others.
	my $type = $Statement->type or return undef;
	if ( $type eq 'if' ) {
		# This should be one of the following
		# if (EXPR) BLOCK
		# if (EXPR) BLOCK else BLOCK
		# if (EXPR) BLOCK elsif (EXPR) BLOCK ... else BLOCK

		# We only implicitly end on a block
		unless ( $LastChild->isa('PPI::Structure::Block') ) {
			# if (EXPR) ...
			# if (EXPR) BLOCK else ...
			# if (EXPR) BLOCK elsif (EXPR) BLOCK ...
			return 1;
		}

		# If the token before the block is an 'else',
		# it's over, no matter what.
		my $NextLast = $Statement->schild(-2);
		if (
			$NextLast
			and
			$NextLast->isa('PPI::Token')
			and
			$NextLast->isa('PPI::Token::Word')
			and
			$NextLast->content eq 'else'
		) {
			return '';
		}

		# Otherwise, we continue for 'elsif' or 'else' only.
		if (
			$Token->isa('PPI::Token::Word')
			and (
				$Token->content eq 'else'
				or
				$Token->content eq 'elsif'
			)
		) {
			return 1;
		}

		return '';
	}

	if ( $type eq 'label' ) {
		# We only have the label so far, could be any of
		# LABEL while (EXPR) BLOCK
		# LABEL while (EXPR) BLOCK continue BLOCK
		# LABEL for (EXPR; EXPR; EXPR) BLOCK
		# LABEL foreach VAR (LIST) BLOCK
		# LABEL foreach VAR (LIST) BLOCK continue BLOCK
		# LABEL BLOCK continue BLOCK

		# Handle cases with a word after the label
		if ( $Token->isa('PPI::Token::Word')
		and $Token->content =~ /^(?:while|for|foreach)$/ ) {
			return 1;
		}

		# Handle labelled blocks
		if ( $Token->isa('PPI::Token::Structure') && $Token->content eq '{' ) {
			return 1;
		}

		return '';
	}

	# Handle the common "after round braces" case
	if ( $LastChild->isa('PPI::Structure') and $LastChild->braces eq '()' ) {
		# LABEL while (EXPR) ...
		# LABEL while (EXPR) ...
		# LABEL for (EXPR; EXPR; EXPR) ...
		# LABEL foreach VAR (LIST) ...
		# LABEL foreach VAR (LIST) ...
		# Only a block will do
		return $Token->isa('PPI::Token::Structure') && $Token->content eq '{';
	}

	if ( $type eq 'for' ) {
		# LABEL for (EXPR; EXPR; EXPR) BLOCK
		if ( $LastChild->isa('PPI::Token::Word') and $LastChild->content eq 'for' ) {
			# LABEL for ...
			if ( $Token->isa('PPI::Token::Structure') && $Token->content eq '(' ) {
				return 1;
			}

			# In this case, we can also behave like a foreach
			$type = 'foreach';

		} elsif ( $LastChild->isa('PPI::Structure::Block') ) {
			# LABEL for (EXPR; EXPR; EXPR) BLOCK
			# That's it, nothing can continue
			return '';
		}
	}

	# Handle the common continue case
	if ( $LastChild->isa('PPI::Token::Word') and $LastChild->content eq 'continue' ) {
		# LABEL while (EXPR) BLOCK continue ...
		# LABEL foreach VAR (LIST) BLOCK continue ...
		# LABEL BLOCK continue ...
		# Only a block will do
		return $Token->isa('PPI::Token::Structure') && $Token->content eq '{';
	}

	# Handle the common continuable block case
	if ( $LastChild->isa('PPI::Structure::Block') ) {
		# LABEL while (EXPR) BLOCK
		# LABEL while (EXPR) BLOCK ...
		# LABEL for (EXPR; EXPR; EXPR) BLOCK
		# LABEL foreach VAR (LIST) BLOCK
		# LABEL foreach VAR (LIST) BLOCK ...
		# LABEL BLOCK ...
		# Is this the block for a continue?
		if ( _INSTANCE($part[-2], 'PPI::Token::Word') and $part[-2]->content eq 'continue' ) {
			# LABEL while (EXPR) BLOCK continue BLOCK
			# LABEL foreach VAR (LIST) BLOCK continue BLOCK
			# LABEL BLOCK continue BLOCK
			# That's it, nothing can continue this
			return '';
		}

		# Only a continue will do
		return $Token->isa('PPI::Token::Word') && $Token->content eq 'continue';
	}

	if ( $type eq 'block' ) {
		# LABEL BLOCK continue BLOCK
		# Every possible case is covered in the common cases above
	}

	if ( $type eq 'while' ) {
		# LABEL while (EXPR) BLOCK
		# LABEL while (EXPR) BLOCK continue BLOCK
		# LABEL until (EXPR) BLOCK
		# LABEL until (EXPR) BLOCK continue BLOCK
		# The only case not covered is the while ...
		if ( $LastChild->isa('PPI::Token::Word') and $LastChild->content eq 'while' or $LastChild->content eq 'until' ) {
			# LABEL while ...
			# LABEL until ...
			# Only a condition structure will do
			return $Token->isa('PPI::Token::Structure') && $Token->content eq '(';
		}
	}

	if ( $type eq 'foreach' ) {
		# LABEL foreach VAR (LIST) BLOCK
		# LABEL foreach VAR (LIST) BLOCK continue BLOCK
		# The only two cases that have not been covered already are
		# 'foreach ...' and 'foreach VAR ...'
		return undef unless $LastChild->isa('PPI::Token');

		if ( $LastChild->isa('PPI::Token::Symbol') ) {
			# LABEL foreach my $scalar ...
			# Only an open round brace will do
			return $Token->isa('PPI::Token::Structure') && $Token->content eq '(';
		}

		if ( $LastChild->content eq 'foreach' or $LastChild->content eq 'for' ) {
			# There are three possibilities here
			if ( $Token->isa('PPI::Token::Word') and $Token->content eq 'my' ) {
				# VAR == 'my ...'
				return 1;
			} elsif ( $Token->content =~ /^\$/ ) {
				# VAR == '$scalar'
				return 1;
			} elsif ( $Token->isa('PPI::Token::Structure') and $Token->content eq '(' ) {
				return 1;
			} else {
				return '';
			}
		}

		if ( $LastChild->content eq 'my' ) {
			# LABEL foreach my ...
			# Only a scalar will do
			return $Token->content =~ /^\$/;
		}
	}

	# Something we don't know about... what could it be
	warn("Illegal parse state in '$type' type compound statement");
	return undef;
}





#####################################################################
# Lex Methods - Structure Object

use vars qw{%ROUND_CLASSES};
BEGIN {
	# Keyword -> Structure class maps
	%ROUND_CLASSES = (
		# Conditions
		'if'     => 'PPI::Structure::Condition',
		'elsif'  => 'PPI::Structure::Condition',
		'unless' => 'PPI::Structure::Condition',
		'while'  => 'PPI::Structure::Condition',
		'until'  => 'PPI::Structure::Condition',

		# For(each)
		'for'     => 'PPI::Structure::ForLoop',
		'foreach' => 'PPI::Structure::ForLoop',
		);
}

# Given a parent element, and a token which will open a structure, determine
# the class that the structure should be.
sub _resolve_new_structure {
	# my $self   = shift;
	# my $Parent = _INSTANCE(shift, 'PPI::Node')             or die "Bad param 1";
	# my $Token  = _INSTANCE(shift, 'PPI::Token::Structure') or die "Bad param 2";
	my ($self, $Parent, $Token) = @_;

	return $self->_resolve_new_structure_round ($Parent) if $Token->content eq '(';
	return $self->_resolve_new_structure_square($Parent) if $Token->content eq '[';
	return $self->_resolve_new_structure_curly ($Parent) if $Token->content eq '{';
	undef;
}

# Given a parent element, and a ( token to open a structure, determine
# the class that the structure should be.
sub _resolve_new_structure_round {
	# my $self   = shift;
	# my $Parent = _INSTANCE(shift, 'PPI::Node') or die "Bad param 1";
	my ($self, $Parent) = @_;

	# Get the last significant element in the parent
	my $Element = $Parent->schild(-1);
	if ( _INSTANCE($Element, 'PPI::Token::Word') ) {
		# Can it be determined because it is a keyword?
		if ( $ROUND_CLASSES{$Element->content} ) {
			return $ROUND_CLASSES{$Element->content};
		}
	}

	# If we are part of a for or foreach statement, we are a ForLoop
	if ( $Parent->isa('PPI::Statement::Compound') and $Parent->type =~ /^for(?:each)?$/ ) {
		return 'PPI::Structure::ForLoop';
	}

	# Otherwise, it must be a list

	# If the previous element is -> then we mark it as a dereference
	if ( _INSTANCE($Element, 'PPI::Token::Operator') and $Element->content eq '->' ) {
		$Element->{_dereference} = 1;
	}

	'PPI::Structure::List'
}

# Given a parent element, and a [ token to open a structure, determine
# the class that the structure should be.
sub _resolve_new_structure_square {
	# my $self   = shift;
	# my $Parent = _INSTANCE(shift, 'PPI::Node') or die "Bad param 1";
	my ($self, $Parent) = @_;

	# Get the last significant element in the parent
	my $Element = $Parent->schild(-1);

	# Is this a subscript, like $foo[1] or $foo{expr}
	
	if ( $Element ) {
		if ( $Element->isa('PPI::Token::Operator') and $Element->content eq '->' ) {
			# $foo->[]
			$Element->{_dereference} = 1;
			return 'PPI::Structure::Subscript';
		}
		if ( $Element->isa('PPI::Structure::Subscript') ) {
			# $foo{}[]
			return 'PPI::Structure::Subscript';
		}
		if ( $Element->isa('PPI::Token::Symbol') and $Element->content =~ /^(?:\$|\@)/ ) {
			# $foo[], @foo[]
			return 'PPI::Structure::Subscript';
		}
		# FIXME - More cases to catch
	}

	# Otherwise, we assume that it's an anonymous arrayref constructor
	'PPI::Structure::Constructor';
}

use vars qw{%CURLY_CLASSES};
BEGIN {
	# Keyword -> Structure class maps
	%CURLY_CLASSES = (
		# Blocks
		'sub'  => 'PPI::Structure::Block',
		'grep' => 'PPI::Structure::Block',
		'map'  => 'PPI::Structure::Block',
		'sort' => 'PPI::Structure::Block',
		'do'   => 'PPI::Structure::Block',

		# Hash constructors
		'='    => 'PPI::Structure::Constructor',
		'||='  => 'PPI::Structure::Constructor',
		','    => 'PPI::Structure::Constructor',
		'=>'   => 'PPI::Structure::Constructor',
		
		);
}

# Given a parent element, and a { token to open a structure, determine
# the class that the structure should be.
sub _resolve_new_structure_curly {
	my ($self, $Parent) = @_;
	# my $self   = shift;
	# my $Parent = _INSTANCE(shift, 'PPI::Node') or die "Bad param 1";

	# Get the last significant element in the parent
	my $Element = $Parent->schild(-1);
	my $content = $Element ? $Element->content : '';

	# Is this a subscript, like $foo[1] or $foo{expr}
	if ( $Element ) {
		if ( $content eq '->' and $Element->isa('PPI::Token::Operator') ) {
			# $foo->{}
			$Element->{_dereference} = 1;
			return 'PPI::Structure::Subscript';
		}
		if ( $Element->isa('PPI::Structure::Subscript') ) {
			# $foo[]{}
			return 'PPI::Structure::Subscript';
		}
		if ( $Element->isa('PPI::Token::Symbol') and $content =~ /^(?:\$|\@)/ ) {
			# $foo{}, @foo{}
			return 'PPI::Structure::Subscript';
		}
		if ( $CURLY_CLASSES{$content} ) {
			# Known type
			return $CURLY_CLASSES{$content};
		}
	}

	# Are we in a compound statement
	if ( $Parent->isa('PPI::Statement::Compound') ) {
		# We will only encounter blocks in compound statements
		return 'PPI::Structure::Block';
	}

	# Are we the second argument of use
	if ( $Parent->isa('PPI::Statement::Include') ) {
		if ( $Parent->schildren == 2 ) {
			# This is something like use constant { ... };
			return 'PPI::Structure::Constructor';
		}
	}

	# Unless we are at the start of the statement, everything else should be a block
	### FIXME This is possibly a bad choice, but will have to do for now.
	if ( $Element ) {
		return 'PPI::Structure::Block';
	}

	# Special case: Are we the param of a core function
	# i.e. map({ $_ => 1 } @foo)
	if (
		$Parent->isa('PPI::Statement')
		and
		_INSTANCE($Parent->parent, 'PPI::Structure::List')
	) {
		my $function = $Parent->parent->parent->schild(-2);
		if ( $function and $function->content =~ /^(?:map|grep|sort)$/ ) {
			return 'PPI::Structure::Block';
		}
	}

	# We need to scan ahead.
	my $Next;
	my $position = 0;
	my @delayed  = ();
	while ( $Next = $self->_get_token ) {
		unless ( $Next->significant ) {
			push @delayed, $Next;
			next;
		}

		# If a closing curly, this is an anonymous hash-ref
		if ( ++$position == 1 and $Next->content eq '}' ) {
			$self->_buffer( splice( @delayed ), $Next );
			return 'PPI::Structure::Constructor';
		}

		# If it contains a => as the second thing,
		# this is also an anonymous hash-ref.
		if ( $position == 2 and $Next->content eq '=>' ) {
			$self->_buffer( splice( @delayed ), $Next );
			return 'PPI::Structure::Constructor';
		}

		# We only check the first two, then default to block
		if ( $position >= 3 ) {
			$self->_buffer( splice( @delayed ), $Next );
			last;
		}

		# Delay and continue
		push @delayed, $Next;
	}

	# Hit the end of the document, or bailed out, go with block
	$self->_buffer( splice @delayed );
	if ( ref($Parent) eq 'PPI::Statement' ) {
		bless $Parent, 'PPI::Statement::Compound';
	}
	return 'PPI::Structure::Block';
}

sub _lex_structure {
	my ($self, $Structure) = @_;
	# my $self      = shift;
	# my $Structure = _INSTANCE(shift, 'PPI::Structure') or die "Bad param 1";

	# Start the processing loop
	my $Token;
	while ( $Token = $self->_get_token ) {
		# Is this a direct type token
		unless ( $Token->significant ) {
			$self->_delay_element( $Token ) or return undef;
			next;
		}

		# Anything other than a Structure starts a Statement
		unless ( $Token->isa('PPI::Token::Structure') ) {
			# Because _resolve_new_statement may well delay and
			# rollback itself, we need to add the delayed tokens early
			$self->_add_delayed( $Structure ) or return undef;

			# Determine the class for the Statement and create it
			my $_class = $self->_resolve_new_statement($Structure, $Token) or return undef;
			my $Statement = $_class->new( $Token )        or return undef;

			# Move the lexing down into the Statement
			$self->_add_element( $Structure, $Statement ) or return undef;
			$self->_lex_statement( $Statement )           or return undef;

			next;
		}

		# Is this the opening of another structure directly inside us?
		if ( $Token->__LEXER__opens ) {
			# Rollback the Token, and recurse into the statement
			$self->_rollback( $Token );
			my $Statement = PPI::Statement->new          or return undef;
			$self->_add_element( $Structure, $Statement ) or return undef;
			$self->_lex_statement( $Statement )          or return undef;
			next;
		}

		# Is this the close of a structure ( which would be an error )
		if ( $Token->__LEXER__closes ) {
			# Is this OUR closing structure
			if ( $Token->content eq $Structure->start->__LEXER__opposite ) {
				# Add any delayed tokens, and the finishing token
				$self->_add_delayed( $Structure ) or return undef;
				$Structure->_set_finish( $Token ) or return undef;
				return 1;
			}

			# Unmatched closing brace.
			# Either they typed the wrong thing, or haven't put
			# one at all. Either way it's an error we need to
			# somehow handle gracefully. For now, we'll treat it
			# as implicitly ending the structure. This causes the
			# least damage across the various reasons why this
			# might have happened.
			warn('Unexpected closing brace') if $self->{warnings};
			return $self->_rollback( $Token );
		}

		# It's a semi-colon on it's own, just inside the block.
		# This is a null statement.
		my $Statement = PPI::Statement::Null->new( $Token ) or return undef;
		$self->_add_element( $Structure, $Statement ) or return undef;
	}

	# Is this an error
	return undef unless defined $Token;

	# No, it's just the end of file.
	# Add any insignificant trailing tokens.
	$self->_add_delayed( $Structure );
}





#####################################################################
# Support Methods

# Get the next token for processing, handling buffering
sub _get_token {
	my $self = shift;
	$self->{Tokenizer} or return undef;

	# First from the buffer
	if ( @{$self->{buffer}} ) {
		# Take from the front, add to the end
		return shift @{$self->{buffer}};
	}

	# Then from the Tokenizer
	$self->{Tokenizer}->get_token;
}

# Delay the addition of a insignificant elements
sub _delay_element {
	# my $self    = shift;
	# my $Element = _INSTANCE(shift, 'PPI::Element') or die "Bad param 1";

	# Take from the front, add to the end
	push @{ $_[0]->{delayed} }, $_[1];
}

# Add an Element to a Node, including any delayed Elements
sub _add_element {
	my ($self, $Parent, $Element) = @_;
	# my $self    = shift;
	# my $Parent  = _INSTANCE(shift, 'PPI::Node')    or die "Bad param 1";
	# my $Element = _INSTANCE(shift, 'PPI::Element') or die "Bad param 2";

	# Handle a special case, where a statement is not fully resolved
	if ( ref $Parent eq 'PPI::Statement' ) {
		my $first  = $Parent->schild(0);
		my $second = $Parent->schild(1);
		if ( $first and $first->isa('PPI::Token::Label') and ! $second ) {
			# It's a labelled statement
			if ( $STATEMENT_CLASSES{$second->content} ) {
				bless $Parent, $STATEMENT_CLASSES{$second->content};
			}
		}
	}

	# Add first the delayed, from the front, then the passed element
	foreach my $el ( @{$self->{delayed}}, $Element ) {
		$Parent->__add_element( $el );
	}

	# Clear the delayed elements if needed
	$self->{delayed} = [] if @{$self->{delayed}};

	1;
}

# Specifically just add any delayed tokens, if any.
sub _add_delayed {
	my ($self, $Parent) = @_;
	# my $self   = shift;
	# my $Parent = _INSTANCE(shift, 'PPI::Node') or die "Bad param 1";

	# Add any delayed
	foreach my $el ( @{$self->{delayed}} ) {
		$Parent->__add_element($el);
	}

	# Clear the delayed elements
	$self->{delayed} = [];
	1;
}

# Rollback the delayed tokens, plus any passed. Once all the tokens
# have been moved back on to the buffer, the order should be.
# <--- @{$self->{delayed}}, @_, @{$self->{buffer}} <----
sub _rollback {
	my $self = shift;

	# First, put any passed objects back
	if ( @_ ) {
		unshift @{$self->{buffer}}, splice @_;
	}

	# Then, put back anything delayed
	if ( @{$self->{delayed}} ) {
		unshift @{$self->{buffer}}, splice @{$self->{delayed}};
	}

	1;
}

# Partial rollback, just return a single list to the buffer
sub _buffer {
	my $self = shift;

	# Put any passed objects back
	if ( @_ ) {
		unshift @{$self->{buffer}}, splice @_;
	}

	1;
}





#####################################################################
# Error Handling

# Set the error message
sub _error {
	$errstr = $_[1];
	undef;
}

# Clear the error message.
# Returns the object as a convenience.
sub _clear {
	$errstr = '';
	$_[0];
}

=pod

=head2 errstr

For any error that occurs, you can use the C<errstr>, as either
a static or object method, to access the error message.

If no error occurs for any particular action, C<errstr> will return false.

=cut

sub errstr {
	$errstr;
}





#####################################################################
# PDOM Extensions
#
# This is something of a future expansion... ignore it for now :)
#
# use PPI::Statement::Sub ();
#
# sub PPI::Statement::Sub::__LEXER__normal { '' }

1;

=pod

=head1 TO DO

- Add optional support for some of the more common source filters

- Some additional checks for blessing things into various Statement
and Structure subclasses.

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
