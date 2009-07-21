package PPI::XSAccessor;

# Provides optional enhancement of PPI with Class::XSAccessor (if installed)

use 5.006;
use strict;
use PPI ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.204_05';
}





######################################################################
# Replacement Methods

# Packages are implemented here in alphabetical order

package PPI::Document;

use Class::Accessor
	replace => 1,
	getters => {
		readonly => 'readonly',
	},
	true    => [
		'scope'
	];

package PPI::Document::File;

use Class::Accessor
	replace => 1,
	getters => {
		filename => 'filename',
	};

package PPI::Document::Fragment;

use Class::Accessor
	replace => 1,
	false   => [
		'scope',
	];

package PPI::Document::Normalized;

use Class::Accessor
	replace => 1,
	getters => {
		'_Document' => 'Document',
		'version'   => 'version',
		'functions' => 'functions',
	};

package PPI::Element;

use Class::Accessor
	replace => 1,
	true    => [
		'significant',
	];

package PPI::Exception;

use Class::Accessor
	replace => 1,
	getters => {
		message => 'message',
	};

package PPI::Node;

use Class::Accessor
	replace => 1,
	false   => [
		'scope',
	];

package PPI::Normal;

use Class::Accessor
	replace => 1,
	getters => {
		'layer' => 'layer',
	};

package PPI::Statement;

use Class::Accessor
	replace => 1,
	true    => [
		'__LEXER__normal',
	];

package PPI::Statement::Compound;

use Class::Accessor
	replace => 1,
	true    => [
		'scope',
	],
	false   => [
		'__LEXER__normal',
	];

package PPI::Statement::Data;

use Class::Accessor
	replace => 1,
	false   => [
		'_complete',
	];

package PPI::Statement::End;

use Class::Accessor
	replace => 1,
	true    => [
		'_complete',
	];

package PPI::Statement::Given;

use Class::Accessor
	replace => 1,
	true    => [
		'scope',
	],
	false   => [
		'__LEXER__normal',
	];

package PPI::Token;

use Class::XSAccessor
	replace => 1,
	getters => {
		content => 'content',
	},
	setters => {
		set_content => 'content',
	},
	true => [
		'__TOKENIZER__on_line_start',
		'__TOKENIZER__on_line_end',
	];

1;
