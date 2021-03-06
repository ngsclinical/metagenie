###########################################################################
# Author: Arun Rawat, TGen												
# iconfig.pm
# This module stores all the configuration (databases, executables and dependencies) 
# required to run MetaGeniE
# MetaGeniE uses Variables and Options. PLEASE DO NOT DELETE ANY VARIABLES/OPTIONS. This might have adverse
# effect on the MetaGeniE
# Variables/database setup can be turned off/on with corresponding Option
# Example To turn off search against Bacterial database, set $run_bacdb="n"  
# Option can only use following values : (y/Y or n/N)
# See Documentation for more help or post your bugs at the Repository
###########################################################################
package iconfig;

##### Variables for both module#######
#Prinseq parameters	
	my $curr_dir=`pwd`;
	chomp $curr_dir;
	our $wait_time=500;
	our $min_len=100; 
	our $lc_method="dust";
	our $lc_threshold=10;
	our $min_qual=20;
	our $ns_max_p=3;

#BLAT parameters
	our $blat_identity = 98;
#####End #####################


########Variables for Read-Reduct Module############
# multiple human/host reference genomes can be used
	our $human_ref_hg19 = "/set/the/directory/hg19.fa";
	our $human_ref_cn = "/set/the/directory/cnGenome.fa";
	our $human_ref_kr = "/set/the/directory/krGenome.fa";
	our $repeat = "/set/the/directory/RepeatLib.fasta";
    #Option to run database
    our $run_bwa="y"; # "Y/y" option will run BWA and "N/n" option will run Bowtie2 to filter human reads; set paths accordingly
	our $run_ref_hg19="y";
	our $run_ref_cn="n";
	our $run_ref_kr="n";
	our $run_dup_filter="n";
	our $run_stampy="n";
	our $run_ref_rep="n";
	our $del_tmp_rr="y"; #Will delete tmp files like bams and output files generated from each step; saves disk space
###########End of Read-Reduct Module#############

#######Variable for Patho-Detect###############
    our $bacteria = "/set/the/directory/bacterialDB";
	our $fungal = "/set/the/directory/fungiDB"; 
	our $viral = "/set/the/directory/viralDB"; 
	
	#Option to run database
	our $run_bacdb="y"; #Turns search against bacterial database on or off
	our $run_fungaldb="n"; #Turns search against fungal database on or off
	our $run_viraldb="n"; #Turns search against viral database on or off
	our $del_tmp_pd="y";#Will delete tmp files like bams and output files generated from each step 
    our $gbl_alignmnt="y";  #Option will run global aligner BWA or Bowtie
	our $lcl_alignmnt="n";  #Option will run local aligner BLAT
##########################################

# Paths for executables
our $bin_dir = "/set/the/directory/metagenie/bin";
our $script_dir= "/set/the/directory/metagenie/scripts";
our $blat_exec = "/set/the/directory/metagenie/external/blat";
our $bwa_exec = "/set/the/directory/bwa";  
our $stampy_exec = "/your/path/stampy.py";
our $bowtie2_exec = "/set/the/directory/bowtie2";
our $prinseq_exec = "/set/the/directory/metagenie/external/prinseq-lite.pl";
our $samtools_exec= "/set/the/directory/SAMtools/0.1.19/samtools"; 
our $formatdb_exec="/set/the/directory/blast/2.2.17/bin/formatdb";
our $fastacmd_exec="/set/the/directory/blast/2.2.17/bin/fastacmd";
our $sortbed_exec="/set/the/directory/bedtools/2.22/bin/sortBed"; ## Install the Bedtool package available in directory external
our $gencov_exec="/set/the/directory/bedtools/2.22/bin/genomeCoverageBed"; ## Install the Bedtool package available in directory external

# Temp folder
our $tmp_blat_rr=$curr_dir."/tmp_blat_rr";
our $tmp_blat_viral=$curr_dir."/tmp_blat_viral";
our $tmp_blat_bacteria=$curr_dir."/tmp_blat_bacteria";
our $tmp_blat_fungal=$curr_dir."/tmp_blat_fungal";
our $tmp_human_filter=$curr_dir."/tmp_human_filter";
our $tmp_bwa_viral=$curr_dir."/tmp_bwa_viral";
our $tmp_bwa_bacteria=$curr_dir."/tmp_bwa_bacteria";
our $tmp_bwa_fungal=$curr_dir."/tmp_bwa_fungal";
our $tmp_prinseq_rr=$curr_dir."/tmp_prinseq_rr";
our $tmp_prinseq_pd=$curr_dir."/tmp_prinseq_pd";

#Log folder
our $log_folder=$curr_dir."/log";
our $log_time=$log_folder."/log_time";
our $log_distrib=$log_folder."/log_distrib";
our $log_stats=$log_folder."/log_stats";
