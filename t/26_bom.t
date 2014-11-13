#!/usr/bin/perl

use t::lib::PPI::Test::pragmas;
use Test::More tests => 21;

use t::lib::PPI;
use PPI;





#####################################################################
# Code/Dump Testing

t::lib::PPI->run_testdir(qw{ t data 26_bom });
