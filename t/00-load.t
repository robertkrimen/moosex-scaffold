#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::Scaffold' );
}

diag( "Testing MooseX::Scaffold $MooseX::Scaffold::VERSION, Perl $], $^X" );
