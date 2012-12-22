#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tiezi::Robot' ) || print "Bail out!\n";
}

diag( "Testing Tiezi::Robot $Tiezi::Robot::VERSION, Perl $], $^X" );
