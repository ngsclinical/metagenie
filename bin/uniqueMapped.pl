#!/usr/bin/perl 

use strict;
use warnings;
									  
#######################################################################																	  
# Author: Arun Rawat, TGen 										 
# Extracts the unique header information         							  
#######################################################################

(open(headerFH, "<$ARGV[0]")) or die "Can't open file : $ARGV[0] \n";
(open(uniqOF,"> $ARGV[1]")) or die "Cannot open file $ARGV[1]";
my @header=();
my @uniqHeader=();
my $cnt=0;
while (<headerFH>)
{
chomp ($_);	
push(@header,$_);
$cnt++;
}
#print scalar(@header), "\n";

my %hashTemp = map { $_ => 1 } @header;
@uniqHeader = sort keys %hashTemp;
for my $row(@uniqHeader)
{
	print uniqOF $row, "\n";	
}

