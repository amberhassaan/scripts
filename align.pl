#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $Usage= <<'THE_END';

./align [options...]

Options are: 

-s [ patt ] # split on patt
  if no patt provided, split on white space
  patt is a string or a valid Perl regexp, use \ to escape magic characters

-j [ str ] # join with string str
  if no join provided, use a single space
  str is a simple string

Use quotes to protect the arguments to -s, -j from shell

-f [ fileName ]
  if no fileName provided or - provided, read stdin

-B {str}
  put str at the beginning of every line

-E {str}
  put str at the end of every line
-h print this msg


THE_END

  
  
my $Sp=' ';
my $Jn= ' ';
my $B = '';
my $E = '';
my $FileName = undef;
my $ShowHelp;

my $status = GetOptions(
  's=s' => \$Sp,
  'j=s' => \$Jn,
  'b=s' => \$B,
  'e=s' => \$E,
  'f=s' => \$FileName,
  'h' => \$ShowHelp,
);

if( !$status ) { die $Usage; }

if( @ARGV ) { die $Usage; }

if( $ShowHelp ) { die $Usage; }


if( ! defined $Sp or $Sp eq '' ) { 
  $Sp = ' ';
}
if( ! defined $Jn ) {
  $Jn = ' ';
}

if(!defined $B ) { $B=''; }
if(!defined $E ) { $E=''; }

my  $FH=*STDIN;

if( !defined $FileName or $FileName eq '-' or $FileName eq '' ) {
}else {
  open $FH, "< $FileName" or die "Could not open $FileName for reading\n";
}


my @Matrix;
my $NumCols=0;

my $LineNo = 0;
while(<$FH>){
  chomp;
  my @tokens;
  if( $Sp =~ /^\s+$/ ) {
    @tokens = split;
  }
  else {
    @tokens = split /${Sp}/, $_;
  }

  push @Matrix, \@tokens;
  if( $NumCols < $#tokens ) { $NumCols = $#tokens ; } 
  $LineNo++;
}

my @ColWidths;



foreach my $i( 0..$NumCols) {
  my $max=0;
  foreach my $l(@Matrix) {
    if( $i <= $#$l ) {
      if( length( $l->[$i] ) > $max ) { $max = length( $l->[$i] ) ; }
    }
  }
  push @ColWidths, $max;
}

foreach my $l ( @Matrix ) {
  for my $i ( 0..$#$l ) {
    $l->[$i] = sprintf("%-$ColWidths[$i]"."s", $l->[$i] );
  }
}

foreach my  $l ( @Matrix ) {
  print $B.( join ($Jn, @$l) ), "$E\n";
}
