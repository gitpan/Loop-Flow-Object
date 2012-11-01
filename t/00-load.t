#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Loop::Flow::Object' ) || print "Bail out!\n";
}

diag( "Testing Loop::Flow::Object $Loop::Flow::Object::VERSION, Perl $], $^X" );
