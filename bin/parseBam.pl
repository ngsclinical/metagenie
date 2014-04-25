#!/usr/bin/perl

#######################################################################																	  
# Author: Arun Rawat, TGen 										 
# The script takes bam file as input and converts to bed file  
#######################################################################

use strict;
use iconfig;

my $input = $ARGV[0];
my $output_bed=$ARGV[0]."_bed";
my $line;
my $samtools_exec=$iconfig::samtools_exec;

open (OUT_BED,">$output_bed") or die "Can't open file :$output_bed \n";
my ($i,$count)=0;
my (@data,@hits,@tokens)=();
my $tag="";
my $cmd="";

open IN, "$samtools_exec view -F 4 $input |" or die;
 
my $flag="";
my $z="";
my $col="";
while (<IN>){

  chomp;
  $flag="F";
  @data = split /\t/;
  $z=0;
  $col=0;
while ($z<scalar(@data)) 
{
if($data[$z] =~ /XA:Z:/){
$col=$z;
$flag="T";
}
$z++;
}


my $name = $data[0];
if ($flag eq "F")
{
$tag="U";

&convert2Bed($name,$data[2],$data[3],$data[5],$data[4],$tag);
}
elsif ($flag eq "T")
{
#multihits
@hits=split(/;/,$data[$col]);
$count = scalar(@hits);
$i=0;
$tag="R";
&convert2Bed($name,$data[2],$data[3],$data[5],$data[4],$tag);
    while ($i<$count)
    {
    	#$tag="R";
    	@tokens=split(/,/,$hits[$i]);
    	if ($i == 0)
    	{
    		$tokens[0] =~ s/XA:Z://; 
    	}
    	&convert2Bed($name,$tokens[0],$tokens[1],$tokens[2],0,$tag);    	
    	$i++;
    }
}
}

sub errorMessage {
    my $err = shift;
    print STDERR "ERROR: ".$err.".\n\n Please see IRIMAS documentation or \'irimas -h\' for info.\n EXITING on ERROR.\n";
    exit(0);
}


sub convert2Bed
{
my @in=@_;
my @cigar = split(/[MID]/,$in[3]); #Approximate coverage, more functionality required
my $i=0;
my $count=scalar(@cigar);
my $sum=0; my $strand=""; 
while ($i<$count)
{
	$sum+=$cigar[$i];
	$i++;
}
if ($in[2] <0)
{
$in[2]= -($in[2]);
$strand="-";
}
else
{
$strand="+";
}
$sum+=$in[2];

print  OUT_BED $in[1],"\t", $in[2],"\t", $sum, "\t", $in[0], "\t",$in[4], "\t",$strand,"\n"; 

}

close IN;
close OUT_BED;

