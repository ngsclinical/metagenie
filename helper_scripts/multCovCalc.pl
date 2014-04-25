#!/usr/bin/perl
######
#
#Created by Arun Rawat, TGen		#
#The script BAM output to Bed output   #
#######################################

#perl bedCovCalc.pl genCov.txt 
my $ARGCNT = $#ARGV + 1;
if ($ARGCNT != 1)
{
        print "usage: perl <perl_script> <inputfile>  \n";
            exit(1);
}

#@files=</expec/snpCalling/bamCov/*>;
#print @files;

my $input = $ARGV[0];
my $output=$ARGV[0]."_CovOut";

#foreach $file(@files)
#{
my $covSum=0;
	open(MF, "<$input") or die "Can't open file :$file \n";
	(open(OF,">>$output")) or die "Cannot open file $output";
	#my @lines = <MF>;
	$orgName="";
	$flag="F";
	$tmpZeroCov=0;
	$tmpGenSize=0;
	$tmpGenCov=0;
	print OF  "Organism" . "\t". "Genome_Coverage(%)". "\t". "Genome_Not_Covered(%)"."\t" ."Genome_Coverage" ."\t" ."Genome_Not_Covered" ."\t" . "Genome_Size" ."\n";
	while ($line=<MF>)
	{

		@arr = split('\t',$line);
	#print OF $loop."\t"."flag=$flag"."\n";
		if ($arr[0] ne 'genome')
		{
			
			if ($orgName eq $arr[0])
			{
				next;
			}
			elsif ($orgName ne $arr[0])
			{
				##this loop will execute first time and everytime the organism changes for 0 coverage
				#write the arrays from above if statement except for first time
					$tmpZeroCov=$arr[2];
					$tmpGenSize=$arr[3];
					$tmpGenCov=$tmpGenSize-$tmpZeroCov;
					$orgName=$arr[0];
					print OF  $orgName . "\t". sprintf("%.3f",$tmpGenCov*100/$tmpGenSize). "\t". sprintf("%.3f",$tmpZeroCov*100/$tmpGenSize)."\t" .$tmpGenCov ."\t" .$tmpZeroCov ."\t" . $tmpGenSize ."\n";
	
			}
		}
	} 
	#continue {
	#				print OF  $orgName . "\t". sprintf("%.3f",$tmpGenCov*100/$tmpGenSize). "\t". sprintf("%.3f",$tmpZeroCov*100/$tmpGenSize)."\t" .$tmpGenCov ."\t" .$tmpZeroCov ."\t" . $tmpGenSize ."\n" if eof;	
	#			}
	
			
#}
