#!/usr/bin/perl

use strict;
use warnings;
use Math::Trig ;

foreach my $i( @ARGV ) {
	my $x = sprintf( "%x", eval($i) );
	print "0x$x\n";
}
