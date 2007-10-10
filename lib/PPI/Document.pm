package PPI::Document;

=pod

=head1 NAME

PPI::Document - Object representation of a Perl document

=head1 INHERITANCE

  PPI::Document
  isa PPI::Node
      isa PPI::Element

=head1 SYNOPSIS

  use PPI;
  
  # Load a document from a file
  my $Document = PPI::Document->new('My/Module.pm');
  
  # Strip out comments
  $Document->prune('PPI::Token::Comment');
  
  # Find all the named subroutines
  my @subs = $Document->find( 
  	sub { $_[1]->isa('PPI::Statement::Sub') and $_[1]->name }
  	);
  
  # Save the file
  $Document->save('My/Module.pm.stripped');

=head1 DESCRIPTION

The C<PPI::Document> class represents a single Perl "document". A
C<PPI::Document> object acts as a root L<PPI::Node>, with some
additional methods for loading and saving, and working with
the line/column locations of Elements within a file.

The exemption to its L<PPI::Node>-like behavior this is that a
C<PPI::Document> object can NEVER have a parent node, and is always
the root node in a tree.

=head2 Storable Support

C<PPI::Document> implements the necessary C<STORABLE_freeze> and
C<STORABLE_thaw> hooks to provide native support for L<Storable>,
if you have it installed.

However if you want to clone clone a Document, you are highly recommended
to use the internal C<$Document-E<gt>clone> method rather than Storable's
C<dclone> function (although C<dclone> should still work).

=head1 METHODS

Most of the things you are likely to want to do with a Document are
probably going to involve the methods from L<PPI::Node> class, of which
this is a subclass.

The methods listed here are the remaining few methods that are truly
Document-specific.

=cut

use strict;
use base 'PPI::Node';
use Carp                          ();
use List::MoreUtils               ();
use Params::Util                  '_INSTANCE',
                                  '_SCALAR';
use Digest::MD5                   ();
use PPI                           ();
use PPI::Util                     ();
use PPI::Document::Fragment       ();
use PPI::Exception::ParserTimeout ();
use overload 'bool'               => sub () { 1 };
use overload '""'                 => 'content';
use constant HAS_ALARM            => (
	$^O eq 'MSWin32' or $^O eq 'cygwin'
	) ? 0 : 1;

use vars qw{$VERSION $errstr};
BEGIN {
	$VERSION = '1.199_06';
	$errstr  = '';
}

# Document cache
my $CACHE = undef;





#####################################################################
# Constructor and Static Methods

=pod

=head2 new

  # Simple construction
  $doc = PPI::Document->new( $filename );
  $doc = PPI::Document->new( \$source  );
  
  # With the readonly attribute set
  $doc = PPI::Document->new( $filename,
          readonly => 1,
          );

The C<new> constructor takes as argument a variety of different sources of
Perl code, and creates a single cohesive Perl C<PPI::Document>
for it.

If passed a file name as a normal string, it will attempt to load the
document from the file.

If passed a reference to a C<SCALAR>, this is taken to be source code and
parsed directly to create the document.

If passed zero arguments, a "blank" document will be created that contains
no content at all.

In all cases, the document is considered to be "anonymous" and not tied back
to where it was created from. Specifically, if you create a PPI::Document from
a filename, the document will B<not> remember where it was created from.

The constructor also takes attribute flags.

At this time, the only available attribute is the C<readonly> flag.

Setting C<readonly> to true will allow various systems to provide
additional optimisations and caching. Note that because C<readonly> is an
optimisation flag, it is off by default and you will need to explicitly
enable it.

Returns a C<PPI::Document> object, or C<undef> if parsing fails.

=cut

sub new {
	local $_; # An extra one, just in case
	my $class = ref $_[0] ? ref shift : shift;

	unless ( @_ ) {
		my $self = $class->SUPER::new;
		$self->{readonly}  = ! 1;
		$self->{tab_width} = 1;
		return $self;
	}

	# Check constructor attributes
	my $source  = shift;
	my %attr    = @_;
	my $timeout = delete $attr{timeout};
	if ( $timeout and ! HAS_ALARM ) {
		Carp::croak("This platform does not support PPI parser timeouts");
	}

	# Check the data source
	if ( ! defined $source ) {
		$class->_error("An undefined value was passed to PPI::Document::new");

	} elsif ( ! ref $source ) {
		# Catch people using the old API
		if ( $source =~ /(?:\012|\015)/ ) {
			Carp::croak("API CHANGE: Source code should only be passed to PPI::Document->new as a SCALAR reference");
		}

		# When loading from a filename, use the caching layer if it exists.
		if ( $CACHE ) {
			my $file   = $source;
			my $source = PPI::Util::_slurp( $file );
			unless ( ref $source ) {
				# Errors returned as plain string
				return $class->_error($source);
			}

			# Retrieve the document from the cache
			my $document = $CACHE->get_document($source);
			return $class->_setattr( $document, %attr ) if $document;

			if ( $timeout ) {
				eval {
					local $SIG{ALRM} = sub { die "alarm\n" };
					alarm( $timeout );
					$document = PPI::Lexer->lex_source( $$source );
					alarm( 0 );
				};
			} else {
				$document = PPI::Lexer->lex_source( $$source );
			}
			if ( $document ) {
				# Save in the cache
				$CACHE->store_document( $document );
				return $class->_setattr( $document, %attr );
			}
		} else {
			if ( $timeout ) {
				eval {
					local $SIG{ALRM} = sub { die "alarm\n" };
					alarm( $timeout );
					my $document = PPI::Lexer->lex_file( $source );
					return $class->_setattr( $document, %attr ) if $document;
					alarm( 0 );
				};
			} else {
				my $document = PPI::Lexer->lex_file( $source );
				return $class->_setattr( $document, %attr ) if $document;
			}
		}

	} elsif ( _SCALAR($source) ) {
		if ( $timeout ) {
			eval {
				local $SIG{ALRM} = sub { die "alarm\n" };
				alarm( $timeout );
				my $document = PPI::Lexer->lex_source( $$source );
				return $class->_setattr( $document, %attr ) if $document;
				alarm( 0 );
			}
		} else {
			my $document = PPI::Lexer->lex_source( $$source );
			return $class->_setattr( $document, %attr ) if $document;
		}

	} else {
		$class->_error("An unknown object or reference was passed to PPI::Document::new");
	}

	# Pull and store the error from the lexer
	my $errstr;
	if ( _INSTANCE($@, 'PPI::Exception::Timeout') ) {
		$errstr = 'Timed out while parsing document';
	} elsif ( _INSTANCE($@, 'PPI::Exception') ) {
		$errstr = $@->message;
	} elsif ( $@ ) {
		$errstr = $@;
		$errstr =~ s/\sat line\s.+$//;
	} elsif ( PPI::Lexer->errstr ) {
		$errstr = PPI::Lexer->errstr;
	} else {
		$errstr = "Unknown error parsing Perl document";
	}
	PPI::Lexer->_clear;
	$class->_error( $errstr );
}

sub load {
	Carp::croak("API CHANGE: File names should now be passed to PPI::Document->new to load a file");
}

sub _setattr {
	my ($class, $document, %attr) = @_;
	$document->{readonly} = !! $attr{readonly};
	return $document;
}

=pod

=head2 set_cache $cache

As of L<PPI> 1.100, C<PPI::Document> supports parser caching.

The default cache class L<PPI::Cache> provides a L<Storable>-based
caching or the parsed document based on the MD5 hash of the document as
a string.

The static C<set_cache> method is used to set the cache object for
C<PPI::Document> to use when loading documents. It takes as argument
a L<PPI::Cache> object (or something that C<isa> the same).

If passed C<undef>, this method will stop using the current cache, if any.

For more information on caching, see L<PPI::Cache>.

Returns true on success, or C<undef> if not passed a valid param.

=cut

sub set_cache {
	my $class  = ref $_[0] ? ref shift : shift;

	if ( defined $_[0] ) {
		# Enable the cache
		my $object = _INSTANCE(shift, 'PPI::Cache') or return undef;
		$CACHE = $object;
	} else {
		# Disable the cache
		$CACHE = undef;
	}

	1;
}

=pod

=head2 get_cache

If a document cache is currently set, the C<get_cache> method will
return it.

Returns a L<PPI::Cache> object, or C<undef> if there is no cache
currently set for C<PPI::Document>.

=cut

sub get_cache {
	$CACHE;	
}





#####################################################################
# PPI::Document Instance Methods

=pod

=head2 readonly

The C<readonly> attribute indicates if the document is intended to be
read-only, and will never be modified. This is an advisory flag, that
writers of L<PPI>-related systems may or may not use to enable
optimisations and caches for your document.

Returns true if the document is read-only or false if not.

=cut

sub readonly {
	$_[0]->{readonly};
}

=pod

=head2 tab_width [ $width ]

In order to handle support for C<location> correctly, C<Documents>
need to understand the concept of tabs and tab width. The C<tab_width>
method is used to get and set the size of the tab width.

At the present time, PPI only supports "naive" (width 1) tabs, but we do
plan on supporting arbitrary, default and auto-sensing tab widths later.

Returns the tab width as an integer, or C<die>s if you attempt to set the
tab width.

=cut

sub tab_width {
	my $self = shift;
	return $self->{tab_width} unless @_;
	$self->{tab_width} = shift;
}

=pod

=head2 save

  $document->save( $file )
 
The C<save> method serializes the C<PPI::Document> object and saves the
resulting Perl document to a file. Returns C<undef> on failure to open
or write to the file.

=cut

sub save {
	my $self = shift;
	local *PPIOUTPUT;
	open( PPIOUTPUT, ">", $_[0] )    or return undef;
	print PPIOUTPUT $self->serialize or return undef;
	close PPIOUTPUT                  or return undef;
	1;
}

=pod

=head2 serialize

Unlike the C<content> method, which shows only the immediate content
within an element, Document objects also have to be able to be written
out to a file again.

When doing this we need to take into account some additional factors.

Primarily, we need to handle here-docs correctly, so that are written
to the file in the expected place.

The C<serialize> method generates the actual file content for a given
Document object. The resulting string can be written straight to a file.

Returns the serialized document as a string.

=cut

sub serialize {
	my $self   = shift;
	my @Tokens = $self->tokens;

	# The here-doc content buffer
	my $heredoc = '';

	# Start the main loop
	my $output = '';
	foreach my $i ( 0 .. $#Tokens ) {
		my $Token = $Tokens[$i];

		# Handle normal tokens
		unless ( $Token->isa('PPI::Token::HereDoc') ) {
			my $content = $Token->content;

			# Handle the trivial cases
			unless ( $heredoc ne '' and $content =~ /\n/ ) {
				$output .= $content;
				next;
			}

			# We have pending here-doc content that needs to be
			# inserted just after the first newline in the content.
			if ( $content eq "\n" ) {
				# Shortcut the most common case for speed
				$output .= $content . $heredoc;
			} else {
				# Slower and more general version
				$content =~ s/\n/\n$heredoc/;
				$output .= $content;
			}

			$heredoc = '';
			next;
		}

		# This token is a HereDoc.
		# First, add the token content as normal, which in this
		# case will definately not contain a newline.
		$output .= $Token->content;

		# Now add all of the here-doc content to the heredoc buffer.
		foreach my $line ( $Token->heredoc ) {
			$heredoc .= $line;
		}

		if ( $Token->{_damaged} ) {
			# Special Case:
			# There are a couple of warning/bug situations
			# that can occur when a HereDoc content was read in
			# from the end of a file that we silently allow.
			#
			# When writing back out to the file we have to
			# auto-repair these problems if we arn't going back
			# on to the end of the file.

			# When calculating $last_line, ignore the final token if
			# and only if it has a single newline at the end.
			my $last_index = $#Tokens;
			if ( $Tokens[$last_index]->{content} =~ /^[^\n]*\n$/ ) {
				$last_index--;
			}

			# This is a two part test.
			# First, are we on the last line of the
			# content part of the file
			my $last_line = List::MoreUtils::none {
				$Tokens[$_] and $Tokens[$_]->{content} =~ /\n/
				} (($i + 1) .. $last_index);
			if ( ! defined $last_line ) {
				# Handles the null list case
				$last_line = 1;
			}

			# Secondly, are their any more here-docs after us,
			# (with content or a terminator)
			my $any_after = List::MoreUtils::any {
				$Tokens[$_]->isa('PPI::Token::HereDoc')
				and (
					scalar(@{$Tokens[$_]->{_heredoc}})
					or
					defined $Tokens[$_]->{_terminator_line}
					)
				} (($i + 1) .. $#Tokens);
			if ( ! defined $any_after ) {
				# Handles the null list case
				$any_after = '';
			}

			# We don't need to repair the last here-doc on the
			# last line. But we do need to repair anything else.
			unless ( $last_line and ! $any_after ) {
				# Add a terminating string if it didn't have one
				unless ( defined $Token->{_terminator_line} ) {
					$Token->{_terminator_line} = $Token->{_terminator};
				}

				# Add a trailing newline to the terminating
				# string if it didn't have one.
				unless ( $Token->{_terminator_line} =~ /\n$/ ) {
					$Token->{_terminator_line} .= "\n";
				}
			}
		}

		# Now add the termination line to the heredoc buffer
		if ( defined $Token->{_terminator_line} ) {
			$heredoc .= $Token->{_terminator_line};
		}
	}

	# End of tokens

	if ( $heredoc ne '' ) {
		# If the file doesn't end in a newline, we need to add one
		# so that the here-doc content starts on the next line.
		unless ( $output =~ /\n$/ ) {
			$output .= "\n";
		}

		# Now we add the remaining here-doc content
		# to the end of the file.
		$output .= $heredoc;
	}

	$output;
}

=pod

=head2 hex_id

The C<hex_id> method generates an unique identifier for the Perl document.

This identifier is basically just the serialized document, with
Unix-specific newlines, passed through MD5 to produce a hexadecimal string.

This identifier is used by a variety of systems (such as L<PPI::Cache>
and L<Perl::Metrics>) as a unique key against which to store or cache
information about a document (or indeed, to cache the document itself).

Returns a 32 character hexadecimal string.

=cut

sub hex_id {
	my $self = shift;
	PPI::Util::md5hex($self->serialize);
}

=pod

=head2 index_locations

Within a document, all L<PPI::Element> objects can be considered to have a
"location", a line/column position within the document when considered as a
file. This position is primarily useful for debugging type activities.

The method for finding the position of a single Element is a bit laborious,
and very slow if you need to do it a lot. So the C<index_locations> method
will index and save the locations of every Element within the Document in
advance, making future calls to <PPI::Element::location> virtually free.

Please note that this is index should always be cleared using
C<flush_locations> once you are finished with the locations. If content is
added to or removed from the file, these indexed locations will be B<wrong>.

=cut

sub index_locations {
	my $self   = shift;
	my @Tokens = $self->tokens;

	# Whenever we hit a heredoc we will need to increment by
	# the number of lines in it's content section when when we
	# encounter the next token with a newline in it.
	my $heredoc = 0;

	# Find the first Token without a location
	my ($first, $location) = ();
	foreach ( 0 .. $#Tokens ) {
		my $Token = $Tokens[$_];
		next if $Token->{_location};

		# Found the first Token without a location
		# Calculate the new location if needed.
		$location = $_
			? $self->_add_location( $location, $Tokens[$_ - 1], \$heredoc )
			: [ 1, 1, 1 ];
		$first = $_;
		last;
	}

	# Calculate locations for the rest
	foreach ( $first .. $#Tokens ) {
		my $Token = $Tokens[$_];
		$Token->{_location} = $location;
		$location = $self->_add_location( $location, $Token, \$heredoc );

		# Add any here-doc lines to the counter
		if ( $Token->isa('PPI::Token::HereDoc') ) {
			$heredoc += $Token->heredoc + 1;
		}
	}

	1;
}

sub _add_location {
	my ($self, $start, $Token, $heredoc) = @_;
	my $content = $Token->{content};

	# Does the content contain any newlines
	my $newlines =()= $content =~ /\n/g;
	unless ( $newlines ) {
		# Handle the simple case
		return [
			$start->[0],
			$start->[1] + length($content),
			$start->[2] + $self->_visual_length($content, $start->[2])
		];
	}

	# This is the more complex case where we hit or
	# span a newline boundary.
	my $location = [ $start->[0] + $newlines, 1, 1 ];
	if ( $heredoc and $$heredoc ) {
		$location->[0] += $$heredoc;
		$$heredoc = 0;
	}

	# Does the token have additional characters
	# after their last newline.
	if ( $content =~ /\n([^\n]+?)\z/ ) {
		$location->[1] += length($1);
		$location->[2] += $self->_visual_length($1, $location->[2]);
	}

	$location;
}

sub _visual_length {
	my ($self, $content, $pos) = @_;

	my $tab_width = $self->tab_width;
	my ($length, $vis_inc);

	return length $content if $content !~ /\t/;

	# Split the content in tab and non-tab parts and calculate the
	# "visual increase" of each part.
	for my $part ( split(/(\t)/, $content) ) {
		if ($part eq "\t") {
			$vis_inc = $tab_width - ($pos-1) % $tab_width;
		}
		else {
			$vis_inc = length $part;
		}
		$length += $vis_inc;
		$pos    += $vis_inc;
	}

	$length;
}

=pod

=head2 flush_locations

When no longer needed, the C<flush_locations> method clears all location data
from the tokens.

=cut

sub flush_locations {
	shift->_flush_locations(@_);
}

=pod

=head2 normalized

The C<normalized> method is used to generate a "Layer 1"
L<PPI::Document::Normalized> object for the current Document.

A "normalized" Perl Document is an arbitrary structure that removes any
irrelevant parts of the document and refactors out variations in style,
to attempt to approach something that is closer to the "true meaning"
of the Document.

See L<PPI::Normal> for more information on document normalization and
the tasks for which it is useful.

Returns a L<PPI::Document::Normalized> object, or C<undef> on error.

=cut

sub normalized {
	my $self = shift;

	# The normalization process will utterly destroy and mangle
	# anything passed to it, so we are going to only give it a
	# clone of ourself.
	my $Document = $self->clone or return undef;

	# Create the normalization object and execute it
	PPI::Normal->process( $Document );
}





#####################################################################
# PPI::Node Methods

# We are a scope boundary
### XS -> PPI/XS.xs:_PPI_Document__scope 0.903+
sub scope { 1 }





#####################################################################
# PPI::Element Methods

# Is the document complete.
# Cascase to the last significant child
sub complete {
	my $self  = shift;
	my $child = $self->schild(-1);
	return !! (
		$child
		and
		$child->complete
	);
}

sub insert_before {
	return undef;
	# die "Cannot insert_before a PPI::Document";
}

sub insert_after {
	return undef;
	# die "Cannot insert_after a PPI::Document";
}

sub replace {
	return undef;
	# die "Cannot replace a PPI::Document";
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

For error that occur when loading and saving documents, you can use
C<errstr>, as either a static or object method, to access the error message.

If a Document loads or saves without error, C<errstr> will return false.

=cut

sub errstr {
	$errstr;
}





#####################################################################
# Native Storable Support

sub STORABLE_freeze {
	my $self  = shift;
	my $class = ref $self;
	my %hash  = %$self;
	return ($class, \%hash);
}

sub STORABLE_thaw {
	my ($self, undef, $class, $hash) = @_;
	bless $self, $class;
	foreach ( keys %$hash ) {
		$self->{$_} = delete $hash->{$_};
	}
	$self->__link_children;
}

1;

=pod

=head1 TO DO

- May need to overload some methods to forcefully prevent Document
objects becoming children of another Node.

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<PPI>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2001 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
