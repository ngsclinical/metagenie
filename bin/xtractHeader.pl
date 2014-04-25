#!/usr/bin/perl

#######################################################################																	  
# Author: Arun Rawat, TGen 										 
# Creates unique index from the header file 
#######################################################################
use strict;
(open(headerFH, "<$ARGV[0]")) or die "Can't open file : $ARGV[0] \n";
(open(OF,"> $ARGV[1]")) or die "Cannot open file $ARGV[1]";

my $header="";
while (<headerFH>)
{
chomp ($_);	
if ($_ =~ /^\>/) 
	{
		$header=$_;
		$header =~ s/>//;
		print OF $header,"\n";
	}
}
