#!/usr/bin/perl

use strict;
use PPI;


#####################################################################
# Prepare

# For each new item in t/data/08_regression add another 14 tests

use Test::More tests => 17;
use t::lib::PPI;





#####################################################################
# Code/Dump Testing
# ntests = 2 + 14 * nfiles

t::lib::PPI->run_testdir(qw{ t data 26_bom });
