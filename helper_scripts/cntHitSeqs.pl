#!/usr/bin/perl 

#######################################################################																	  
# Author: Arun Rawat, TGen											  # 										 
# The script calculates total read number for given organism		  #
# detected by MetaGeniE												  #
# Organism string specificity Genus, Species, Strain 	
# Uses Fastacmd, please set the path appropriately 				      #
#######################################################################

use strict;
use warnings FATAL => 'all';
use File::Basename;
#use Parallel::ForkManager;
use File::Glob qw[glob];

my $ARGCNT = $#ARGV + 1;
if ($ARGCNT != 4)
{
        print "usage: perl <perl_script> <Project Folder Path> <Organism String> <Microbial_Type(bac,fungal,viral)> <Create_Fasta_File>\n";
            exit(1);
}

my $project_folder=$ARGV[0];
my $organism_str=$ARGV[1];
my $microbial_type=$ARGV[2];
my $create_fasta_file=$ARGV[3];
my $sh_cmd="";
my $organism_substr="";
my %microbe_lcl_dict = ();
my %microbe_gbl_dict = ();

%microbe_lcl_dict = (
'bac'=>'tmp_blat_bacteria',
'fungal'=>'tmp_blat_fungal',
'viral'=>'tmp_blat_viral',
);

%microbe_gbl_dict = (
'bac'=>'tmp_bwa_bacteria',
'fungal'=>'tmp_bwa_fungal',
'viral'=>'tmp_bwa_viral',
);

my @tmp_arr=split /[#,\!,{,},|,\.]/,$organism_str;
foreach my $token(@tmp_arr) {
	$organism_substr=$organism_substr . $token;
}

&extract_align_info("_gbl",\%microbe_gbl_dict);
&extract_align_info("_lcl",\%microbe_lcl_dict);

sub extract_align_info {
	my $tmp_align_type=shift;
	my $tmp_dict = shift; 
# sort All_header | uniq > All_header_uniq #sort ref_lcl | uniq > ref_lcl_uniq
	foreach ( keys %{$tmp_dict} ) {
		if ($_ eq $microbial_type)  {  
			my $folder_type=$tmp_dict->{$_};
			my $tmp_organism_substr=$organism_substr . $tmp_align_type;
			my $path = $project_folder . "/" . $tmp_dict->{$_} . "/";
			$sh_cmd = `grep $organism_str $path/ALL_MAPPED.bed | awk '{print \$4}' | uniq > $tmp_organism_substr`;
			if ($create_fasta_file eq "y" || $create_fasta_file eq "Y") {
				my @tmp_files=glob("$path/*.fasta");
				my $j=1;
				my $output_file="";
				for my $file(@tmp_files) {
					$output_file= $organism_substr.$j."_MAPPED_SEQ.fa";
					$sh_cmd = "/packages/blast/2.2.17/bin/fastacmd -p F -d $file -i $tmp_organism_substr -o $output_file 2>>err_log";
					system($sh_cmd);
					$j++;
				} 
				$output_file=$organism_substr."_MAPPED_SEQ_ALL.fa";
				@tmp_files=glob("*_MAPPED_SEQ.fa");
				for my $file(@tmp_files) {
					$sh_cmd="cat $file >> $output_file";
					system($sh_cmd);
					unlink "$file" or warn "Can't delete $file: $!";
				}
			}
		}
	}
}
