#!/usr/bin/perl

##################################################################
#																 #
#Author: Arun Rawat, TGen										 #
#The script summarizes the BED output to genome coverage summary #
##################################################################
use strict;
use warnings;

my $usage = "Usage: $0 <in.sortbed> <out.summary>\n";

open(MF, "<$ARGV[0]") or die "Can't open file :$ARGV[0] \n";
open(OF,">$ARGV[1]") or die "Cannot open file $ARGV[1] \n";
	
	my $covSum=0;
	my $orgName="";
	my $flag="F";
	my $tmpZeroCov=0;
	my $tmpGenSize=0;
	my $tmpGenCov=0;
	my @arr=();
	print OF  "Organism" . "\t". "Genome_Coverage(%)". "\t". "Genome_Not_Covered(%)"."\t" ."Genome_Coverage" ."\t" ."Genome_Not_Covered" ."\t" . "Genome_Size" ."\n";
	while (my $line=<MF>)
	{
		@arr = split('\t',$line);
		if ($arr[0] ne 'genome')
		{
			
			if ($orgName eq $arr[0])
			{
				next;
			}
			elsif ($orgName ne $arr[0])
			{
					$tmpZeroCov=$arr[2];
					$tmpGenSize=$arr[3];
					$tmpGenCov=$tmpGenSize-$tmpZeroCov;
					$orgName=$arr[0];
					print OF  $orgName . "\t". sprintf("%.3f",$tmpGenCov*100/$tmpGenSize). "\t". sprintf("%.3f",$tmpZeroCov*100/$tmpGenSize)."\t" .$tmpGenCov ."\t" .$tmpZeroCov ."\t" . $tmpGenSize ."\n";
	
			}
		}
	} 
