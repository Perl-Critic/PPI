#!/usr/bin/perl

# Basic first pass API testing for PPI

use strict;
use Test::More;
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
	if ( $ENV{RELEASE_TESTING} ) {
		plan( tests => 2931 );
	} else {
		plan( skip_all => 'Author tests not required for installation' );
	}
}
use File::Spec::Functions ':ALL';
use Test::NoWarnings;
use Test::ClassAPI;
use PPI;
use PPI::Dumper;
use PPI::Find;
use PPI::Transform;

# Ignore various imported or special functions
$Test::ClassAPI::IGNORE{'DESTROY'}++;
$Test::ClassAPI::IGNORE{'refaddr'}++;
$Test::ClassAPI::IGNORE{'reftype'}++;
$Test::ClassAPI::IGNORE{'blessed'}++;

# Execute the tests
Test::ClassAPI->execute('complete', 'collisions');
exit(0);

# Now, define the API for the classes
__DATA__

# Explicitly list the core classes
PPI=class
PPI::Tokenizer=class
PPI::Lexer=class
PPI::Dumper=class
PPI::Find=class
PPI::Transform=abstract
PPI::Normal=class

# The abstract PDOM classes
PPI::Element=abstract
PPI::Node=abstract
PPI::Token=abstract
PPI::Token::_QuoteEngine=abstract
PPI::Token::_QuoteEngine::Simple=abstract
PPI::Token::_QuoteEngine::Full=abstract
PPI::Token::Quote=abstract
PPI::Token::QuoteLike=abstract
PPI::Token::Regexp=abstract
PPI::Structure=abstract
PPI::Statement=abstract









#####################################################################
# PDOM Classes

[PPI::Element]
new=method
clone=method
parent=method
descendant_of=method
ancestor_of=method
top=method
document=method
statement=method
next_sibling=method
snext_sibling=method
previous_sibling=method
sprevious_sibling=method
first_token=method
last_token=method
next_token=method
previous_token=method
insert_before=method
insert_after=method
remove=method
delete=method
replace=method
content=method
tokens=method
significant=method
location=method
line_number=method
column_number=method
visual_column_number=method
logical_line_number=method
logical_filename=method
class=method

[PPI::Node]
PPI::Element=isa
scope=method
add_element=method
elements=method
first_element=method
last_element=method
children=method
schildren=method
child=method
schild=method
contains=method
find=method
find_any=method
find_first=method
remove_child=method
prune=method

[PPI::Token]
PPI::Element=isa
new=method
add_content=method
set_class=method
set_content=method
length=method

[PPI::Token::Whitespace]
PPI::Token=isa
null=method
tidy=method

[PPI::Token::Pod]
PPI::Token=isa
lines=method
merge=method

[PPI::Token::Data]
PPI::Token=isa
handle=method

[PPI::Token::End]
PPI::Token=isa

[PPI::Token::Comment]
PPI::Token=isa
line=method

[PPI::Token::Word]
PPI::Token=isa
literal=method
method_call=method

[PPI::Token::Separator]
PPI::Token::Word=isa

[PPI::Token::Label]
PPI::Token=isa

[PPI::Token::Structure]
PPI::Token=isa

[PPI::Token::Number]
PPI::Token=isa
base=method
literal=method

[PPI::Token::Symbol]
PPI::Token=isa
canonical=method
symbol=method
raw_type=method
symbol_type=method

[PPI::Token::ArrayIndex]
PPI::Token=isa

[PPI::Token::Operator]
PPI::Token=isa

[PPI::Token::Magic]
PPI::Token=isa
PPI::Token::Symbol=isa

[PPI::Token::Cast]
PPI::Token=isa

[PPI::Token::Prototype]
PPI::Token=isa
prototype=method

[PPI::Token::Attribute]
PPI::Token=isa
identifier=method
parameters=method

[PPI::Token::DashedWord]
PPI::Token=isa
literal=method

[PPI::Token::HereDoc]
PPI::Token=isa
heredoc=method
terminator=method

[PPI::Token::_QuoteEngine]

[PPI::Token::_QuoteEngine::Simple]
PPI::Token::_QuoteEngine=isa

[PPI::Token::_QuoteEngine::Full]
PPI::Token::_QuoteEngine=isa

[PPI::Token::Quote]
PPI::Token=isa
string=method

[PPI::Token::Quote::Single]
PPI::Token=isa
PPI::Token::Quote=isa
literal=method

[PPI::Token::Quote::Double]
PPI::Token=isa
PPI::Token::Quote=isa
interpolations=method
simplify=method

[PPI::Token::Quote::Literal]
PPI::Token=isa
literal=method

[PPI::Token::Quote::Interpolate]
PPI::Token=isa

[PPI::Token::QuoteLike]
PPI::Token=isa

[PPI::Token::QuoteLike::Backtick]
PPI::Token=isa
PPI::Token::_QuoteEngine::Simple=isa

[PPI::Token::QuoteLike::Command]
PPI::Token=isa
PPI::Token::_QuoteEngine::Full=isa

[PPI::Token::QuoteLike::Words]
PPI::Token=isa
PPI::Token::_QuoteEngine::Full=isa
literal=method

[PPI::Token::QuoteLike::Regexp]
PPI::Token=isa
PPI::Token::_QuoteEngine::Full=isa
get_match_string=method
get_substitute_string=method
get_modifiers=method
get_delimiters=method

[PPI::Token::QuoteLike::Readline]
PPI::Token=isa
PPI::Token::_QuoteEngine::Full=isa

[PPI::Token::Regexp]
PPI::Token=isa
PPI::Token::_QuoteEngine::Full=isa
get_match_string=method
get_substitute_string=method
get_modifiers=method
get_delimiters=method

[PPI::Token::Regexp::Match]
PPI::Token=isa

[PPI::Token::Regexp::Substitute]
PPI::Token=isa

[PPI::Token::Regexp::Transliterate]
PPI::Token=isa

[PPI::Statement]
PPI::Node=isa
label=method
specialized=method
stable=method

[PPI::Statement::Expression]
PPI::Statement=isa

[PPI::Statement::Package]
PPI::Statement=isa
namespace=method
file_scoped=method

[PPI::Statement::Include]
PPI::Statement=isa
type=method
arguments=method
module=method
module_version=method
pragma=method
version=method
version_literal=method

[PPI::Statement::Include::Perl6]
PPI::Statement::Include=isa
perl6=method

[PPI::Statement::Sub]
PPI::Statement=isa
name=method
prototype=method
block=method
forward=method
reserved=method

[PPI::Statement::Scheduled]
PPI::Statement::Sub=isa
PPI::Statement=isa
type=method
block=method

[PPI::Statement::Variable]
PPI::Statement=isa
PPI::Statement::Expression=isa
type=method
variables=method
symbols=method

[PPI::Statement::Compound]
PPI::Statement=isa
type=method

[PPI::Statement::Given]
PPI::Statement=isa

[PPI::Statement::When]
PPI::Statement=isa

[PPI::Statement::Break]
PPI::Statement=isa

[PPI::Statement::Null]
PPI::Statement=isa

[PPI::Statement::Data]
PPI::Statement=isa

[PPI::Statement::End]
PPI::Statement=isa

[PPI::Statement::Unknown]
PPI::Statement=isa

[PPI::Structure]
PPI::Node=isa
braces=method
complete=method
start=method
finish=method

[PPI::Structure::Block]
PPI::Structure=isa

[PPI::Structure::Subscript]
PPI::Structure=isa

[PPI::Structure::Constructor]
PPI::Structure=isa

[PPI::Structure::Condition]
PPI::Structure=isa

[PPI::Structure::List]
PPI::Structure=isa

[PPI::Structure::For]
PPI::Structure=isa

[PPI::Structure::Given]
PPI::Structure=isa

[PPI::Structure::When]
PPI::Structure=isa

[PPI::Structure::Unknown]
PPI::Structure=isa

[PPI::Document]
PPI::Node=isa
get_cache=method
set_cache=method
load=method
save=method
readonly=method
tab_width=method
serialize=method
hex_id=method
index_locations=method
flush_locations=method
normalized=method
complete=method
errstr=method
STORABLE_freeze=method
STORABLE_thaw=method

[PPI::Document::Fragment]
PPI::Document=isa





#####################################################################
# Non-PDOM Classes

[PPI]

[PPI::Tokenizer]
new=method
get_token=method
all_tokens=method
increment_cursor=method
decrement_cursor=method

[PPI::Lexer]
new=method
lex_file=method
lex_source=method
lex_tokenizer=method
errstr=method

[PPI::Dumper]
new=method
print=method
string=method
list=method

[PPI::Find]
new=method
clone=method
in=method
start=method
match=method
finish=method
errstr=method

[PPI::Transform]
new=method
document=method
apply=method
file=method

[PPI::Normal]
register=method
new=method
layer=method
process=method

[PPI::Normal::Standard]
import=method
remove_insignificant_elements=method
remove_useless_attributes=method
remove_useless_pragma=method
remove_statement_separator=method
remove_useless_return=method

[PPI::Document::Normalized]
new=method
version=method
functions=method
equal=method
