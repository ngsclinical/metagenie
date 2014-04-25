#!/usr/bin/perl 

#######################################################################																	  
# Author: Arun Rawat, TGen 										 
# The script is invoked if Patho-Detect option is set yes
# Detects Pathogen from metagenome samples 
#######################################################################

use strict;
use iconfig;
use warnings FATAL => 'all';
use File::Basename;
use Parallel::ForkManager;
use File::Glob qw[glob];

my $wait_time=$iconfig::wait_time;
my $min_len=$iconfig::min_len;
my $lc_method=$iconfig::lc_method;
my $lc_threshold=$iconfig::lc_threshold;
my $min_qual=$iconfig::min_qual;
my $ns_max_p=$iconfig::ns_max_p;
my $blat_identity = $iconfig::blat_identity;
my $prinseq_exec=$iconfig::prinseq_exec;
my $bin_dir = $iconfig::bin_dir;
my $script_dir = $iconfig::script_dir;
my $blat_exec = $iconfig::blat_exec;
my $bwa_exec = $iconfig::bwa_exec;
my $samtools_exec=$iconfig::samtools_exec;
my $formatdb_exec=$iconfig::formatdb_exec;
my $fastacmd_exec=$iconfig::fastacmd_exec;
my $sortbed_exec=$iconfig::sortbed_exec;
my $gencov_exec=$iconfig::gencov_exec;
my $bacteria = $iconfig::bacteria;
my $fungal = $iconfig::fungal;
my $viral = $iconfig::viral;
my $run_bacdb=$iconfig::run_bacdb;
my $run_fungaldb=$iconfig::run_fungaldb;
my $run_viraldb=$iconfig::run_viraldb;
my $lcl_alignmnt=$iconfig::lcl_alignmnt;
my $del_tmp_pd=$iconfig::del_tmp_pd;
my $tmp_bwa_viral=$iconfig::tmp_bwa_viral;
my $tmp_blat_viral=$iconfig::tmp_blat_viral;
my $tmp_blat_bacteria=$iconfig::tmp_blat_bacteria;
my $tmp_blat_fungal=$iconfig::tmp_blat_fungal;
my $tmp_bwa_bacteria=$iconfig::tmp_bwa_bacteria;
my $tmp_bwa_fungal=$iconfig::tmp_bwa_fungal;
my $tmp_prinseq=$iconfig::tmp_prinseq_pd;
my $log_folder=$iconfig::log_folder;
my $log_time=$iconfig::log_time;
my $log_stats=$iconfig::log_stats; 
my $log_distrib=$iconfig::log_distrib;
my $frag_file_script = "$bin_dir/fragFile.pl";
my $psl_extract_script="$bin_dir/pslXtractor.pl";
my $xtract_Header_script="$bin_dir/xtractHeader.pl";
my $intersect_script="$bin_dir/intersect.pl";
my $uniq_map_script="$bin_dir/uniqueMapped.pl";
my $parse_bam_script="$bin_dir/parseBam.pl";
my $p2b_script="$bin_dir/p2b.pl";
my $mult_covcalc_script="$bin_dir/multCovCalc.pl";
my $mult_bacteria_bwa="$script_dir/mult_bacteria_bwa.sh";
my $manager="";
my $pid="";
my $wait_msg="";
my $input_file="";
my $output_file = "";
my $tmp_file_prefix="";
my $fasta_format = $ARGV[0];
my $sh_cmd="";
my (@cmd,@tmp_arr,@files_in_folder)=();
my $log_msg="";
my $tmp_file_suffix="";
my $tmp_file="";
my $tmp_cnt=0;
my $tmp_header="";
my $input_file_prefix="";
my $num_proc=$ARGV[2];
my @tmp_dir=($tmp_blat_bacteria,$tmp_blat_viral,$tmp_blat_fungal,$tmp_bwa_bacteria,$tmp_bwa_fungal,$tmp_bwa_viral,$tmp_prinseq);

foreach(@tmp_dir) {
			$tmp_file_prefix=$_;
			&makeDir($tmp_file_prefix);
			  } 
			  
unless(-d $log_folder) {
    mkdir $log_folder; 
}
else { 
	print "Using existing Log folder!!  \n"; 
}

$input_file=`basename $ARGV[1]`;
@tmp_arr=split(/\./,$input_file);
$input_file_prefix= $tmp_arr[0];
$tmp_file_prefix="tmp_".$input_file_prefix;

open(timeLog, ">>$log_time") or die "Can't open file :$log_time \n";
open(logStats,">>$log_stats") or die "Can't open file :$log_stats \n";

print timeLog "The Pathogen Detection started at:";
&timeStamp;

@cmd=("perl", "$frag_file_script", "$input_file", "$tmp_file_prefix", "$tmp_prinseq", "$num_proc", "$fasta_format");
system (@cmd)== 0 or &errorMessage(" @cmd failed: $?");
if ($fasta_format eq "y" || $fasta_format eq "Y") {
	@files_in_folder=<$tmp_prinseq/*.fasta>;
}
elsif($fasta_format eq "n" || $fasta_format eq "N")	{
	@files_in_folder=<$tmp_prinseq/*.fastq>;
}

&parallelManager_initiate;
foreach my $file(@files_in_folder) {
	$tmp_cnt++;
	$tmp_file_prefix=fileparse($file);
	$tmp_file_suffix="PD_clean";
	$tmp_file=$tmp_file_prefix."_".$tmp_file_suffix;
	$tmp_header=$input_file_prefix."_".$tmp_cnt."_";
	$manager->start($file) and next;
	if ($fasta_format eq "y" || $fasta_format eq "Y" ) {
     	$sh_cmd="$prinseq_exec -log -fasta $file -min_len $min_len -rm_header -seq_id $tmp_header -lc_threshold $lc_threshold -lc_method dust -out_good $tmp_prinseq/$tmp_file -ns_max_p $ns_max_p -out_format 1 -out_bad null";
	}
	elsif ($fasta_format eq "n" || $fasta_format eq "N" ) {
		$sh_cmd ="$prinseq_exec -log -fastq $file -min_qual_score $min_qual -min_len $min_len -rm_header -seq_id $tmp_header -lc_threshold $lc_threshold -lc_method dust -out_good $tmp_prinseq/$tmp_file -ns_max_p $ns_max_p -out_format 1 -out_bad null";
    }
    system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
	if ($manager) {$manager->finish($pid)};
}
$wait_msg="Performing removal of low quality reads ...\n";
$manager->wait_all_children;

my @tmpfiles=glob("$tmp_prinseq/*PD_clean.fasta");
$output_file=$input_file_prefix."_clean.fasta";
for my $file(@tmpfiles) {
	$sh_cmd="cat $file >> $output_file";
	system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
	unlink "$file" or warn "Can't delete $file: $!";
}
if ($fasta_format eq "y" || $fasta_format eq "Y" )	{
	@tmpfiles=glob("$tmp_prinseq/*.fasta");
}
elsif ($fasta_format eq "n" || $fasta_format eq "N") {
	@tmpfiles=glob("$tmp_prinseq/*.fastq");
}

for my $file(@tmpfiles)	{
	unlink "$file" or warn "Can't delete $file: $!";
}
$log_msg="Total sequences after removal of low quality reads:";
&seqCount_fasta($log_msg,$output_file);

print timeLog "The sequence cleaning done:";
&timeStamp;

$fasta_format="y";

if ($run_bacdb eq "y" || $run_bacdb eq "Y") { 
	if (-d $bacteria) {
		$tmp_file_suffix="_renBWA_bacIn";
		&renameHeader;

		$tmp_file_prefix="tmpBWABac_".$input_file_prefix;
		$tmp_file_suffix="_unmap_bac_bwa.fasta";
		&gblAlign($tmp_bwa_bacteria,$bacteria);
	}
	else {
		die "Please set the bacterial database in Configuration file!!  \n";
	}
}
else {
	print logStats "Querying Bacterial Genomes turned OFF !! \n";
}
	
if ($run_viraldb eq "y" || $run_viraldb eq "Y") {
	if (-d $viral) {
		$tmp_file_suffix="_renBWA_viralIn";
		&renameHeader;

		$tmp_file_prefix="tmpBWAVir_".$input_file_prefix;
		$tmp_file_suffix="_unmap_viral_bwa.fasta";
		&gblAlign($tmp_bwa_viral,$viral);
	}
	else {
		die "Please set the viral database in Configuration file!!  \n";
	}
}
else {
	print logStats "Querying Viral Genomes turned OFF!! \n";
	}

if ($run_fungaldb eq "y" || $run_fungaldb eq "Y") {
	if (-d $fungal) {
		$tmp_file_suffix="_renBWA_fungiIn";
		&renameHeader;

		$tmp_file_prefix="tmpBWAFungi_".$input_file_prefix;
		$tmp_file_suffix="_unmap_fungi_bwa.fasta";
		&gblAlign($tmp_bwa_fungal,$fungal);
	}
	else {
		die "Please set the fungal database in Configuration file!!  \n";
	}
}
else {
	print logStats "Querying Fungal Genomes turned OFF!! \n";
}

if ($lcl_alignmnt eq "y" || $lcl_alignmnt eq "Y") {
	if ($run_bacdb eq "y" || $run_bacdb eq "Y") { 
		if (-d $bacteria) {
			$tmp_file_suffix="_renBLAT_BacIn";
			&renameHeader;

			$tmp_file_prefix="tmpBLATBac_".$input_file_prefix;
			$tmp_file_suffix="_unmap_bac_blat.fasta"; 
			&lclAlign($bacteria,$tmp_bwa_bacteria, $tmp_blat_bacteria);
		}
		else {
		die "Please set the bacterial database in Configuration file!!  \n";
		}
	}
	else {
		print logStats "Querying Bacterial Genomes turned OFF !! \n";		
	}
	if ($run_viraldb eq "y" || $run_viraldb eq "Y") { 
		if (-d $viral) {
			$tmp_file_suffix="_renBLAT_ViralIn";
			&renameHeader;

			$tmp_file_prefix="tmpBLATVir_".$input_file_prefix;
			$tmp_file_suffix="_unmap_vir_blat.fasta"; 
			&lclAlign($viral,$tmp_bwa_viral, $tmp_blat_viral);
		}
		else {
		die "Please set the viral database in Configuration file!!  \n";
		}
	}
	else {
		print logStats "Querying Viral Genomes turned OFF !! \n";		
	}
	
	if ($run_fungaldb eq "y" || $run_fungaldb eq "Y") { 
		if (-d $fungal) {
			$tmp_file_suffix="_renBLAT_FungalIn";
			&renameHeader;

			$tmp_file_prefix="tmpBLATFungal_".$input_file_prefix;
			$tmp_file_suffix="_unmap_fungal_blat.fasta"; 
			&lclAlign($fungal,$tmp_bwa_fungal, $tmp_blat_fungal);
		}
		else {
		die "Please set the fungal database in Configuration file!!  \n";
		}
	}
	else {
		print logStats "Querying Fungal Genomes turned OFF !! \n";		
	}
}
else {
	print logStats "Settings for Local Alignment turned OFF!! \n";	
}
	$input_file=$output_file;
	$output_file=$input_file_prefix."_pathoDetect.fasta";
	rename($input_file,$output_file);
	&closeFiles;
	
sub lclAlign {
	my ($tmp_db,$tmp_gbl_dir,$tmp_lcl_dir)=@_;
	$input_file=$output_file;
	$output_file=$input_file_prefix.$tmp_file_suffix;
	&runBlat($input_file,$tmp_db,$tmp_lcl_dir,$output_file);
	$log_msg="Total sequences after removal against". $tmp_db . "with BLAT:";
	&seqCount_fasta($log_msg,$output_file);
	&genomeCoverage($tmp_gbl_dir,$tmp_lcl_dir,$tmp_db);
	print timeLog "The ". $tmp_db. " alignment with BLAT finished:";
	&timeStamp;
}

sub gblAlign {
	my ($tmp_dir,$tmp_db)=@_;
	$input_file=$output_file;
	$wait_msg="Running alignment against". $tmp_db. "database with BWA ...\n";
	&pathoAlign($tmp_dir,$tmp_db);
	print timeLog "Alignment against".$tmp_db . "with BWA finished:";
	&timeStamp;
}

sub renameHeader {
	$input_file=$output_file;
	$output_file=$input_file_prefix.$tmp_file_suffix;
	$sh_cmd ="$prinseq_exec -log -fasta $input_file -rm_header -seq_id $input_file_prefix -out_good $output_file -out_format 1 -out_bad null";
	system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
	unlink "$input_file" or warn "Can't delete $input_file: $!";
	$output_file=$output_file.".fasta";
}

sub genomeCoverage {
	my ($tmp_bwa,$tmp_blat,$patho_dir)=@_;
	my $tmp_output_file;
	my $tmp_input_file;

	$tmp_input_file=<$tmp_bwa/ALL_MAPPED.bed>;
	$tmp_output_file=$tmp_blat."/ALL_MAPPED_TOTAL.bed";

	$sh_cmd="cat $tmp_input_file >> $tmp_output_file";
	system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");

	$tmp_input_file=<$tmp_blat/ALL_MAPPED.bed>;
	$sh_cmd="cat $tmp_input_file >> $tmp_output_file";
	system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");

	if (-s $tmp_output_file != 0) {
		$tmp_input_file=$tmp_output_file;
		$tmp_output_file=$tmp_input_file."_TOTAL_SORTBED";
		$sh_cmd="$sortbed_exec -i $tmp_input_file > $tmp_output_file";
		system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
	}

	if (-s $tmp_output_file != 0) {
		$tmp_input_file=$tmp_output_file;
		$tmp_output_file=$tmp_input_file."_TOTAL_GENOMECOV";
		$sh_cmd="$gencov_exec -i $tmp_input_file -g $patho_dir/GenomeDesc > $tmp_output_file";
		system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
	}

	if (-s $tmp_output_file != 0) {
		$tmp_input_file=$tmp_output_file;
		$tmp_output_file=$tmp_input_file."_SUMMARY";
		@cmd=("perl", "$mult_covcalc_script", "$tmp_input_file", "$tmp_output_file");
		system(@cmd) == 0 or &errorMessage(" @cmd failed: $?");
	}
	
	if ($del_tmp_pd eq "y" || $del_tmp_pd eq "Y") {
		my @tmp_suffix =(".psl", ".psl.MAPPED", ".psl.UNMAPPED", "_TOTAL_SORTBED", "_TOTAL.bed", "_TOTAL_GENOMECOV", ".HEADER.ALL") ;
		foreach(@tmp_suffix) {
			$tmp_file_suffix=$_;
			&unlinkFiles($tmp_blat,$tmp_file_suffix);
		}
	}
}

sub runBlat {
	my ($input,$ref,$tmp_blat,$output)=@_;
	my $tmp_file="";
	my $file_out="";
	my $db_partition=0;
	my $tmp_output_file;

	@cmd=("perl", "$frag_file_script", "$input", "$tmp_file_prefix", "$tmp_blat", "$num_proc","$fasta_format");
	system (@cmd) == 0 or &errorMessage(" @cmd failed: $?");
	unlink "$input" or warn "Can't delete $input: $!";

	@tmpfiles=glob("$ref/*.bwt");
	$db_partition=scalar(@tmpfiles);
	my @tmp_str;
	my $cmb_str;
	my $tmp_outer=1;

	for my $file_db(@tmpfiles) {
		my $tmp_inner=0;
		@tmp_str=fileparse($file_db,qr/\.[^.]*/);
		$cmb_str=$tmp_str[1].$tmp_str[0];
		@files_in_folder=glob("$tmp_blat/*.fasta");
		&parallelManager_initiate;
		foreach my $file(@files_in_folder) {
			$tmp_inner++;
			$manager->start($file) and next;
			$file_out=$file."_".$tmp_inner."_".$tmp_outer.".psl";
			$sh_cmd="$blat_exec $cmb_str -minIdentity=$blat_identity -noHead $file $file_out";
			system($sh_cmd)==0 or &errorMessage("$sh_cmd failed: $?");
			if ($manager) {$manager->finish($pid)};
		}
	$tmp_outer++;
	$wait_msg="Running Bac Genome Alignment with BLAT ...\n";
	$manager->wait_all_children;
	}
	
	$tmp_outer=$db_partition+1;
	for my $file_db(@tmpfiles) {
		&blat_align(--$tmp_outer,$tmp_blat,$db_partition);
	}
	&blat_extract($tmp_blat,$db_partition);
	
	$tmp_outer=$db_partition+1;	
	for my $file_db(@tmpfiles) {
		&run_p2b(--$tmp_outer,$tmp_blat,$db_partition); #tmp_outer and dbpartition are same except with each iteration tmp_outer decreases
	}
	
	@tmpfiles=glob("$tmp_blat/*.psl.UNMAPPED_SEQ");
	for my $file(@tmpfiles) {
		$sh_cmd ="cat $file >> $output";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?") ;
		unlink "$file" or warn "Can't delete $file: $!";
	}
	
	@tmpfiles=glob("$tmp_blat/*.bed");
	$tmp_output_file=$tmp_blat."/ALL_MAPPED.bed";
	for my $file(@tmpfiles) {
		$sh_cmd="cat $file >> $tmp_output_file";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?") ;
 		unlink "$file" or warn "Can't delete $file: $!";
	}
}

sub blat_extract {
	my ($tmp_blat,$db_partition)=@_;
	my $tmp_in;
	my $tmp_out;
	my $tmp_inner=1;

	&parallelManager_initiate;
	@files_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		@cmd=("perl", "$xtract_Header_script", "$file", "$file.HEADER.ALL");
		system(@cmd)==0 or &errorMessage("@cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
		}
	$wait_msg="Extracting headers ...\n";
	$manager->wait_all_children;
	my @fasta_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $fasta_file(@fasta_in_folder) {
		for (my $tmp_outer = 1; $tmp_outer<=$db_partition; $tmp_outer++) {
			$tmp_in=$fasta_file."_".$tmp_inner."_".$tmp_outer.".psl.MAPPED";
			$sh_cmd ="cat $tmp_in >> $fasta_file.psl.MAPPED";
			system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
		}
		$tmp_inner++;
	}

	&parallelManager_initiate;
	@files_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		my @cmd=("perl","$intersect_script", "$file.psl.MAPPED", "$file.HEADER.ALL", "$file.psl.UNMAPPED");
		system(@cmd)==0 or &errorMessage(" @cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}

	$wait_msg="Extracting unmapped headers ...\n";
	$manager->wait_all_children;
	print $wait_msg;

	&parallelManager_initiate;
	@files_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		$sh_cmd="$formatdb_exec -p F -o T -i $file";
		system($sh_cmd)==0 or &errorMessage("$sh_cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Setting databases ...\n";
	$manager->wait_all_children;
	print $wait_msg;

	&parallelManager_initiate;
	$tmp_inner=0;
	@files_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		$sh_cmd="$fastacmd_exec -p F -d $file -i $file.psl.UNMAPPED -o $file.psl.UNMAPPED_SEQ 2>>$tmp_blat/db_log";
		system($sh_cmd); # Always raise error due to partioned fasta db;
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Extracting unmapped reads ...\n";
	$manager->wait_all_children;
	print $wait_msg;
}

sub blat_align {
	my ($tmp_outer,$tmp_blat,$db_partition)=@_;
	my $tmp_in="";
	my $tmp_out="";
	my $tmp_inner;

	&parallelManager_initiate;
	for (my $tmp_inner = 1; $tmp_inner<=$db_partition; $tmp_inner++) {
		@files_in_folder=glob("$tmp_blat/*_$tmp_outer.psl");
		foreach my $file(@files_in_folder) {
			$manager->start($file) and next;
			@cmd=("perl", "$psl_extract_script", "$file", "$file.MAPPED");
			system(@cmd) ==0 or &errorMessage(" @cmd failed: $?");
			if ($manager) {$manager->finish($pid)};
		}
	}
	$wait_msg="Extracting and finalizing BLAT hits ...\n";
	$manager->wait_all_children;
}

sub run_p2b {
	my ($tmp_outer,$tmp_blat,$db_partition)=@_;
	my $tmp_inner=1;
	&parallelManager_initiate;
	for ($tmp_inner = 1; $tmp_inner<=$db_partition; $tmp_inner++) {
		@files_in_folder=glob("$tmp_blat/*_$tmp_outer.psl");
		foreach my $file(@files_in_folder) {
			$manager->start($file) and next;
			@cmd=("perl", "$p2b_script", "$file", "$file.bed");
			system(@cmd)==0 or &errorMessage("@cmd failed: $?");
			if ($manager) {$manager->finish($pid)};
		}
	}
	$manager->wait_all_children;
}

sub pathoAlign {
	my $dir=shift;
	my $patho_dir=shift;
	my $tmp_output_file="";
	my $tmp_input_file="";
	my $tmp_child_proc=0;

	@cmd=("perl","$frag_file_script", "$input_file", "$tmp_file_prefix", "$dir", "$num_proc","$fasta_format");
	system (@cmd) == 0 or &errorMessage(" @cmd failed: $?");
	unlink "$input_file" or warn "Can't delete $input_file: $!";
	
	@files_in_folder=<$dir/*.fasta>;
	my $unmap_output_file="";
	&parallelManager_initiate;
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		$sh_cmd="$mult_bacteria_bwa $bwa_exec $samtools_exec $file $dir $log_distrib $patho_dir";
		system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
		$tmp_child_proc++;
	}
	$manager->wait_all_children;

	@tmpfiles=glob("$dir/*_ALL_MAPPED_HEADER");
	$output_file="$dir/ALL_MAPPED_HEADER";
	for my $file(@tmpfiles) {
		$sh_cmd="cat $file >> $output_file";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
	}
	
	@tmpfiles=glob("$dir/*_ALL_UNMAPPED_HEADER");
	$output_file="$dir/ALL_UNMAPPED_HEADER";
	for my $file(@tmpfiles) {
		$sh_cmd="cat $file >> $output_file";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
	}

	$input_file=$dir."/ALL_MAPPED_HEADER";
	my $map_output_file=$dir."/ALL_MAPPED_UNIQHEADER";
	if (-e $input_file) {
		@cmd=("perl","$uniq_map_script", "$input_file", "$map_output_file");
		system (@cmd) == 0 or &errorMessage(" @cmd failed: $?");
	}
	else {
		&errorMessage("ALL_MAPPED_HEADER file not found");
	}

	$input_file=$dir."/ALL_UNMAPPED_HEADER";
	$unmap_output_file=$dir."/ALL_UNMAPPED_TMP_UNIQHEADER";
	if (-e $input_file) {
		@cmd=("perl", "$uniq_map_script", "$input_file", "$unmap_output_file");
		system (@cmd) == 0 or &errorMessage(" @cmd failed: $?");
	}
	else {
		&errorMessage ("ALL_UNMAPPED_HEADER file not found");
	}

	$output_file=$dir."/ALL_UNMAPPED_UNIQHEADER";
	if (-e $map_output_file && -e $unmap_output_file) {
		@cmd=("perl", "$intersect_script","$map_output_file","$unmap_output_file", "$output_file");
		system(@cmd) == 0 or &errorMessage(" @cmd failed: $?");
	}
	else {
		&errorMessage("ALL_UNMAPPED_UNIQHEADER file not found");
	}

	@files_in_folder=glob("$dir/$tmp_file_prefix*.fasta");
	&parallelManager_initiate;
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		$sh_cmd="$formatdb_exec -p F -o T -i $file"; 
		system($sh_cmd) ==0 or &errorMessage(" $sh_cmd failed: $?");		

		if ($manager) {$manager->finish($pid)};
	}

	$wait_msg="Creating databases ...\n";
	$manager->wait_all_children;

	$input_file=$output_file;
	&parallelManager_initiate;
	@files_in_folder=glob("$dir/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		$sh_cmd="$fastacmd_exec -p F -d $file -i $input_file -o $file.UNMAPPED_SEQ 2>>$dir/db_log_bac";
		system($sh_cmd); #The command always raise error due to partioned fasta db
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Extracting unmapped reads ...\n";
	$manager->wait_all_children;

	@tmpfiles=glob("$dir/*.UNMAPPED_SEQ");
	$output_file=$input_file_prefix.$tmp_file_suffix;
	for my $file(@tmpfiles) {
		$sh_cmd="cat $file >> $output_file";
		system($sh_cmd)== 0 or &errorMessage("$sh_cmd failed: $?");
		 unlink "$file" or warn "Can't delete $file: $!";
	}

	&parallelManager_initiate;
	@files_in_folder=glob("$dir/*.bam");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		@cmd=("perl", "$parse_bam_script", "$file");
		system(@cmd)==0 or &errorMessage("@cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}

	$wait_msg="Creating BED files ...\n";
	$manager->wait_all_children;
	
	my $split_out=`wc -l "$dir/ALL_UNMAPPED_UNIQHEADER"`;
	@tmp_arr=split(" ",$split_out);
	my $num_seq=$tmp_arr[0];
	$log_msg="Total sequences remaining after alignment with $patho_dir database:$num_seq";
	print logStats $log_msg,"\n";

	@tmpfiles=glob("$dir/*.bam_bed");
	$tmp_output_file=$dir."/ALL_MAPPED.bed";
	for my $file(@tmpfiles) {
		$sh_cmd="cat $file >> $tmp_output_file";
		system($sh_cmd)==0 or &errorMessage("$sh_cmd failed: $?");
		 unlink "$file" or warn "Can't delete $file: $!";
	}

	if ($lcl_alignmnt eq "n" || $lcl_alignmnt eq "N") {
		if (-s $tmp_output_file != 0) {
			$tmp_input_file=$tmp_output_file;
			$tmp_output_file=$tmp_input_file."_SORTBED";
			$sh_cmd="$sortbed_exec -i $tmp_input_file > $tmp_output_file";
			system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
		}

		if (-s $tmp_output_file != 0) {
			$tmp_input_file=$tmp_output_file;
			$tmp_output_file=$tmp_input_file."_GENOMECOV";
			$sh_cmd="$gencov_exec -i $tmp_input_file -g $patho_dir/GenomeDesc > $tmp_output_file";
			system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
		}
	}
	if ($del_tmp_pd eq "y" || $del_tmp_pd eq "Y") {
		my @tmp_suffix =(".bam", "ALL_UNMAPPED_HEADER", "ALL_MAPPED_HEADER", "UNIQHEADER", "_TOTAL_SORTBED") ;
		foreach(@tmp_suffix) {
			$tmp_file_suffix=$_;
			&unlinkFiles($dir,$tmp_file_suffix);
		}
	}
}

sub unlinkFiles {
	my ($dir,$ext)=@_;
	@tmpfiles=glob("$dir/*$ext");
	for my $file(@tmpfiles) {
		unlink "$file" or warn "Can't delete $file: $!";
	}
}

sub errorMessage {
    my $err = shift;
    print STDERR "ERROR: ".$err.".\n\n Please see MetaGeniE documentation or \'irimas -h\' for info.\n EXITING on ERROR.\n";
    exit(0);
}

$manager->run_on_finish (
	sub { 
		my ($pid, $exit_code, $ident) = @_;
      	print "** $ident not in pool ".
        "with PID $pid and exit code: $exit_code\n";
    }
  );

$manager->run_on_start(
    sub { my ($tmp_pid,$ident)=@_;
    $tmp_pid=$pid;
      print "** $ident started, pid: $pid\n";
    }
);

$manager->run_on_wait(
    sub {
      print "** Have to wait for one children ...\n"
    },
    0.5
);
  
sub parallelManager_initiate {
	$manager = new Parallel::ForkManager($num_proc);
}

sub seqCount_fasta {
	my $msg=shift;
	my $file=shift;
	(open(IN, "<$file"));
	my $cnt=0;
	while (<IN>) {
		if ($_ =~ /^\>/) {
		$cnt++;
		}
	}
	print logStats "$msg",$cnt,"\n";
	close IN;
}

sub timeStamp {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,
	$yday,$isdst)=localtime(time);

	printf timeLog "%4d-%02d-%02d %02d:%02d:%02d\n",
	$year+1900,$mon+1,$mday,$hour,$min,$sec;
}

sub makeDir {
	my $dir=shift;
	unless(-d $dir) {
		mkdir $dir;    
	} 
	else { 
		die "Temp Directories already exists, Please delete or rename Folders!!  \n"; 
	} 
}

sub closeFiles {
	close timeLog;
	close logStats;
}
