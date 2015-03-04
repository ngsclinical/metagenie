#!/usr/bin/perl

use strict;
use warnings;

#######################################################################
# Author: Arun Rawat, TGen
# Extracts the unique header information
#######################################################################

(open(headerFH, "<$ARGV[0]")) or die "Can't open file : $ARGV[0] \n";
(open(uniqOF,"> $ARGV[1]")) or die "Cannot open file $ARGV[1]";
my $val=1;
my %hashTemp=();
while (<headerFH>)
{
chomp ($_);
$hashTemp{$_} = $val; # if !exists $hashTemp{$_}; No need to validate the hash for the key

}

for my $row(keys %hashTemp)
{
print uniqOF $row, "\n";
}


