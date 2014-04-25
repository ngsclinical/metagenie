#!/usr/bin/perl 													  
#############################################################################																	  
# Created by Arun Rawat, TGen 										 
# The input file (both fasta or fastq) is split into user defined partition       							  
############################################################################
use strict;
use POSIX;
use File::Glob ':glob';
use iconfig;

my $file_in=$ARGV[0];
my $file_prefix=$ARGV[1];
my $folder_out=$ARGV[2];
my $num_proc=$ARGV[3];
my $file_format=$ARGV[4];
my $split_file=$iconfig::log_distrib;
my $num_per_file=0;
my $num_seq=0;
my @arr=();
my $split_out=0;

open(log_distrib, ">>$split_file") or die "Can't open file :$split_file \n";

if ($file_format eq "y" || $file_format eq "Y"  ){
	(open(IN, "<$file_in")) or die "Can't open file :$file_in \n";
	(open(OUT, ">$folder_out/$file_prefix")) or die "Can't create file : $file_prefix \n";
	my @fasta_seqs=<IN>;
	my $flag="N";
	foreach my $fasta_seq(@fasta_seqs){
		if ($fasta_seq =~ /^\>/) {
			if ($flag eq "N") {
				print OUT $fasta_seq;
				$flag ="Y";
			}
			else {
				print OUT "\n". $fasta_seq;
			}
		}
    	elsif ($fasta_seq =~ /^[ACGTURYKMSWBDHVNXacgturykmswbdhvnx-]+/)  {
           chomp($fasta_seq);
           print OUT $fasta_seq;
		}
	}

	$split_out=`wc -l $folder_out/$file_prefix`;
	@arr=split(" ",$split_out);
	$num_seq=$arr[0];

	$num_per_file = ceil($num_seq/$num_proc);

	if ($num_per_file%2 == 1 ){
		$num_per_file+=1;
	}
}
elsif ($file_format eq "n" || $file_format eq "N"){
	$split_out=`wc -l $file_in`;
	@arr=split(" ",$split_out);
	$num_seq=$arr[0];
	$num_seq/=4;
	$num_per_file = ceil($num_seq/$num_proc);
	if ($num_per_file%4 != 0 ){
		$num_per_file+=1;
	}
$num_per_file*=4;	
}

if ($file_format eq "y" || $file_format eq "Y"){
	`split -l $num_per_file $folder_out/$file_prefix $folder_out/$file_prefix`;
	`rm $folder_out/$file_prefix`; 
	my @tmpfiles=glob("$folder_out/*");
	for my $file(@tmpfiles){
		`mv $file $file.fasta`;
	}

	print log_distrib "$file_prefix", "\n";
	print log_distrib "Total number of seq=",$num_seq/2, "\n";
	print log_distrib "Number of reads per file=", $num_per_file/2, "\n\n";
}
elsif($file_format eq "n" || $file_format eq "N")
{
	chomp($file_in);
	`split -l $num_per_file "$file_in" "$folder_out/$file_prefix"`;
	my @tmpfiles=glob("$folder_out/*");
	for my $file(@tmpfiles){
		`mv $file $file.fastq`;
	}
	print log_distrib "$file_prefix", "\n";
	print log_distrib "Total number of seq=",$num_seq, "\n";
	print log_distrib "Number of reads per file=", $num_per_file/4, "\n\n";
}


