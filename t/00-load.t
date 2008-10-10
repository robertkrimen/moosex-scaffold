#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::ClassScaffold' );
}

diag( "Testing MooseX::ClassScaffold $MooseX::ClassScaffold::VERSION, Perl $], $^X" );
