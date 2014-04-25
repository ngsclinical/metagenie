#!/usr/bin/perl

#######################################################################																	  
# Author: Arun Rawat, TGen 										 
# Generates the header info for the PSL files  
#######################################################################
use strict;

(open(headerFH, "<$ARGV[0]")) or die "Can't open file : $ARGV[0] \n";
(open(uniqOF,">>$ARGV[1]")) or die "Cannot open file $ARGV[1]";

my $cnt=0;
my (@header,@arr) = ();
my %hashTemp = ();

while (<headerFH>) {
 	chomp ($_);	
 	@arr = split('\t',$_);
	if (scalar(@arr) == 21){
		push(@header,$arr[9]);
	}
	$cnt++;
}

%hashTemp = map { $_ => 1 } @header;
my @uniqHeader = sort keys %hashTemp;

for my $row(@uniqHeader)
{
	print uniqOF $row, "\n";	
}
